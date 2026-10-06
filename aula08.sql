-- Database: db_aula08

-- DROP DATABASE IF EXISTS db_aula08;

CREATE DATABASE db_aula08
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Portuguese_Brazil.1252'
    LC_CTYPE = 'Portuguese_Brazil.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- tabelas --

CREATE TABLE Cliente (
    cpf VARCHAR(14) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    endereco VARCHAR(200),
    telefone VARCHAR(20)
);

CREATE TABLE Veiculo (
    renavan VARCHAR(11) PRIMARY KEY,
    chassi VARCHAR(20) NOT NULL,
    placa VARCHAR(10) NOT NULL,
    modelo VARCHAR(50),
    cor VARCHAR(30),
    situacao VARCHAR(30),
    cliente VARCHAR(14),
    FOREIGN KEY (cliente) REFERENCES Cliente(cpf)
);

CREATE TABLE RelatoCliente (
    id INT PRIMARY KEY,
    problema VARCHAR(200),
    data DATE,
    veiculo VARCHAR(11),
    FOREIGN KEY (veiculo) REFERENCES Veiculo(renavan)
);

CREATE TABLE Orcamento (
    id INT PRIMARY KEY,
    valor NUMERIC(10,2),
    data DATE,
    situacao VARCHAR(30),
    mecanico VARCHAR(100),
    totalHoras NUMERIC(5,2),
    previsaoEnt DATE,
    formaPag VARCHAR(30),
    veiculo VARCHAR(11),
    FOREIGN KEY (veiculo) REFERENCES Veiculo(renavan)
);

CREATE TABLE Servico (
    id INT PRIMARY KEY,
    descricao VARCHAR(100),
    custo NUMERIC(10,2),
    tempo NUMERIC(5,2)
);

CREATE TABLE Peca (
    id INT PRIMARY KEY,
    descricao VARCHAR(100),
    custo NUMERIC(10,2)
);

CREATE TABLE ItemServico (
    id INT PRIMARY KEY,
    orcamento INT,
    servico INT,
    situacao VARCHAR(30),
    FOREIGN KEY (orcamento) REFERENCES Orcamento(id),
    FOREIGN KEY (servico) REFERENCES Servico(id)
);

CREATE TABLE ItemPeca (
    id INT PRIMARY KEY,
    orcamento INT,
    peca INT,
    quantidade INT,
    custoTotalPeca NUMERIC(10,2),
    situacao VARCHAR(30),
    FOREIGN KEY (orcamento) REFERENCES Orcamento(id),
    FOREIGN KEY (peca) REFERENCES Peca(id)
);

-- sequences --

CREATE SEQUENCE seq_relato START 1;
CREATE SEQUENCE seq_orcamento START 1;
CREATE SEQUENCE seq_servico START 1;
CREATE SEQUENCE seq_peca START 1;
CREATE SEQUENCE seq_itemservico START 1;
CREATE SEQUENCE seq_itempeca START 1;

-- 3 registro em cada tabela --

INSERT INTO Cliente VALUES
('11111111111','João Silva','Rua A, 100','11999999999'),
('22222222222','Maria Souza','Rua B, 200','11888888888'),
('33333333333','Pedro Santos','Rua C, 300','11777777777');


INSERT INTO Veiculo VALUES
('100000001','CH001','ABC1234','Gol','Prata','Ativo','11111111111'),
('100000002','CH002','DEF5678','Onix','Branco','Ativo','22222222222'),
('100000003','CH003','GHI9012','HB20','Preto','Ativo','33333333333');
``

INSERT INTO RelatoCliente VALUES
(nextval('seq_relato'),'Troca de óleo','2025-01-10','100000001'),
(nextval('seq_relato'),'Barulho no motor','2025-02-15','100000001'),
(nextval('seq_relato'),'Problema no freio','2025-03-05','100000002');

INSERT INTO Orcamento VALUES
(nextval('seq_orcamento'),500.00,'2025-01-15',
'Finalizado','Carlos',5,'2025-01-18','Cartão','100000001'),

