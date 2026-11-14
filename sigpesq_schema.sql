-- ========================================================================= --
-- SIGPesq - Sistema de Gerenciamento de Projetos de Pesquisa Universitarios --
-- ========================================================================= --

SET NAMES utf8mb4;

DROP DATABASE IF EXISTS sigpesq;
CREATE DATABASE sigpesq
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE sigpesq;

-- =========================== --
-- 1. TABELAS SEM DEPENDENCIAS --
-- =========================== --

-- --------------- --
-- AGENCIA_FOMENTO --
-- --------------- --
CREATE TABLE agencia_fomento (
    id_agencia      INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(150)    NOT NULL,
    sigla           VARCHAR(20)     NOT NULL,
    ativo           BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_agencia_sigla UNIQUE (sigla)
) ENGINE = InnoDB;

-- ------------- --
-- TIPO_PRODUCAO --
-- ------------- --
CREATE TABLE tipo_producao (
    id_tipo_producao INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(100)    NOT NULL,
    ativo           BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_tipo_producao_nome UNIQUE (nome)
) ENGINE = InnoDB;

-- ------------ --
-- PARTICIPANTE --
-- ------------ --
CREATE TABLE participante (
    id_participante     INT AUTO_INCREMENT PRIMARY KEY,
    tipo                VARCHAR(20)     NOT NULL,
    nome                VARCHAR(150)    NOT NULL,
    cpf                 CHAR(11)        NOT NULL,
    email_institucional VARCHAR(120)    NOT NULL,
    ativo               BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_participante_cpf   UNIQUE (cpf),                 -- RN-09
    CONSTRAINT uq_participante_email UNIQUE (email_institucional), -- RN-14
    CONSTRAINT ck_participante_tipo  CHECK (tipo IN ('Docente', 'Discente', 'Tecnico')),
    CONSTRAINT ck_participante_cpf   CHECK (cpf REGEXP '^[0-9]{11}$') -- 11 digitos, sem pontuacao
) ENGINE = InnoDB;

-- ===================================== --
-- 2. TABELAS COM DEPENDENCIA DE 1 NIVEL --
-- ===================================== --

-- ------------- --
-- FINANCIAMENTO --
-- ------------- --
CREATE TABLE financiamento (
    id_financiamento INT AUTO_INCREMENT PRIMARY KEY,
    id_agencia      INT             NOT NULL,
    tipo_fomento    VARCHAR(50)     NOT NULL,
    inicio_vigencia DATE            NOT NULL,
    fim_vigencia    DATE            NOT NULL,
    valor_total     DECIMAL(15,2)   NOT NULL,
    ativo           BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_financiamento_agencia FOREIGN KEY (id_agencia)
        REFERENCES agencia_fomento (id_agencia)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_financiamento_vigencia CHECK (fim_vigencia > inicio_vigencia), -- RN-12
    CONSTRAINT ck_financiamento_valor    CHECK (valor_total > 0)
) ENGINE = InnoDB;

-- ---------------- --
-- PROJETO_PESQUISA --
-- ---------------- --
CREATE TABLE projeto_pesquisa (
    codigo          VARCHAR(20)     PRIMARY KEY,              -- RN-04
    id_coordenador  INT             NOT NULL,                 -- RN-01 
    titulo          VARCHAR(200)    NOT NULL,
    descricao       TEXT            NOT NULL,                 -- RF-01
    data_inicio     DATE            NOT NULL,
    data_termino    DATE            NOT NULL,                 -- RF-01
    situacao        VARCHAR(20)     NOT NULL DEFAULT 'Em andamento',
    ativo           BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_projeto_coordenador FOREIGN KEY (id_coordenador)
        REFERENCES participante (id_participante)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_projeto_situacao CHECK (situacao IN ('Em andamento', 'Concluido', 'Cancelado')), -- RN-03
    CONSTRAINT ck_projeto_datas    CHECK (data_termino > data_inicio) -- RN-10
) ENGINE = InnoDB;

-- ====================================== --
-- 3. TABELAS COM DEPENDENCIA DE 2 NIVEIS --
-- ====================================== --

