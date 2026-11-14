# SIGPesq

Sistema de Gerenciamento de Projetos de Pesquisa Universitarios (Banco de Dados - UFES/CEUNES).

## Requisitos
- Docker e Docker Compose
- Java 21 e Maven (`sudo pacman -S jdk21-openjdk maven` no CachyOS/Arch)

## Como rodar
```bash
cp .env.example .env          # so na primeira vez
docker compose up -d          # sobe o MySQL e cria as tabelas
mvn compile exec:java         # sobe a aplicacao
```
Abra http://localhost:8080

Depois de alterar `sigpesq_schema.sql`, recrie o banco:
`docker compose down -v && docker compose up -d`

## Consultas SQL
`sigpesq_consultas.sql` tem as consultas dos relatorios e os testes das regras de negocio:
`docker exec -i sigpesq_db mysql -u root -p < sigpesq_consultas.sql`
