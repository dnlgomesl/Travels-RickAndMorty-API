require "spec"
require "http/client"
require "json"

puts "Aguardando API"
sleep 120.seconds

## Para rodar os testes execute docker-compose up --build -d e após crystal run spec/app_spec.cr

def request(method, path, body = "")
  response = HTTP::Client.exec(method, path, HTTP::Headers{ "Content-Type" => "application/json" }, body)
  response
end

describe "Travel Plans API" do
  data_teste = String

  puts "Início dos testes"
  # Define um método auxiliar para fazer requisições para a API

  describe "POST /travel_plans" do
    it "cria um novo plano de viagem" do
      # Simula a requisição POST para /travel_plans com JSON válido
      response = request("POST", "localhost:3000/travel_plans",  %({"travel_stops": [1, 2, 3]}))

      response.status_code.should eq(201)
      response.headers["Content-Type"].should eq("application/json")

      # Verifica se a resposta contém o ID e as paradas de viagem corretas
      body = response.body.to_s
      json = JSON.parse(body)
      data_teste = json["id"].to_s
      json["id"].should_not be_nil
      json["travel_stops"].should eq([1, 2, 3])
    end

    it "retorna OK e (e não salva) se as paradas de viagem estão fora do intervalo permitido" do
      # Simula a requisição POST para /travel_plans com paradas inválidas
      response = request("POST", "localhost:3000/travel_plans", %({"travel_stops": [0, 127]}))

      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/json")
      body = response.body.to_s
      json = JSON.parse(body)
      json.should eq([] of JSON::Any)
    end
  end

  describe "GET /travel_plans" do
    it "Recupera um plano de viagens sem optimize e sem expand" do
      # Simula a requisição POST para /travel_plans com JSON válido
      response = request("GET", "localhost:3000/travel_plans/#{data_teste}")

      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/json")

      # Verifica se a resposta contém o ID e as paradas de viagem corretas
      body = response.body.to_s
      json = JSON.parse(body)
      json["id"].should_not be_nil
      json["travel_stops"].should eq([1, 2, 3])
    end
  end

  describe "PUT /travel_plans" do
    it "Atualiza um plano de viagens" do
      # Simula a requisição POST para /travel_plans com JSON válido
      response = request("PUT", "localhost:3000/travel_plans/#{data_teste}", %({"travel_stops": [1, 2]}))

      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/json")

      # Verifica se a resposta contém o ID e as paradas de viagem corretas
      body = response.body.to_s
      json = JSON.parse(body)
      json["id"].should_not be_nil
      json["travel_stops"].should eq([1, 2])
    end

    it "retorna OK e não modifica se as paradas de viagem estão fora do intervalo permitido" do
      # Simula a requisição POST para /travel_plans com paradas inválidas
      response = request("PUT", "localhost:3000/travel_plans/#{data_teste}", %({"travel_stops": [0, 127]}))

      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/json")
      body = response.body.to_s
      json = JSON.parse(body)
      json.should eq([] of JSON::Any)
    end
    it "Recupera um plano de viagens com optimize e sem expand" do
      # Simula a requisição POST para /travel_plans com JSON válido
      response = request("GET", "localhost:3000/travel_plans/#{data_teste}?optimize=true")

      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/json")

      # Verifica se a resposta contém o ID e as paradas de viagem corretas
      body = response.body.to_s
      json = JSON.parse(body)
      json["id"].should_not be_nil
      json["travel_stops"].should eq([2, 1])
    end
    it "Recupera um plano de viagens com expand e sem optimize" do
      # Simula a requisição POST para /travel_plans com JSON válido
      response = request("GET", "localhost:3000/travel_plans/#{data_teste}?expand=true")

      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/json")

      # Verifica se a resposta contém o ID e as paradas de viagem corretas
      body = response.body.to_s
      json = JSON.parse(body)
      json["id"].should_not be_nil
      puts "114"
      json["travel_stops"].to_s.should eq([{"id" => 1,
      "name" => "Earth (C-137)",
      "type" => "Planet",
      "dimension" => "Dimension C-137"},
     {"id" => 2,
      "name" => "Abadango",
      "type" => "Cluster",
      "dimension" => "unknown"}].to_s)
    end
  end

  describe "DELETE /travel_plans" do
    it "Deleta um plano de viagens" do
      # Simula a requisição POST para /travel_plans com JSON válido
      response = request("DELETE", "localhost:3000/travel_plans/#{data_teste}")

      response.status_code.should eq(204)
      response.headers["Content-Type"].should eq("application/json")
    end
    it "Recupera um plano de viagens que não existe" do
      # Simula a requisição POST para /travel_plans com JSON válido
      response = request("GET", "localhost:3000/travel_plans/#{data_teste}")

      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/json")

      # Verifica se a resposta contém o ID e as paradas de viagem corretas
      body = response.body.to_s
      json = JSON.parse(body)
      json.should eq([] of JSON::Any)
    end
    it "Atualiza um plano de viagens que não existe" do
      # Simula a requisição POST para /travel_plans com JSON válido
      response = request("PUT", "localhost:3000/travel_plans/#{data_teste}", %({"travel_stops": [1, 2]}))

      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/json")

      # Verifica se a resposta contém o ID e as paradas de viagem corretas
      body = response.body.to_s
      json = JSON.parse(body)
      json.should eq([] of JSON::Any)
    end
  end

end