(nextval('seq_orcamento'),1200.00,'2025-03-06',
'Em andamento','José',10,'2025-03-10','Pix','100000002'),

(nextval('seq_orcamento'),800.00,'2025-04-01',
'Finalizado','Marcos',8,'2025-04-05','Dinheiro','100000003');

INSERT INTO Servico VALUES
(nextval('seq_servico'),'Troca de óleo',150.00,1),
(nextval('seq_servico'),'Alinhamento',100.00,2),
(nextval('seq_servico'),'Troca de freio',300.00,3);


INSERT INTO Peca VALUES
(nextval('seq_peca'),'Filtro de óleo',50.00),
(nextval('seq_peca'),'Pastilha de freio',120.00),
(nextval('seq_peca'),'Correia dentada',180.00);

INSERT INTO ItemServico VALUES
(nextval('seq_itemservico'),1,1,'Concluído'),
(nextval('seq_itemservico'),2,2,'Em andamento'),
(nextval('seq_itemservico'),3,3,'Concluído');


INSERT INTO ItemPeca VALUES
(nextval('seq_itempeca'),1,1,1,50.00,'Instalada'),
(nextval('seq_itempeca'),2,2,2,240.00,'Pendente'),
(nextval('seq_itempeca'),3,3,1,180.00,'Instalada');

-- funçoes --
-- 4 -- 
CREATE OR REPLACE FUNCTION historico_problemas(p_renavan VARCHAR)
RETURNS TABLE(
    id_relato INT,
    problema VARCHAR,
    data_relato DATE
)
AS $$
BEGIN
    RETURN QUERY
    SELECT rc.id,
           rc.problema,
           rc.data
    FROM RelatoCliente rc
    WHERE rc.veiculo = p_renavan
    ORDER BY rc.data;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM historico_problemas('100000001');

-- 5 -- 
CREATE OR REPLACE FUNCTION veiculos_cliente(p_nome VARCHAR)
RETURNS TABLE(
    renavan VARCHAR,
    placa VARCHAR,
    modelo VARCHAR,
    cor VARCHAR
)
AS $$
BEGIN
    RETURN QUERY
    SELECT v.renavan,
           v.placa,
           v.modelo,
           v.cor
    FROM Veiculo v
    INNER JOIN Cliente c
        ON v.cliente = c.cpf
    WHERE c.nome ILIKE p_nome;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM veiculos_cliente('João Silva');

-- 6 --
CREATE OR REPLACE FUNCTION servicos_orcamento(p_codigo INT)
RETURNS TABLE(
    descricao VARCHAR,
    custo NUMERIC,
    tempo NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
    SELECT s.descricao,
           s.custo,
           s.tempo
    FROM ItemServico i
    INNER JOIN Servico s
        ON i.servico = s.id
    WHERE i.orcamento = p_codigo
    ORDER BY s.descricao;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM servicos_orcamento(1);

-- 7 -- 
CREATE OR REPLACE FUNCTION total_gasto_cliente(p_nome VARCHAR)
RETURNS NUMERIC
AS $$
DECLARE
    total NUMERIC;
BEGIN

    SELECT COALESCE(SUM(o.valor),0)
    INTO total
    FROM Orcamento o
         INNER JOIN Veiculo v
         ON o.veiculo = v.renavan
         INNER JOIN Cliente c
         ON v.cliente = c.cpf
    WHERE c.nome ILIKE p_nome;

    RETURN total;

END;
$$ LANGUAGE plpgsql;

SELECT total_gasto_cliente('João Silva');

-- 8 -- 
CREATE OR REPLACE FUNCTION excluir_orcamento(p_codigo INT)
RETURNS TEXT
AS $$
BEGIN

    DELETE FROM ItemServico
    WHERE orcamento = p_codigo;

    DELETE FROM ItemPeca
    WHERE orcamento = p_codigo;

    DELETE FROM Orcamento
    WHERE id = p_codigo;

    RETURN 'Orçamento excluído com sucesso!';

END;
$$ LANGUAGE plpgsql;

SELECT excluir_orcamento(1);