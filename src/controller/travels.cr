require "db"
require "pg"
require "http/client"
require "crystal-gql"
require "json"

DB.open "postgres://user:pass@database:5432/mtb" do |cnn|
  post "/travel_plans" do |env|
    travel_stops = env.params.json["travel_stops"].as(Array)
    # Verificar se todos os itens estão dentro do intervalo permitido
    if travel_stops.any? { |stop| stop.to_s.to_i < 1 || stop.to_s.to_i > 126 }
      env.response.status = HTTP::Status::OK
      env.response.headers["Content-Type"] = "application/json"
      empty_arr = [] of Int32
      env.response.write(empty_arr.to_json.to_slice)
    else
      result = cnn.exec("INSERT INTO travel_plans (travel_stops) VALUES ('{#{travel_stops.join(",")}}');")
      last_id = cnn.query_one "SELECT LASTVAL() AS last_id;", as: {Int64}
      env.response.status = HTTP::Status::CREATED
      env.response.headers["Content-Type"] = "application/json"
      env.response.write({id: last_id, travel_stops: travel_stops}.to_json.to_slice)
    end
  end

  get "/travel_plans" do |env|
    response = [] of Hash(String, Array(Int32) | Int32)
    response_expand = [] of Hash(String, Array(Hash(String, String | Int32)) | Int32)
    query_params = env.params.query
    flag_e = false
    cnn.query("SELECT id, travel_stops::int[] FROM travel_plans") do |rs|
      rs.each do
        id = rs.read(Int32)
        arr = rs.read(Array(Int32))

        if query_params.has_key?("optimize")
          optimize = to_bool(query_params["optimize"])
          if optimize
            arr = optimize_method(arr)
          end
        end

        if query_params.has_key?("expand")
          expand = to_bool(query_params["expand"])
          if expand
            flag_e = true
            expand_arr = expand_method(arr)
            response_expand << {"id" => id, "travel_stops" => expand_arr}
          else
            response << {"id" => id, "travel_stops" => arr}
          end
        else
          response << {"id" => id, "travel_stops" => arr}
        end
      end
    end
    if (!flag_e && response.size < 1) || (flag_e && response_expand.size < 1)
      env.response.status = HTTP::Status::OK
      env.response.headers["Content-Type"] = "application/json"
      empty_arr = [] of Int32
      env.response.write(empty_arr.to_json.to_slice)
    else
      env.response.status = HTTP::Status::OK
      env.response.headers["Content-Type"] = "application/json"
      if flag_e
        env.response.write(response_expand.to_json.to_slice)
      else
        env.response.write(response.to_json.to_slice)
      end
    end
  end

  get "/travel_plans/:id" do |env|
    id = env.params.url["id"].to_i
    travel_stops = cnn.query_one("SELECT travel_stops::int[] FROM travel_plans WHERE id = $1", id, &.read(Array(Int32)))
    query_params = env.params.query

    if query_params.has_key?("optimize")
      optimize = to_bool(query_params["optimize"])
      if optimize
        travel_stops = optimize_method(travel_stops)
      end
    end

    flag_e = false
    expand_arr = [] of Array(Hash(String, String | Int32))
    if query_params.has_key?("expand")
      expand = to_bool(query_params["expand"])
      if expand
        flag_e = true
        expand_arr = expand_method(travel_stops)
      end
    end
    env.response.status = HTTP::Status::OK
    env.response.headers["Content-Type"] = "application/json"
    if flag_e
      env.response.write({id: id, travel_stops: expand_arr}.to_json.to_slice)
    else
      env.response.write({id: id, travel_stops: travel_stops}.to_json.to_slice)
    end
  rescue exception
    env.response.status = HTTP::Status::OK
    env.response.headers["Content-Type"] = "application/json"
    empty_arr = [] of Int32
    env.response.write(empty_arr.to_json.to_slice)
  end

  put "/travel_plans/:id" do |env|
    id = env.params.url["id"]
    travel_stops = env.params.json["travel_stops"].as(Array)
    # Verificar se todos os itens estão dentro do intervalo permitido
    if travel_stops.any? { |stop| stop.to_s.to_i < 1 || stop.to_s.to_i > 126 }
      env.response.status = HTTP::Status::OK
      env.response.headers["Content-Type"] = "application/json"
      empty_arr = [] of Int32
      env.response.write(empty_arr.to_json.to_slice)
    else
      result = cnn.exec("UPDATE travel_plans SET travel_stops = '{#{travel_stops.join(",")}}' WHERE id = #{id};")
      env.response.status = HTTP::Status::OK
      env.response.headers["Content-Type"] = "application/json"
      if result.rows_affected > 0
        env.response.write({id: id.to_i, travel_stops: travel_stops}.to_json.to_slice)
      else
        empty_arr = [] of Int32
        env.response.write(empty_arr.to_json.to_slice)
      end
    end
  end

  delete "/travel_plans/:id" do |env|
    id = env.params.url["id"]
    cnn.exec("DELETE from travel_plans WHERE id = #{id};")
    env.response.status = HTTP::Status::NO_CONTENT
    env.response.headers["Content-Type"] = "application/json"
    empty_arr = [] of Int32
    env.response.write(empty_arr.to_json.to_slice)
  end
