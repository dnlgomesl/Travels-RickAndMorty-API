# Documentação do Código - Cadastro de Planos de Viagens para o Universo de Rick and Morty

O código fornecido implementa um sistema para cadastrar planos de viagens para o universo de Rick and Morty. Ele utiliza uma API chamada "rickandmortyapi" para obter informações sobre as localizações no universo e permite que os usuários otimizem suas viagens e obtenham informações expandidas sobre as paradas de viagem.

## Rotas Disponíveis

### POST /travel_plans

Esta rota é responsável por cadastrar um novo plano de viagem. Ela recebe os dados da viagem no formato JSON no corpo da requisição. Os dados devem incluir uma lista de "travel_stops" que representam as paradas planejadas da viagem.

#### Parâmetros da Requisição

- `travel_stops` (obrigatório): Uma lista de paradas da viagem. Cada parada deve ser representada por um número inteiro no intervalo de 1 a 126.

### GET /travel_plans

Esta rota retorna uma lista de todos os planos de viagem cadastrados. Ela suporta dois parâmetros de consulta opcionais: `optimize` e `expand`.

#### Parâmetros da Consulta

- `optimize` (opcional): Um valor booleano que indica se a viagem deve ser otimizada. Quando definido como `true`, a ordem das paradas de viagem será otimizada para minimizar saltos interdimensionais. Se não fornecido ou definido como `false`, a ordem das paradas permanecerá como foi cadastrada.
- `expand` (opcional): Um valor booleano que indica se as informações das paradas de viagem devem ser expandidas. Quando definido como `true`, as informações expandidas incluirão detalhes sobre as localizações de cada parada obtidos da API "rickandmortyapi". Se não fornecido ou definido como `false`, apenas os IDs das paradas serão retornados.

### GET /travel_plans/:id

Esta rota retorna os detalhes de um plano de viagem específico com base no ID fornecido. Assim como a rota anterior, ela também suporta os parâmetros de consulta `optimize` e `expand`.

#### Parâmetros da URL

- `id` (obrigatório): O ID do plano de viagem a ser recuperado.

### PUT /travel_plans/:id

Esta rota permite atualizar um plano de viagem existente com base no ID fornecido. Ela recebe os dados da viagem atualizados no formato JSON no corpo da requisição, incluindo a lista de `travel_stops` atualizada.

#### Parâmetros da URL

- `id` (obrigatório): O ID do plano de viagem a ser atualizado.

#### Parâmetros da Requisição

- `travel_stops` (obrigatório): A lista atualizada de paradas da viagem.

### DELETE /travel_plans/:id

Esta rota permite excluir um plano de viagem existente com base no ID fornecido.

#### Parâmetros da URL

- `id` (obrigatório): O ID do plano de viagem a ser excluído.

## Funções Auxiliares

O código também inclui algumas funções auxiliares que são utilizadas pelas rotas para realizar operações específicas.

### `to_bool(value : String) : Bool?`

Esta

 função converte uma string em um valor booleano. Ela é utilizada pelas rotas GET para converter os valores dos parâmetros de consulta `optimize` e `expand` em valores booleanos.

### `expand_method(arr : Array(Int32)) : Array(Hash(String, String | Int32))?`

Esta função é utilizada para expandir as informações das paradas de viagem. Ela recebe uma lista de IDs de paradas e faz uma chamada à API "rickandmortyapi" para obter informações detalhadas sobre cada parada. As informações expandidas incluem o nome da localização, o tipo e a dimensão. Os resultados são retornados como uma lista de hashes.

### `optimize_method(ids : Array(Int32)) : Array(Int32)`

Esta função é utilizada para otimizar a ordem das paradas de viagem. Ela faz uso da API "rickandmortyapi" para obter informações sobre as localizações e suas respectivas dimensões. Com base nessas informações, os IDs das paradas são reordenados de acordo com a popularidade das dimensões e das localizações dentro de cada dimensão. Os resultados são retornados como uma nova lista de IDs otimizados.

### `calculate_location_popularity(location : Hash(String, JSON::Any)) : Int32`

Esta função calcula a popularidade de uma localização com base na quantidade total de episódios em que seus residentes aparecem. Ela é utilizada pela função `optimize_method` para determinar a popularidade de cada localização e realizar a ordenação.

## Considerações Finais

O código fornecido implementa um sistema básico de cadastro de planos de viagens para o universo de Rick and Morty. Ele oferece suporte a recursos como otimização de viagens e informações expandidas sobre as paradas de viagem, utilizando a API "rickandmortyapi" como fonte de dados adicionais.