-- ======================================= --
-- SIGPesq - Consultas e testes das regras --
-- ======================================= --
USE sigpesq;

-- ------------------ --
-- 1. Listar projetos --
-- ------------------ --
SELECT p.codigo,
       p.titulo,
       c.nome        AS coordenador,
       p.situacao,
       p.data_inicio,
       p.data_termino
FROM projeto_pesquisa p
JOIN participante c ON c.id_participante = p.id_coordenador
WHERE p.ativo = TRUE
ORDER BY p.codigo;

-- ---------------------------------------------- --
-- 2. Producoes cientificas de um determinado ano --
-- ---------------------------------------------- --
SELECT pc.titulo,
       tp.nome            AS tipo,
       pc.ano_publicacao,
       pc.meio_divulgacao,
       p.titulo           AS projeto,
       GROUP_CONCAT(pa.nome ORDER BY a.ordem_autoria SEPARATOR ', ') AS autores
FROM producao_cientifica pc
JOIN tipo_producao tp   ON tp.id_tipo_producao = pc.id_tipo_producao
JOIN projeto_pesquisa p ON p.codigo = pc.codigo_projeto
JOIN autoria a          ON a.id_producao = pc.id_producao
JOIN participante pa    ON pa.id_participante = a.id_participante
WHERE pc.ano_publicacao = 2026
GROUP BY pc.id_producao, pc.titulo, tp.nome, pc.ano_publicacao, pc.meio_divulgacao, p.titulo
ORDER BY pc.titulo;

-- ------------------------------------------------------------ --
-- 3. Total de financiamento por agencia (RF-09 / RF-20)        --
--    LEFT JOIN: agencia sem financiamento aparece com total 0. --
-- ------------------------------------------------------------ --
SELECT ag.sigla,
       ag.nome,
       COUNT(f.id_financiamento)      AS qtd_financiamentos,
       COALESCE(SUM(f.valor_total), 0) AS total_financiado
FROM agencia_fomento ag
LEFT JOIN financiamento f ON f.id_agencia = ag.id_agencia AND f.ativo = TRUE
WHERE ag.ativo = TRUE
GROUP BY ag.id_agencia, ag.sigla, ag.nome
ORDER BY total_financiado DESC;

-- ---------------------------------------- --
-- 4. Participantes que atuam em um projeto --
-- ---------------------------------------- --
SELECT pt.nome,
       pt.tipo,
       v.funcao,
       v.data_entrada,
       COALESCE(CAST(v.data_saida AS CHAR), 'Em aberto') AS data_saida
FROM vinculo_participacao v
JOIN participante pt ON pt.id_participante = v.id_participante
WHERE v.codigo_projeto = 'P001'
ORDER BY v.data_entrada;

-- ------ --
-- EXTRAS --
-- ------ --

-- RF-14: participantes com vinculo ativo em mais de um projeto
SELECT pt.nome, COUNT(DISTINCT v.codigo_projeto) AS qtd_projetos_ativos
FROM vinculo_participacao v
JOIN participante pt ON pt.id_participante = v.id_participante
WHERE v.data_saida IS NULL
GROUP BY pt.id_participante, pt.nome
HAVING COUNT(DISTINCT v.codigo_projeto) > 1;

-- RF-05: projetos coordenados por um docente
SELECT p.codigo, p.titulo, p.situacao
FROM projeto_pesquisa p
JOIN participante c ON c.id_participante = p.id_coordenador
WHERE c.nome = 'Ana Beatriz Souza';

-- RF-21: producoes por tipo
SELECT tp.nome AS tipo, COUNT(*) AS quantidade
FROM producao_cientifica pc
JOIN tipo_producao tp ON tp.id_tipo_producao = pc.id_tipo_producao
GROUP BY tp.id_tipo_producao, tp.nome
ORDER BY quantidade DESC;

-- Quanto cada agencia ja distribuiu para projetos (soma das alocacoes)
SELECT ag.sigla, COALESCE(SUM(al.valor_destinado), 0) AS total_alocado
FROM agencia_fomento ag
LEFT JOIN financiamento f ON f.id_agencia = ag.id_agencia
LEFT JOIN alocacao_financiamento al ON al.id_financiamento = f.id_financiamento
GROUP BY ag.id_agencia, ag.sigla;

-- =====================================================================
-- TESTES DAS REGRAS -- descomente UMA linha por vez; TODAS devem dar erro.
-- (se alguma funcionar, a regra correspondente nao esta sendo aplicada)
-- =====================================================================
-- RN-02  coordenador nao-docente:
-- INSERT INTO projeto_pesquisa (codigo,id_coordenador,titulo,descricao,data_inicio,data_termino) VALUES ('X1',3,'T','D','2026-01-01','2026-12-31');
-- RN-02  trocar tipo de docente que coordena:
-- UPDATE participante SET tipo = 'Discente' WHERE id_participante = 1;
-- RN-03  situacao invalida:
-- UPDATE projeto_pesquisa SET situacao = 'Pausado' WHERE codigo = 'P001';
-- RN-09  CPF duplicado:
-- INSERT INTO participante (tipo,nome,cpf,email_institucional) VALUES ('Discente','X','11122233344','x@ufnes.edu.br');
-- CPF fora do formato (11 digitos):
-- INSERT INTO participante (tipo,nome,cpf,email_institucional) VALUES ('Discente','X','123','y@ufnes.edu.br');
-- RN-10  termino antes do inicio:
-- INSERT INTO projeto_pesquisa (codigo,id_coordenador,titulo,descricao,data_inicio,data_termino) VALUES ('X2',1,'T','D','2026-05-01','2026-01-01');
-- RN-16  alocacao acima do total do financiamento 1 (ja alocado 50.000):
-- INSERT INTO alocacao_financiamento (codigo_projeto,id_financiamento,modalidade,valor_destinado) VALUES ('P003',1,'Parcial',1.00);
-- RN-16  reduzir o valor total abaixo do ja alocado (RF-19):
-- UPDATE financiamento SET valor_total = 10000 WHERE id_financiamento = 1;
-- RN-17  vinculo antes do inicio do projeto P003:
-- INSERT INTO vinculo_participacao (id_participante,codigo_projeto,funcao,data_entrada) VALUES (4,'P003','Bolsista','2025-01-01');
-- RN-01  funcao Coordenador para quem nao e o coordenador do projeto:
-- INSERT INTO vinculo_participacao (id_participante,codigo_projeto,funcao,data_entrada) VALUES (3,'P001','Coordenador','2025-06-01');
-- RN-18  producao com ano anterior ao inicio do projeto:
-- INSERT INTO producao_cientifica (codigo_projeto,id_tipo_producao,titulo,ano_publicacao,meio_divulgacao) VALUES ('P002',1,'T',2024,'M');
-- RN-19  segundo vinculo ATIVO igual (Fernanda ja e Bolsista em P001):
-- INSERT INTO vinculo_participacao (id_participante,codigo_projeto,funcao,data_entrada) VALUES (3,'P001','Bolsista','2025-07-01');
-- RNF-02 apagar quem esta referenciado:
-- DELETE FROM participante WHERE id_participante = 1;