end

def to_bool(value : String) : Bool?
  case value.downcase
  when "true", "yes", "1"
    true
  when "false", "no", "0"
    false
  else
    false
  end
end

def expand_method(arr : Array(Int32)) : Array(Hash(String, String | Int32))?
  expand_arr = [] of Hash(String, String | Int32)
  arr.each do |id_s|
    res_api = HTTP::Client.get("https://rickandmortyapi.com/api/location/#{id_s}")
    if res_api.status_code == 200
      body = res_api.body.to_s
      item = JSON.parse(body)
      name = item["name"].to_s
      type = item["type"].to_s
      dim = item["dimension"].to_s
      expand_arr << {"id" => id_s, "name" => name, "type" => type, "dimension" => dim}
    end
  end
  expand_arr
end

def optimize_method(ids : Array(Int32)) : Array(Int32)
  api = GraphQLClient.new "https://rickandmortyapi.com/graphql"
  response = [] of Int32

  locations_by_dimension = {} of String => Array(Hash(String, JSON::Any))
  dimensions_popularity = [] of String
  dimensions_average_popularity = {} of String => Float64

  ids.each do |id_q|
    data, error, loading = api.query("{
        location(id: #{id_q}) {
          name
          dimension
          id
          residents {
            episode {
              id
            }
          }
        }
      }")

    location_data = data["location"]
    dimension = location_data["dimension"].to_s
    if locations_by_dimension.has_key?(dimension)
      locations = locations_by_dimension[dimension]
    else
      locations = [] of Hash(String, JSON::Any)
    end
    locations << location_data.as_h
    locations_by_dimension[dimension] = locations

    residents = location_data["residents"].as_a
    count = 0
    residents.each do |resident|
      eps = resident["episode"].as_a.size
      count += eps
    end

    dimensions_average_popularity[dimension] ||= 0.0
    dimensions_average_popularity[dimension] += count.to_f
  end

  dimensions_average_popularity.each do |dimension, popularity|
    dimensions_average_popularity[dimension] = popularity / locations_by_dimension[dimension].size.to_f
    dimensions_popularity << dimension
  end

  dimensions_popularity.sort! do |a, b|
    popularity_comparison = dimensions_average_popularity[a] <=> dimensions_average_popularity[b]
    if popularity_comparison.nil? || popularity_comparison.zero?
      a <=> b
    else
      popularity_comparison
    end
  end

  dimensions_popularity.each do |dimension|
    locations = locations_by_dimension[dimension]
    locations.sort! do |a, b|
      popularity_a = calculate_location_popularity(a)
      popularity_b = calculate_location_popularity(b)
      popularity_comparison = popularity_a <=> popularity_b
      if popularity_comparison.zero?
        a["name"].to_s <=> b["name"].to_s
      else
        popularity_comparison
      end
    end

    locations.each do |location|
      response << location["id"].to_s.to_i
    end
  end

  response
end

def calculate_location_popularity(location : Hash(String, JSON::Any)) : Int32
  residents = location["residents"].as_a
  count = 0
  residents.each do |resident|
    eps = resident["episode"].as_a.size
    count += eps
  end
  count
end
