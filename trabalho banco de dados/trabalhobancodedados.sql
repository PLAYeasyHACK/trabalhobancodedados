DROP DATABASE IF EXISTS simu;
CREATE DATABASE simu
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
USE simu;

CREATE TABLE empresa_operadora (
    id_empresa     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    cnpj           CHAR(14)      NOT NULL,
    razao_social   VARCHAR(120)  NOT NULL,
    nome_fantasia  VARCHAR(80)   NOT NULL,
    telefone       VARCHAR(15)   NULL,
    email          VARCHAR(120)  NULL,
    ativa          BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_empresa       PRIMARY KEY (id_empresa),
    CONSTRAINT uq_empresa_cnpj  UNIQUE (cnpj),
    CONSTRAINT ck_empresa_cnpj  CHECK (CHAR_LENGTH(cnpj) = 14)
) ENGINE = InnoDB;

CREATE TABLE linha (
    id_linha      INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    codigo        VARCHAR(10)    NOT NULL,
    denominacao   VARCHAR(120)   NOT NULL,
    modal         ENUM('ONIBUS','METRO','BRT','VLT') NOT NULL DEFAULT 'ONIBUS',
    extensao_km   DECIMAL(6,2)   NOT NULL,
    tarifa_base   DECIMAL(6,2)   NOT NULL,
    id_empresa    INT UNSIGNED   NOT NULL,
    CONSTRAINT pk_linha          PRIMARY KEY (id_linha),
    CONSTRAINT uq_linha_codigo   UNIQUE (codigo),
    CONSTRAINT fk_linha_empresa  FOREIGN KEY (id_empresa)
        REFERENCES empresa_operadora (id_empresa)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_linha_tarifa   CHECK (tarifa_base >= 0),
    CONSTRAINT ck_linha_extensao CHECK (extensao_km > 0)
) ENGINE = InnoDB;

CREATE TABLE parada (
    id_parada   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(100)  NOT NULL,
    tipo        ENUM('PARADA','TERMINAL','ESTACAO') NOT NULL DEFAULT 'PARADA',
    logradouro  VARCHAR(120)  NOT NULL,
    numero      VARCHAR(10)   NULL,
    bairro      VARCHAR(60)   NOT NULL,
    cidade      VARCHAR(60)   NOT NULL,
    uf          CHAR(2)       NOT NULL,
    cep         CHAR(8)       NULL,
    latitude    DECIMAL(10,7) NULL,
    longitude   DECIMAL(10,7) NULL,
    acessivel   BOOLEAN       NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_parada    PRIMARY KEY (id_parada),
    CONSTRAINT ck_parada_uf CHECK (CHAR_LENGTH(uf) = 2)
) ENGINE = InnoDB;

CREATE INDEX ix_parada_bairro ON parada (cidade, bairro);

