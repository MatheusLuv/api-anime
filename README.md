## SQL – Criação do Banco e Tabela
**Nome do arquivo:** create_danbooru_posts.sql

*No terminal (cmd ou PowerShell), digite:*
`psql -U postgres`

*Crie o Banco:*
``CREATE DATABASE danbooru_demo;``

*Em seguida entre no Banco com comando:*
``\c danbooru_demo;``

### Crie a Tabela do Banco

    CREATE TABLE IF NOT EXISTS danbooru_posts (
        id SERIAL PRIMARY KEY,
        api_id INTEGER UNIQUE,
        tags TEXT,
        image_url TEXT,
        creator TEXT,
        score INTEGER,file_ext TEXT,
        created_at TIMESTAMP,
        inserted_at TIMESTAMP DEFAULT NOW()
    );

## Descrição da API

API escolhida: ``Danbooru API``

Recurso usado: /posts.json

A API retorna posts (imagens/animes) com metadados.

Permite buscar por tags, paginação e quantidade de registros.

Exemplo de requisição:

https://danbooru.donmai.us/posts.json?tags=anime&page=1&limit=20

## Como Rodar

### Crie o Banco e Tabela:

    psql -U postgres -f create_danbooru_posts.sql

### Instale a gems: 

    gem install pg httparty

### Busque os dados da API e salve no banco:

    ruby app_danbooru.rb fetch Uzumaki_Naruto

### Liste os resultados salvos:

    ruby app_danbooru.rb list 5