-- ------------------- --
-- PRODUCAO_CIENTIFICA --
-- ------------------- --
CREATE TABLE producao_cientifica (
    id_producao     INT AUTO_INCREMENT PRIMARY KEY,
    codigo_projeto  VARCHAR(20)     NOT NULL,
    id_tipo_producao INT            NOT NULL,
    titulo          VARCHAR(200)    NOT NULL,
    ano_publicacao  INT             NOT NULL,
    meio_divulgacao VARCHAR(150)    NOT NULL,                 -- RF-10
    CONSTRAINT fk_producao_projeto FOREIGN KEY (codigo_projeto)
        REFERENCES projeto_pesquisa (codigo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_producao_tipo FOREIGN KEY (id_tipo_producao)
        REFERENCES tipo_producao (id_tipo_producao)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_producao_ano CHECK (ano_publicacao BETWEEN 1900 AND 2100)
) ENGINE = InnoDB;

-- -------------------- --
-- VINCULO_PARTICIPACAO --
-- -------------------- --
CREATE TABLE vinculo_participacao (
    id_vinculo      INT AUTO_INCREMENT PRIMARY KEY,
    id_participante INT             NOT NULL,
    codigo_projeto  VARCHAR(20)     NOT NULL,
    funcao          VARCHAR(40)     NOT NULL,
    data_entrada    DATE            NOT NULL,
    data_saida      DATE            NULL,

    vinculo_aberto  TINYINT GENERATED ALWAYS AS (IF(data_saida IS NULL, 1, NULL)) VIRTUAL,
    CONSTRAINT fk_vinculo_participante FOREIGN KEY (id_participante)
        REFERENCES participante (id_participante)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_vinculo_projeto FOREIGN KEY (codigo_projeto)
        REFERENCES projeto_pesquisa (codigo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_vinculo_datas CHECK (data_saida IS NULL OR data_saida > data_entrada), -- RN-11
    CONSTRAINT uq_vinculo_ativo UNIQUE (id_participante, codigo_projeto, funcao, vinculo_aberto) -- RN-19
) ENGINE = InnoDB;

-- ---------------------- --
-- ALOCACAO_FINANCIAMENTO --
-- ---------------------- --
CREATE TABLE alocacao_financiamento (
    id_alocacao     INT AUTO_INCREMENT PRIMARY KEY,
    codigo_projeto  VARCHAR(20)     NOT NULL,
    id_financiamento INT            NOT NULL,
    modalidade      VARCHAR(20)     NOT NULL,
    valor_destinado DECIMAL(15,2)   NOT NULL,
    CONSTRAINT fk_alocacao_projeto FOREIGN KEY (codigo_projeto)
        REFERENCES projeto_pesquisa (codigo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_alocacao_financiamento FOREIGN KEY (id_financiamento)
        REFERENCES financiamento (id_financiamento)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_alocacao_projeto_financiamento UNIQUE (codigo_projeto, id_financiamento),
    CONSTRAINT ck_alocacao_modalidade CHECK (modalidade IN ('Total', 'Parcial')),
    CONSTRAINT ck_alocacao_valor CHECK (valor_destinado > 0)
) ENGINE = InnoDB;

-- ------- --
-- AUTORIA --
-- ------- --
CREATE TABLE autoria (
    id_producao     INT             NOT NULL,
    id_participante INT             NOT NULL,
    ordem_autoria   INT             NULL,
    PRIMARY KEY (id_producao, id_participante),
    CONSTRAINT fk_autoria_producao FOREIGN KEY (id_producao)
        REFERENCES producao_cientifica (id_producao)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_autoria_participante FOREIGN KEY (id_participante)
        REFERENCES participante (id_participante)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ===================== --
-- 4. INDICES ADICIONAIS --
-- ===================== --
CREATE INDEX idx_projeto_situacao ON projeto_pesquisa (situacao);
CREATE INDEX idx_producao_ano     ON producao_cientifica (ano_publicacao);

-- =========== --
-- 5. TRIGGERS --
-- =========== --
DELIMITER $$

-- ------------------------------------------------------------- --
-- RN-02: o coordenador principal de um projeto deve ser Docente --
-- ------------------------------------------------------------- --
CREATE TRIGGER trg_projeto_coordenador_docente_ins
BEFORE INSERT ON projeto_pesquisa
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(20);
    SELECT tipo INTO v_tipo FROM participante WHERE id_participante = NEW.id_coordenador;
    IF v_tipo IS NULL OR v_tipo <> 'Docente' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-02: o coordenador principal do projeto deve ser um participante do tipo Docente.';
    END IF;
END$$

CREATE TRIGGER trg_projeto_coordenador_docente_upd
BEFORE UPDATE ON projeto_pesquisa
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(20);
    SELECT tipo INTO v_tipo FROM participante WHERE id_participante = NEW.id_coordenador;
    IF v_tipo IS NULL OR v_tipo <> 'Docente' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-02: o coordenador principal do projeto deve ser um participante do tipo Docente.';
    END IF;
END$$

-- RN-02: impede trocar o tipo de um Docente que ainda
-- coordena projetos (RF-18 permite editar o tipo do participante)
CREATE TRIGGER trg_participante_tipo_upd
BEFORE UPDATE ON participante
FOR EACH ROW
BEGIN
    IF OLD.tipo = 'Docente' AND NEW.tipo <> 'Docente' THEN
        IF EXISTS (SELECT 1 FROM projeto_pesquisa WHERE id_coordenador = OLD.id_participante) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'RN-02: participante coordena projetos e nao pode deixar de ser Docente.';
        END IF;
    END IF;
END$$

-- ---------------------------------------------------------------------
-- RN-17 + regra do Coordenador (UC-03, passo 6):
--  * o periodo do vinculo deve estar contido na vigencia do projeto;
--  * se a funcao for 'Coordenador', o participante deve ser o
--    coordenador principal do projeto.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_vinculo_regras_ins
BEFORE INSERT ON vinculo_participacao
FOR EACH ROW
BEGIN
    DECLARE v_inicio DATE;
    DECLARE v_termino DATE;
    DECLARE v_coord INT;
    SELECT data_inicio, data_termino, id_coordenador INTO v_inicio, v_termino, v_coord
        FROM projeto_pesquisa WHERE codigo = NEW.codigo_projeto;
    IF NEW.data_entrada < v_inicio OR NEW.data_entrada > v_termino THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-17: a data de entrada do vinculo deve estar dentro da vigencia do projeto.';
    END IF;
    IF NEW.data_saida IS NOT NULL AND NEW.data_saida > v_termino THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-17: a data de saida do vinculo nao pode ser posterior ao termino do projeto.';
    END IF;
    IF NEW.funcao = 'Coordenador' AND NEW.id_participante <> v_coord THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-01: a funcao Coordenador so pode ser atribuida ao coordenador principal do projeto.';
    END IF;
END$$

CREATE TRIGGER trg_vinculo_regras_upd
BEFORE UPDATE ON vinculo_participacao
FOR EACH ROW
BEGIN
    DECLARE v_inicio DATE;
    DECLARE v_termino DATE;
    DECLARE v_coord INT;
    SELECT data_inicio, data_termino, id_coordenador INTO v_inicio, v_termino, v_coord
        FROM projeto_pesquisa WHERE codigo = NEW.codigo_projeto;
    IF NEW.data_entrada < v_inicio OR NEW.data_entrada > v_termino THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-17: a data de entrada do vinculo deve estar dentro da vigencia do projeto.';
    END IF;
    IF NEW.data_saida IS NOT NULL AND NEW.data_saida > v_termino THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-17: a data de saida do vinculo nao pode ser posterior ao termino do projeto.';
    END IF;
    IF NEW.funcao = 'Coordenador' AND NEW.id_participante <> v_coord THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-01: a funcao Coordenador so pode ser atribuida ao coordenador principal do projeto.';
    END IF;
END$$

-- ---------------------------------------------------------------------------- --
-- RN-18: o ano de publicacao nao pode ser anterior ao ano de inicio do projeto --
-- ---------------------------------------------------------------------------- --
CREATE TRIGGER trg_producao_ano_ins
BEFORE INSERT ON producao_cientifica
FOR EACH ROW
BEGIN
    DECLARE v_ano_inicio INT;
    SELECT YEAR(data_inicio) INTO v_ano_inicio FROM projeto_pesquisa WHERE codigo = NEW.codigo_projeto;
    IF NEW.ano_publicacao < v_ano_inicio THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-18: o ano de publicacao nao pode ser anterior ao ano de inicio do projeto.';
    END IF;
END$$

CREATE TRIGGER trg_producao_ano_upd
BEFORE UPDATE ON producao_cientifica
FOR EACH ROW
BEGIN
    DECLARE v_ano_inicio INT;
    SELECT YEAR(data_inicio) INTO v_ano_inicio FROM projeto_pesquisa WHERE codigo = NEW.codigo_projeto;
    IF NEW.ano_publicacao < v_ano_inicio THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-18: o ano de publicacao nao pode ser anterior ao ano de inicio do projeto.';
    END IF;
END$$

-- ---------------------------------------------------------------- --
-- RN-16: a soma dos valores destinados a um financiamento nao pode --
-- ultrapassar o valor_total desse financiamento                    --
-- ---------------------------------------------------------------- --
CREATE TRIGGER trg_alocacao_limite_ins
BEFORE INSERT ON alocacao_financiamento
FOR EACH ROW
BEGIN
    DECLARE v_total DECIMAL(15,2);
    DECLARE v_alocado DECIMAL(15,2);
    SELECT valor_total INTO v_total FROM financiamento WHERE id_financiamento = NEW.id_financiamento;
    SELECT COALESCE(SUM(valor_destinado), 0) INTO v_alocado FROM alocacao_financiamento
        WHERE id_financiamento = NEW.id_financiamento;
    IF (v_alocado + NEW.valor_destinado) > v_total THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-16: a soma das alocacoes ultrapassa o valor total do financiamento.';
    END IF;
END$$

CREATE TRIGGER trg_alocacao_limite_upd
BEFORE UPDATE ON alocacao_financiamento
FOR EACH ROW
BEGIN
    DECLARE v_total DECIMAL(15,2);
    DECLARE v_alocado DECIMAL(15,2);
    SELECT valor_total INTO v_total FROM financiamento WHERE id_financiamento = NEW.id_financiamento;
    SELECT COALESCE(SUM(valor_destinado), 0) INTO v_alocado FROM alocacao_financiamento
        WHERE id_financiamento = NEW.id_financiamento AND id_alocacao <> NEW.id_alocacao;
    IF (v_alocado + NEW.valor_destinado) > v_total THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-16: a soma das alocacoes ultrapassa o valor total do financiamento.';
    END IF;
END$$

-- RN-16 (lado inverso): ao editar o financiamento (RF-19), o novo valor
-- total nao pode ficar abaixo do que ja foi alocado aos projetos
CREATE TRIGGER trg_financiamento_valor_upd
BEFORE UPDATE ON financiamento
FOR EACH ROW
BEGIN
    DECLARE v_alocado DECIMAL(15,2);
    SELECT COALESCE(SUM(valor_destinado), 0) INTO v_alocado FROM alocacao_financiamento
        WHERE id_financiamento = OLD.id_financiamento;
    IF NEW.valor_total < v_alocado THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-16: o novo valor total e menor que o valor ja alocado aos projetos.';
    END IF;
END$$

DELIMITER ;

-- ================= --
-- 6. CARGA DE DADOS --
-- ================= --

-- Agencias de fomento
INSERT INTO agencia_fomento (nome, sigla, ativo) VALUES
    ('Conselho Nacional de Desenvolvimento Cientifico e Tecnologico', 'CNPq', TRUE),
    ('Fundacao de Amparo a Pesquisa e Inovacao do Espirito Santo',     'FAPES', TRUE),
    ('Coordenacao de Aperfeicoamento de Pessoal de Nivel Superior',    'CAPES', TRUE);

-- Tipos de producao
INSERT INTO tipo_producao (nome, ativo) VALUES
    ('Artigo', TRUE),
    ('Capitulo de Livro', TRUE),
    ('Software', TRUE),
    ('Relatorio Tecnico', TRUE);

-- Participantes
INSERT INTO participante (tipo, nome, cpf, email_institucional, ativo) VALUES
    ('Docente',  'Ana Beatriz Souza',     '11122233344', 'ana.souza@ufnes.edu.br',      TRUE),
    ('Docente',  'Carlos Eduardo Lima',   '22233344455', 'carlos.lima@ufnes.edu.br',    TRUE),
    ('Discente', 'Fernanda Dias Rocha',   '33344455566', 'fernanda.rocha@ufnes.edu.br', TRUE),
    ('Discente', 'Gabriel Martins Alves', '44455566677', 'gabriel.alves@ufnes.edu.br',  TRUE),
    ('Tecnico',  'Helena Castro Pires',   '55566677788', 'helena.pires@ufnes.edu.br',   TRUE);

-- Financiamentos
INSERT INTO financiamento (id_agencia, tipo_fomento, inicio_vigencia, fim_vigencia, valor_total, ativo) VALUES
    (1, 'Bolsa',    '2025-01-01', '2026-12-31', 50000.00, TRUE),  -- CNPq
    (2, 'Auxilio',  '2025-06-01', '2026-05-31', 30000.00, TRUE);  -- FAPES

-- Projetos de pesquisa
INSERT INTO projeto_pesquisa (codigo, id_coordenador, titulo, descricao, data_inicio, data_termino, situacao, ativo) VALUES
    ('P001', 1, 'Monitoramento de Qualidade da Agua em Bacias Urbanas',
        'Avaliacao de parametros fisico-quimicos em cursos de agua da regiao metropolitana.',
        '2025-02-01', '2026-12-31', 'Em andamento', TRUE),
    ('P002', 1, 'Inteligencia Artificial Aplicada a Agricultura de Precisao',
        'Desenvolvimento de modelos preditivos para apoio a decisao no manejo agricola.',
        '2025-03-01', '2026-02-28', 'Concluido', TRUE),
    ('P003', 2, 'Educacao Ambiental em Escolas Publicas',
        'Diagnostico e proposta de intervencoes de educacao ambiental na rede municipal.',
        '2025-05-01', '2026-10-31', 'Em andamento', TRUE);

-- Vinculos de participacao
INSERT INTO vinculo_participacao (id_participante, codigo_projeto, funcao, data_entrada, data_saida) VALUES
    (1, 'P001', 'Coordenador', '2025-02-01', NULL),
    (1, 'P002', 'Coordenador', '2025-03-01', NULL),
    (2, 'P003', 'Coordenador', '2025-05-01', NULL),
    (3, 'P001', 'Bolsista',    '2025-02-15', NULL),   
    (3, 'P003', 'Colaborador', '2025-06-01', NULL),   
    (4, 'P001', 'Bolsista',    '2025-03-01', NULL),   
    (4, 'P002', 'Bolsista',    '2025-04-01', NULL),  
    (5, 'P002', 'Colaborador', '2025-03-15', '2025-12-31');

-- Alocacoes de financiamento
-- O financiamento 1 (CNPq, R$ 50.000,00) eh dividido entre P001 e P002:
-- 20.000,00 + 30.000,00 = 50.000,00 (exatamente o limite -- RN-16)
INSERT INTO alocacao_financiamento (codigo_projeto, id_financiamento, modalidade, valor_destinado) VALUES
    ('P001', 1, 'Parcial', 20000.00),
    ('P002', 1, 'Parcial', 30000.00),
    ('P003', 2, 'Total',   30000.00);

-- Producoes cientificas
INSERT INTO producao_cientifica (codigo_projeto, id_tipo_producao, titulo, ano_publicacao, meio_divulgacao) VALUES
    ('P001', 1, 'Qualidade da agua em bacias urbanas: um estudo de caso', 2025, 'Revista Brasileira de Recursos Hidricos'),
    ('P002', 3, 'AgroIA: sistema de apoio a decisao agricola',            2026, 'Repositorio institucional UFNES'),
    ('P002', 1, 'Redes neurais aplicadas a previsao de safra',            2026, 'Congresso Brasileiro de Agroinformatica'),
    ('P003', 4, 'Diagnostico de educacao ambiental na rede publica',      2026, 'Relatorio interno UFNES');

-- Autoria das producoes
INSERT INTO autoria (id_producao, id_participante, ordem_autoria) VALUES
    (1, 1, 1), (1, 3, 2),          
    (2, 1, 1), (2, 4, 2),          
    (3, 4, 1), (3, 1, 2),          
    (4, 2, 1), (4, 3, 2);          