CREATE TABLE linha_parada (
    id_linha           INT UNSIGNED    NOT NULL,
    id_parada          INT UNSIGNED    NOT NULL,
    sentido            ENUM('IDA','VOLTA') NOT NULL,
    ordem              SMALLINT UNSIGNED NOT NULL,
    tempo_estimado_min SMALLINT UNSIGNED NOT NULL,
    CONSTRAINT pk_linha_parada        PRIMARY KEY (id_linha, id_parada, sentido),
    CONSTRAINT uq_linha_parada_ordem  UNIQUE (id_linha, sentido, ordem),
    CONSTRAINT fk_lp_linha            FOREIGN KEY (id_linha)
        REFERENCES linha (id_linha)  ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_lp_parada           FOREIGN KEY (id_parada)
        REFERENCES parada (id_parada) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE veiculo (
    id_veiculo      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    placa           CHAR(7)      NOT NULL,
    numero_frota    VARCHAR(10)  NOT NULL,
    modelo          VARCHAR(60)  NOT NULL,
    ano_fabricacao  YEAR         NOT NULL,
    capacidade      SMALLINT UNSIGNED NOT NULL,
    acessivel       BOOLEAN      NOT NULL DEFAULT FALSE,
    status          ENUM('ATIVO','MANUTENCAO','INATIVO') NOT NULL DEFAULT 'ATIVO',
    id_empresa      INT UNSIGNED NOT NULL,
    CONSTRAINT pk_veiculo          PRIMARY KEY (id_veiculo),
    CONSTRAINT uq_veiculo_placa    UNIQUE (placa),
    CONSTRAINT uq_veiculo_frota    UNIQUE (id_empresa, numero_frota),
    CONSTRAINT fk_veiculo_empresa  FOREIGN KEY (id_empresa)
        REFERENCES empresa_operadora (id_empresa)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_veiculo_cap      CHECK (capacidade BETWEEN 10 AND 300)
) ENGINE = InnoDB;

CREATE TABLE funcionario (
    id_funcionario INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cpf            CHAR(11)     NOT NULL,
    primeiro_nome  VARCHAR(40)  NOT NULL,
    sobrenome      VARCHAR(80)  NOT NULL,
    data_nascimento DATE        NOT NULL,
    data_admissao  DATE         NOT NULL,
    salario        DECIMAL(10,2) NOT NULL,
    tipo           ENUM('MOTORISTA','MECANICO','FISCAL') NOT NULL,
    id_empresa     INT UNSIGNED NOT NULL,
    CONSTRAINT pk_funcionario        PRIMARY KEY (id_funcionario),
    CONSTRAINT uq_funcionario_cpf    UNIQUE (cpf),
    CONSTRAINT fk_funcionario_emp    FOREIGN KEY (id_empresa)
        REFERENCES empresa_operadora (id_empresa)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_funcionario_sal    CHECK (salario > 0)
) ENGINE = InnoDB;

CREATE TABLE motorista (
    id_funcionario       INT UNSIGNED NOT NULL,
    data_validade_exame  DATE         NOT NULL,
    anos_experiencia     TINYINT UNSIGNED NOT NULL DEFAULT 0,
    CONSTRAINT pk_motorista PRIMARY KEY (id_funcionario),
    CONSTRAINT fk_motorista_func FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE mecanico (
    id_funcionario INT UNSIGNED NOT NULL,
    especialidade  ENUM('MOTOR','ELETRICA','FUNILARIA','SUSPENSAO') NOT NULL,
    registro_crea  VARCHAR(20) NULL,
    CONSTRAINT pk_mecanico PRIMARY KEY (id_funcionario),
    CONSTRAINT fk_mecanico_func FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE fiscal (
    id_funcionario INT UNSIGNED NOT NULL,
    setor          VARCHAR(60) NOT NULL,
    cracha         VARCHAR(15) NOT NULL,
    CONSTRAINT pk_fiscal        PRIMARY KEY (id_funcionario),
    CONSTRAINT uq_fiscal_cracha UNIQUE (cracha),
    CONSTRAINT fk_fiscal_func   FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE cnh (
    numero_registro CHAR(11)     NOT NULL,
    id_funcionario  INT UNSIGNED NOT NULL,
    categoria       ENUM('B','C','D','E') NOT NULL,
    data_emissao    DATE         NOT NULL,
    data_validade   DATE         NOT NULL,
    CONSTRAINT pk_cnh          PRIMARY KEY (numero_registro),
    CONSTRAINT uq_cnh_motorista UNIQUE (id_funcionario),
    CONSTRAINT fk_cnh_motorista FOREIGN KEY (id_funcionario)
        REFERENCES motorista (id_funcionario)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_cnh_datas     CHECK (data_validade > data_emissao)
) ENGINE = InnoDB;

CREATE TABLE usuario (
    id_usuario      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cpf             CHAR(11)     NOT NULL,
    primeiro_nome   VARCHAR(40)  NOT NULL,
    sobrenome       VARCHAR(80)  NOT NULL,
    data_nascimento DATE         NOT NULL,
    email           VARCHAR(120) NULL,
    logradouro      VARCHAR(120) NULL,
    numero          VARCHAR(10)  NULL,
    bairro          VARCHAR(60)  NULL,
    cidade          VARCHAR(60)  NULL,
    uf              CHAR(2)      NULL,
    cep             CHAR(8)      NULL,
    categoria       ENUM('COMUM','ESTUDANTE','IDOSO') NOT NULL DEFAULT 'COMUM',
    data_cadastro   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_usuario     PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuario_cpf UNIQUE (cpf)
) ENGINE = InnoDB;

CREATE TABLE usuario_telefone (
    id_usuario INT UNSIGNED NOT NULL,
    telefone   VARCHAR(15)  NOT NULL,
    tipo       ENUM('CELULAR','RESIDENCIAL','COMERCIAL') NOT NULL DEFAULT 'CELULAR',
    CONSTRAINT pk_usuario_telefone PRIMARY KEY (id_usuario, telefone),
    CONSTRAINT fk_tel_usuario      FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE usuario_estudante (
    id_usuario          INT UNSIGNED NOT NULL,
    matricula           VARCHAR(20)  NOT NULL,
    instituicao         VARCHAR(120) NOT NULL,
    percentual_desconto DECIMAL(5,2) NOT NULL DEFAULT 50.00,
    validade_carteirinha DATE        NOT NULL,
    CONSTRAINT pk_usu_estudante PRIMARY KEY (id_usuario),
    CONSTRAINT fk_est_usuario   FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_est_desconto  CHECK (percentual_desconto BETWEEN 0 AND 100)
) ENGINE = InnoDB;

CREATE TABLE usuario_idoso (
    id_usuario        INT UNSIGNED NOT NULL,
    data_comprovacao  DATE         NOT NULL,
    isento            BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_usu_idoso   PRIMARY KEY (id_usuario),
    CONSTRAINT fk_idoso_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE cartao (
    id_cartao     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    numero_serie  CHAR(16)      NOT NULL,
    id_usuario    INT UNSIGNED  NOT NULL,
    saldo         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    data_emissao  DATE          NOT NULL,
    status        ENUM('ATIVO','BLOQUEADO','CANCELADO') NOT NULL DEFAULT 'ATIVO',
    CONSTRAINT pk_cartao        PRIMARY KEY (id_cartao),
    CONSTRAINT uq_cartao_serie  UNIQUE (numero_serie),
    CONSTRAINT fk_cartao_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_cartao_saldo  CHECK (saldo >= 0)
) ENGINE = InnoDB;

CREATE TABLE recarga (
    id_cartao       INT UNSIGNED  NOT NULL,
    seq_recarga     SMALLINT UNSIGNED NOT NULL,
    data_hora       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor           DECIMAL(10,2) NOT NULL,
    forma_pagamento ENUM('PIX','CREDITO','DEBITO','DINHEIRO') NOT NULL,
    canal           ENUM('APP','TERMINAL','LOJA') NOT NULL DEFAULT 'APP',
    CONSTRAINT pk_recarga      PRIMARY KEY (id_cartao, seq_recarga),
    CONSTRAINT fk_recarga_cartao FOREIGN KEY (id_cartao)
        REFERENCES cartao (id_cartao)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_recarga_valor CHECK (valor > 0)
) ENGINE = InnoDB;

CREATE TABLE viagem (
    id_viagem       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_linha        INT UNSIGNED NOT NULL,
    id_veiculo      INT UNSIGNED NOT NULL,
    id_funcionario  INT UNSIGNED NOT NULL,
    sentido         ENUM('IDA','VOLTA') NOT NULL,
    data_hora_inicio DATETIME    NOT NULL,
    data_hora_fim    DATETIME    NULL,
    km_percorrido    DECIMAL(6,2) NULL,
    status           ENUM('PROGRAMADA','EM_CURSO','CONCLUIDA','CANCELADA')
                     NOT NULL DEFAULT 'PROGRAMADA',
    CONSTRAINT pk_viagem          PRIMARY KEY (id_viagem),
    CONSTRAINT uq_viagem_veiculo  UNIQUE (id_veiculo, data_hora_inicio),
    CONSTRAINT fk_viagem_linha    FOREIGN KEY (id_linha)
        REFERENCES linha (id_linha)   ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_viagem_veiculo  FOREIGN KEY (id_veiculo)
        REFERENCES veiculo (id_veiculo) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_viagem_motorista FOREIGN KEY (id_funcionario)
        REFERENCES motorista (id_funcionario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_viagem_periodo  CHECK (data_hora_fim IS NULL
                                         OR data_hora_fim > data_hora_inicio)
) ENGINE = InnoDB;

CREATE INDEX ix_viagem_linha_data ON viagem (id_linha, data_hora_inicio);

CREATE TABLE ocorrencia (
    id_viagem     INT UNSIGNED NOT NULL,
    seq_ocorrencia SMALLINT UNSIGNED NOT NULL,
    data_hora     DATETIME     NOT NULL,
    tipo          ENUM('ATRASO','ACIDENTE','PANE','SUPERLOTACAO','OUTRO') NOT NULL,
    gravidade     ENUM('BAIXA','MEDIA','ALTA') NOT NULL DEFAULT 'BAIXA',
    descricao     VARCHAR(255) NULL,
    CONSTRAINT pk_ocorrencia      PRIMARY KEY (id_viagem, seq_ocorrencia),
    CONSTRAINT fk_ocorrencia_viagem FOREIGN KEY (id_viagem)
        REFERENCES viagem (id_viagem)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE embarque (
    id_embarque   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    id_cartao     INT UNSIGNED  NOT NULL,
    id_viagem     INT UNSIGNED  NOT NULL,
    id_parada     INT UNSIGNED  NOT NULL,
    data_hora     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_pago    DECIMAL(6,2)  NOT NULL,
    tipo_tarifa   ENUM('INTEGRAL','ESTUDANTE','GRATUIDADE','INTEGRACAO') NOT NULL,
    CONSTRAINT pk_embarque        PRIMARY KEY (id_embarque),
    CONSTRAINT uq_embarque        UNIQUE (id_cartao, id_viagem, data_hora),
    CONSTRAINT fk_embarque_cartao FOREIGN KEY (id_cartao)
        REFERENCES cartao (id_cartao) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_embarque_viagem FOREIGN KEY (id_viagem)
        REFERENCES viagem (id_viagem) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_embarque_parada FOREIGN KEY (id_parada)
        REFERENCES parada (id_parada) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_embarque_valor  CHECK (valor_pago >= 0)
) ENGINE = InnoDB;

CREATE TABLE manutencao (
    id_manutencao  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    id_veiculo     INT UNSIGNED  NOT NULL,
    id_funcionario INT UNSIGNED  NOT NULL,
    tipo           ENUM('PREVENTIVA','CORRETIVA') NOT NULL,
    data_entrada   DATE          NOT NULL,
    data_saida     DATE          NULL,
    custo          DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    descricao      VARCHAR(255)  NULL,
    CONSTRAINT pk_manutencao        PRIMARY KEY (id_manutencao),
    CONSTRAINT fk_manut_veiculo     FOREIGN KEY (id_veiculo)
        REFERENCES veiculo (id_veiculo) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_manut_mecanico    FOREIGN KEY (id_funcionario)
        REFERENCES mecanico (id_funcionario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_manut_datas       CHECK (data_saida IS NULL OR data_saida >= data_entrada),
    CONSTRAINT ck_manut_custo       CHECK (custo >= 0)
) ENGINE = InnoDB;

INSERT INTO empresa_operadora (cnpj, razao_social, nome_fantasia, telefone, email) VALUES
('12345678000199','Viação Planalto Transportes Ltda','Viação Planalto','6132221000','contato@planalto.com.br'),
('98765432000155','Urbano Mobilidade S.A.','Urbano Mob','6133334000','sac@urbanomob.com.br'),
('45678912000133','Metrô Integrado do DF S.A.','Metrô DF','6134445000','faleconosco@metrodf.com.br');

INSERT INTO linha (codigo, denominacao, modal, extensao_km, tarifa_base, id_empresa) VALUES
('0.110','Luziânia - Rodoviária do Plano Piloto','ONIBUS',62.50,7.50,1),
('0.220','Valparaíso - Setor Comercial Sul','ONIBUS',48.30,6.50,1),
('0.331','Gama - Taguatinga (Expresso)','BRT',35.00,5.50,2),
('0.450','Ceilândia - Asa Norte','ONIBUS',41.20,5.50,2),
('MET-01','Samambaia - Central','METRO',42.00,5.00,3);

INSERT INTO parada (nome, tipo, logradouro, numero, bairro, cidade, uf, cep, latitude, longitude, acessivel) VALUES
('Terminal Luziânia','TERMINAL','Avenida JK','1000','Centro','Luziânia','GO','72800100',-16.2526000,-47.9503000,TRUE),
('Parada Jardim Ingá','PARADA','BR-040 km 24',NULL,'Jardim Ingá','Luziânia','GO','72870000',-16.1500000,-47.9600000,FALSE),
('Rodoviária do Plano Piloto','TERMINAL','Eixo Monumental','S/N','Asa Sul','Brasília','DF','70070000',-15.7942000,-47.8822000,TRUE),
('Estação Setor Comercial Sul','ESTACAO','SCS Quadra 2','10','Asa Sul','Brasília','DF','70300500',-15.7970000,-47.8900000,TRUE),
('Terminal Gama','TERMINAL','Praça Central','50','Setor Central','Gama','DF','72405610',-16.0180000,-48.0650000,TRUE),
('Terminal Taguatinga','TERMINAL','Avenida Comercial','200','Taguatinga Centro','Taguatinga','DF','72015900',-15.8330000,-48.0570000,TRUE),
('Parada Ceilândia Norte','PARADA','QNM 18',NULL,'Ceilândia','Ceilândia','DF','72215180',-15.8100000,-48.1100000,FALSE),
('Estação Samambaia','ESTACAO','Avenida Samambaia','S/N','Samambaia Sul','Samambaia','DF','72300000',-15.8800000,-48.0900000,TRUE);

INSERT INTO linha_parada (id_linha, id_parada, sentido, ordem, tempo_estimado_min) VALUES
(1,1,'IDA',1,0),(1,2,'IDA',2,18),(1,3,'IDA',3,65),
(1,3,'VOLTA',1,0),(1,2,'VOLTA',2,50),(1,1,'VOLTA',3,70),
(2,2,'IDA',1,0),(2,4,'IDA',2,55),
(3,5,'IDA',1,0),(3,6,'IDA',2,38),
(4,7,'IDA',1,0),(4,3,'IDA',2,45),
(5,8,'IDA',1,0),(5,3,'IDA',2,40);

INSERT INTO veiculo (placa, numero_frota, modelo, ano_fabricacao, capacidade, acessivel, status, id_empresa) VALUES
('JKL1A23','1001','Mercedes-Benz O500U',2021,90,TRUE,'ATIVO',1),
('JKL1A24','1002','Volvo B270F',2019,85,FALSE,'ATIVO',1),
('JKL1A25','1003','Marcopolo Torino',2018,80,TRUE,'MANUTENCAO',1),
('MNO2B34','2001','Scania K310 Articulado',2022,140,TRUE,'ATIVO',2),
('MNO2B35','2002','Caio Millennium BRT',2020,120,TRUE,'ATIVO',2),
('PQR3C45','3001','Alstom Metropolis',2017,300,TRUE,'ATIVO',3);

INSERT INTO funcionario (cpf, primeiro_nome, sobrenome, data_nascimento, data_admissao, salario, tipo, id_empresa) VALUES
('11122233344','Carlos','Almeida Souza','1985-04-12','2015-03-01',3800.00,'MOTORISTA',1),
('22233344455','Fernanda','Lima Rocha','1990-09-30','2018-07-15',3950.00,'MOTORISTA',1),
('33344455566','Rafael','Teixeira Dias','1988-01-22','2017-02-10',4100.00,'MOTORISTA',2),
('44455566677','Juliana','Moreira Pinto','1992-11-05','2020-05-20',4300.00,'MOTORISTA',3),
('55566677788','Marcos','Pereira Lopes','1979-06-18','2012-08-01',4500.00,'MECANICO',1),
('66677788899','Patrícia','Nogueira Campos','1986-03-27','2019-01-07',4200.00,'MECANICO',2),
('77788899900','Bruno','Cardoso Martins','1994-12-02','2021-04-12',3200.00,'FISCAL',1),
('88899900011','Aline','Ferreira Gomes','1991-08-09','2022-02-14',3300.00,'FISCAL',2);

INSERT INTO motorista (id_funcionario, data_validade_exame, anos_experiencia) VALUES
(1,'2027-04-30',15),(2,'2026-12-31',8),(3,'2027-08-15',11),(4,'2026-11-20',6);

INSERT INTO mecanico (id_funcionario, especialidade, registro_crea) VALUES
(5,'MOTOR','CREA-DF-45120'),(6,'ELETRICA','CREA-DF-51877');

INSERT INTO fiscal (id_funcionario, setor, cracha) VALUES
(7,'Bilhetagem','FIS-0001'),(8,'Operação','FIS-0002');

INSERT INTO cnh (numero_registro, id_funcionario, categoria, data_emissao, data_validade) VALUES
('01234567890',1,'D','2021-05-10','2026-05-10'),
('11234567891',2,'D','2022-03-18','2027-03-18'),
('21234567892',3,'E','2020-09-01','2025-09-01'),
('31234567893',4,'D','2023-02-25','2028-02-25');

INSERT INTO usuario (cpf, primeiro_nome, sobrenome, data_nascimento, email, logradouro, numero, bairro, cidade, uf, cep, categoria) VALUES
('90011122233','Victor','Santos Oliveira','2003-05-14','victor.so@email.com','Rua das Palmeiras','120','Centro','Luziânia','GO','72800110','ESTUDANTE'),
('90022233344','Mariana','Costa Ribeiro','1998-02-08','mariana.cr@email.com','Quadra 10 Conjunto B','7','Jardim Ingá','Luziânia','GO','72870010','COMUM'),
('90033344455','José','Barbosa Filho','1955-07-21','jose.bf@email.com','QNM 18 Conjunto D','15','Ceilândia','Ceilândia','DF','72215180','IDOSO'),
('90044455566','Camila','Andrade Nunes','2001-10-03','camila.an@email.com','SQN 210 Bloco C','504','Asa Norte','Brasília','DF','70862030','ESTUDANTE'),
('90055566677','Roberto','Silva Menezes','1987-12-19','roberto.sm@email.com','Avenida Central','88','Setor Central','Gama','DF','72405610','COMUM'),
('90066677788','Terezinha','Alves Campos','1950-03-30',NULL,'Rua 12','45','Samambaia Sul','Samambaia','DF','72300120','IDOSO');

INSERT INTO usuario_telefone (id_usuario, telefone, tipo) VALUES
(1,'61991110001','CELULAR'),(1,'6133330001','RESIDENCIAL'),
(2,'61991110002','CELULAR'),
(3,'61991110003','CELULAR'),(3,'6133330003','RESIDENCIAL'),
(4,'61991110004','CELULAR'),
(5,'61991110005','CELULAR'),(5,'6133330005','COMERCIAL'),
(6,'61991110006','CELULAR');

INSERT INTO usuario_estudante (id_usuario, matricula, instituicao, percentual_desconto, validade_carteirinha) VALUES
(1,'UCB20230145','Universidade Católica de Brasília',50.00,'2026-12-31'),
(4,'UNB20210987','Universidade de Brasília',50.00,'2026-06-30');

INSERT INTO usuario_idoso (id_usuario, data_comprovacao, isento) VALUES
(3,'2020-08-15',TRUE),
(6,'2015-04-02',TRUE);

INSERT INTO cartao (numero_serie, id_usuario, saldo, data_emissao, status) VALUES
('1000000000000001',1,45.50,'2023-03-10','ATIVO'),
('1000000000000002',2,12.00,'2022-11-05','ATIVO'),
('1000000000000003',3,0.00,'2021-06-30','ATIVO'),
('1000000000000004',4,88.25,'2024-01-20','ATIVO'),
('1000000000000005',5,3.50,'2023-09-14','BLOQUEADO'),
('1000000000000006',6,0.00,'2019-02-11','ATIVO');

INSERT INTO recarga (id_cartao, seq_recarga, data_hora, valor, forma_pagamento, canal) VALUES
(1,1,'2026-08-01 09:12:00',50.00,'PIX','APP'),
(1,2,'2026-09-02 18:40:00',30.00,'CREDITO','APP'),
(2,1,'2026-08-15 07:55:00',20.00,'DINHEIRO','TERMINAL'),
(2,2,'2026-09-10 12:30:00',25.00,'DEBITO','LOJA'),
(4,1,'2026-09-05 08:05:00',100.00,'PIX','APP'),
(5,1,'2026-07-22 19:10:00',15.00,'DINHEIRO','TERMINAL');

INSERT INTO viagem (id_linha, id_veiculo, id_funcionario, sentido, data_hora_inicio, data_hora_fim, km_percorrido, status) VALUES
(1,1,1,'IDA','2026-09-15 05:30:00','2026-09-15 06:45:00',62.50,'CONCLUIDA'),
(1,1,1,'VOLTA','2026-09-15 07:10:00','2026-09-15 08:30:00',62.50,'CONCLUIDA'),
(1,2,2,'IDA','2026-09-15 06:00:00','2026-09-15 07:20:00',62.50,'CONCLUIDA'),
(2,2,2,'IDA','2026-09-16 05:45:00','2026-09-16 06:50:00',48.30,'CONCLUIDA'),
(3,4,3,'IDA','2026-09-16 06:15:00','2026-09-16 06:58:00',35.00,'CONCLUIDA'),
(4,5,3,'IDA','2026-09-17 05:50:00','2026-09-17 06:40:00',41.20,'CONCLUIDA'),
(5,6,4,'IDA','2026-09-17 06:00:00','2026-09-17 06:42:00',42.00,'CONCLUIDA'),
(1,1,1,'IDA','2026-09-18 05:30:00',NULL,NULL,'PROGRAMADA');

INSERT INTO ocorrencia (id_viagem, seq_ocorrencia, data_hora, tipo, gravidade, descricao) VALUES
(1,1,'2026-09-15 06:05:00','ATRASO','BAIXA','Congestionamento na BR-040'),
(3,1,'2026-09-15 06:40:00','SUPERLOTACAO','MEDIA','Demanda acima da capacidade no horário de pico'),
(5,1,'2026-09-16 06:30:00','PANE','ALTA','Falha no sistema de ar-condicionado'),
(5,2,'2026-09-16 06:35:00','ATRASO','MEDIA','Parada técnica de 10 minutos');

INSERT INTO embarque (id_cartao, id_viagem, id_parada, data_hora, valor_pago, tipo_tarifa) VALUES
(1,1,1,'2026-09-15 05:32:00',3.75,'ESTUDANTE'),
(2,1,2,'2026-09-15 05:51:00',7.50,'INTEGRAL'),
(3,1,1,'2026-09-15 05:33:00',0.00,'GRATUIDADE'),
(1,2,3,'2026-09-15 07:12:00',3.75,'ESTUDANTE'),
(2,3,2,'2026-09-15 06:20:00',7.50,'INTEGRAL'),
(4,4,2,'2026-09-16 05:48:00',3.25,'ESTUDANTE'),
(6,5,5,'2026-09-16 06:18:00',0.00,'GRATUIDADE'),
(2,6,7,'2026-09-17 05:55:00',5.50,'INTEGRAL'),
(4,7,8,'2026-09-17 06:02:00',2.50,'ESTUDANTE'),
(1,6,7,'2026-09-17 05:57:00',2.75,'INTEGRACAO');

INSERT INTO manutencao (id_veiculo, id_funcionario, tipo, data_entrada, data_saida, custo, descricao) VALUES
(3,5,'CORRETIVA','2026-09-01','2026-09-12',4850.00,'Retífica parcial do motor'),
(1,5,'PREVENTIVA','2026-08-10','2026-08-11',620.00,'Troca de óleo e filtros'),
(4,6,'CORRETIVA','2026-09-16',NULL,0.00,'Diagnóstico do sistema elétrico'),
(5,6,'PREVENTIVA','2026-07-05','2026-07-06',780.00,'Revisão de 20.000 km');

SELECT l.codigo, l.denominacao, lp.sentido, lp.ordem,
       p.nome AS parada, CONCAT(p.bairro,' - ',p.cidade,'/',p.uf) AS localizacao,
       lp.tempo_estimado_min
FROM   linha l
JOIN   linha_parada lp ON lp.id_linha = l.id_linha
JOIN   parada p        ON p.id_parada = lp.id_parada
WHERE  l.codigo = '0.110'
ORDER  BY lp.sentido, lp.ordem;

SELECT l.codigo, l.denominacao,
       COUNT(e.id_embarque)  AS total_embarques,
       SUM(e.valor_pago)     AS arrecadacao,
       ROUND(AVG(e.valor_pago),2) AS ticket_medio
FROM   linha l
JOIN   viagem v   ON v.id_linha  = l.id_linha
JOIN   embarque e ON e.id_viagem = v.id_viagem
GROUP  BY l.id_linha, l.codigo, l.denominacao
HAVING COUNT(e.id_embarque) > 1
ORDER  BY arrecadacao DESC;

SELECT e.tipo_tarifa,
       COUNT(*)                AS qtd,
       SUM(e.valor_pago)       AS valor_arrecadado,
       SUM(l.tarifa_base - e.valor_pago) AS subsidio_concedido
FROM   embarque e
JOIN   viagem v ON v.id_viagem = e.id_viagem
JOIN   linha  l ON l.id_linha  = v.id_linha
GROUP  BY e.tipo_tarifa
ORDER  BY subsidio_concedido DESC;

SELECT u.id_usuario, CONCAT(u.primeiro_nome,' ',u.sobrenome) AS nome,
       u.categoria,
       TIMESTAMPDIFF(YEAR, u.data_nascimento, CURDATE()) AS idade,
       ue.instituicao, ue.percentual_desconto,
       ui.isento
FROM   usuario u
LEFT   JOIN usuario_estudante ue ON ue.id_usuario = u.id_usuario
LEFT   JOIN usuario_idoso     ui ON ui.id_usuario = u.id_usuario
ORDER  BY u.categoria, nome;

SELECT u.id_usuario, CONCAT(u.primeiro_nome,' ',u.sobrenome) AS nome,
       GROUP_CONCAT(t.telefone ORDER BY t.tipo SEPARATOR ' / ') AS telefones
FROM   usuario u
JOIN   usuario_telefone t ON t.id_usuario = u.id_usuario
GROUP  BY u.id_usuario, nome;

SELECT c.numero_serie, 'RECARGA' AS movimento, r.data_hora, r.valor AS valor
FROM   cartao c JOIN recarga r ON r.id_cartao = c.id_cartao
WHERE  c.id_cartao = 1
UNION ALL
SELECT c.numero_serie, 'EMBARQUE', e.data_hora, -e.valor_pago
FROM   cartao c JOIN embarque e ON e.id_cartao = c.id_cartao
WHERE  c.id_cartao = 1
ORDER  BY data_hora;

SELECT CONCAT(f.primeiro_nome,' ',f.sobrenome) AS motorista,
       ch.categoria AS cnh, ch.data_validade,
       COUNT(DISTINCT v.id_viagem) AS viagens,
       COALESCE(SUM(v.km_percorrido),0) AS km_total,
       COUNT(o.seq_ocorrencia) AS ocorrencias
FROM   motorista m
JOIN   funcionario f ON f.id_funcionario = m.id_funcionario
LEFT   JOIN cnh ch   ON ch.id_funcionario = m.id_funcionario
LEFT   JOIN viagem v ON v.id_funcionario = m.id_funcionario AND v.status = 'CONCLUIDA'
LEFT   JOIN ocorrencia o ON o.id_viagem = v.id_viagem
GROUP  BY m.id_funcionario, motorista, ch.categoria, ch.data_validade
ORDER  BY km_total DESC;

SELECT l.codigo, l.denominacao, SUM(e.valor_pago) AS arrecadacao
FROM   linha l
JOIN   viagem v   ON v.id_linha  = l.id_linha
JOIN   embarque e ON e.id_viagem = v.id_viagem
GROUP  BY l.id_linha, l.codigo, l.denominacao
HAVING SUM(e.valor_pago) > (
        SELECT AVG(total) FROM (
            SELECT SUM(e2.valor_pago) AS total
            FROM   embarque e2
            JOIN   viagem v2 ON v2.id_viagem = e2.id_viagem
            GROUP  BY v2.id_linha
        ) AS sub
);

SELECT emp.nome_fantasia, ve.placa, ve.modelo, ve.status,
       COUNT(mt.id_manutencao) AS qtd_manutencoes,
       SUM(mt.custo)           AS custo_total,
       MAX(mt.data_entrada)    AS ultima_entrada
FROM   veiculo ve
JOIN   empresa_operadora emp ON emp.id_empresa = ve.id_empresa
LEFT   JOIN manutencao mt    ON mt.id_veiculo  = ve.id_veiculo
GROUP  BY emp.nome_fantasia, ve.id_veiculo, ve.placa, ve.modelo, ve.status
ORDER  BY custo_total DESC;

SELECT 'Frota' AS dimensao,
       COUNT(*) AS total,
       SUM(acessivel) AS acessiveis,
       ROUND(100 * SUM(acessivel)/COUNT(*),2) AS percentual
FROM   veiculo
UNION ALL
SELECT 'Paradas', COUNT(*), SUM(acessivel),
       ROUND(100 * SUM(acessivel)/COUNT(*),2)
FROM   parada;

SELECT o.tipo, o.gravidade, o.data_hora, o.descricao,
       l.codigo AS linha, ve.placa,
       CONCAT(f.primeiro_nome,' ',f.sobrenome) AS motorista
FROM   ocorrencia o
JOIN   viagem v      ON v.id_viagem = o.id_viagem
JOIN   linha l       ON l.id_linha  = v.id_linha
JOIN   veiculo ve    ON ve.id_veiculo = v.id_veiculo
JOIN   funcionario f ON f.id_funcionario = v.id_funcionario
WHERE  o.gravidade IN ('MEDIA','ALTA')
ORDER  BY FIELD(o.gravidade,'ALTA','MEDIA'), o.data_hora;

SELECT HOUR(e.data_hora) AS hora, COUNT(*) AS embarques,
       SUM(e.valor_pago) AS arrecadacao
FROM   embarque e
GROUP  BY HOUR(e.data_hora)
ORDER  BY hora;

UPDATE linha
SET    tarifa_base = ROUND(tarifa_base * 1.08, 2)
WHERE  modal = 'ONIBUS';

UPDATE cartao c
SET    c.saldo = c.saldo + (
        SELECT COALESCE(SUM(r.valor),0)
        FROM   recarga r
        WHERE  r.id_cartao = c.id_cartao
          AND  r.data_hora >= '2026-09-01'
)
WHERE  c.status = 'ATIVO';

UPDATE cartao c
JOIN   embarque e ON e.id_cartao = c.id_cartao
SET    c.saldo = c.saldo - e.valor_pago
WHERE  e.id_embarque = 10 AND c.saldo >= e.valor_pago;

UPDATE veiculo v
SET    v.status = 'ATIVO'
WHERE  v.status = 'MANUTENCAO'
  AND  NOT EXISTS (SELECT 1 FROM manutencao m
                   WHERE m.id_veiculo = v.id_veiculo AND m.data_saida IS NULL);

UPDATE manutencao
SET    data_saida = CURDATE(),
       custo      = 1290.00,
       descricao  = CONCAT(descricao, ' - chicote elétrico substituído')
WHERE  id_manutencao = 3 AND data_saida IS NULL;

UPDATE viagem
SET    status = 'CONCLUIDA',
       data_hora_fim = '2026-09-18 06:47:00',
       km_percorrido = 62.50
WHERE  id_viagem = 8 AND status = 'PROGRAMADA';

UPDATE cartao c
SET    c.status = 'BLOQUEADO'
WHERE  c.status = 'ATIVO'
  AND  NOT EXISTS (SELECT 1 FROM embarque e
                   WHERE e.id_cartao = c.id_cartao
                     AND e.data_hora >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH));

UPDATE usuario
SET    categoria = 'IDOSO'
WHERE  TIMESTAMPDIFF(YEAR, data_nascimento, CURDATE()) >= 65
  AND  categoria <> 'IDOSO';

UPDATE usuario_estudante
SET    validade_carteirinha = DATE_ADD(validade_carteirinha, INTERVAL 1 YEAR)
WHERE  validade_carteirinha BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY);

UPDATE motorista m
JOIN   cnh c ON c.id_funcionario = m.id_funcionario
SET    m.data_validade_exame = CURDATE()
WHERE  c.data_validade < CURDATE();

CREATE OR REPLACE VIEW vw_demanda_linha AS
SELECT l.id_linha, l.codigo, l.denominacao, emp.nome_fantasia AS operadora,
       COUNT(DISTINCT v.id_viagem) AS viagens,
       COUNT(e.id_embarque)        AS embarques,
       COALESCE(SUM(e.valor_pago),0) AS arrecadacao
FROM   linha l
JOIN   empresa_operadora emp ON emp.id_empresa = l.id_empresa
LEFT   JOIN viagem v   ON v.id_linha  = l.id_linha
LEFT   JOIN embarque e ON e.id_viagem = v.id_viagem
GROUP  BY l.id_linha, l.codigo, l.denominacao, emp.nome_fantasia;

SELECT * FROM vw_demanda_linha ORDER BY arrecadacao DESC;
