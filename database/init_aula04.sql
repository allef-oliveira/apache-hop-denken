CREATE TABLE IF NOT EXISTS produto (
    codigo VARCHAR(30) PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL,
    familia VARCHAR(50) NOT NULL
);

INSERT INTO produto (codigo, descricao, familia)
VALUES
    ('PRODUTO_A', 'Placa Modelo A', 'FAMILY_A'),
    ('PRODUTO_B', 'Placa Modelo B', 'FAMILY_B'),
    ('PRODUTO_C', 'Placa Modelo C', 'FAMILY_C'),
    ('PRODUTO_D', 'Placa Modelo D', 'FAMILY_D')
ON CONFLICT (codigo) DO UPDATE SET
    descricao = EXCLUDED.descricao,
    familia = EXCLUDED.familia;

CREATE TABLE IF NOT EXISTS producao_consolidada (
    id BIGSERIAL PRIMARY KEY,
    data_hora TIMESTAMP NOT NULL,
    linha VARCHAR(10) NOT NULL,
    estacao VARCHAR(30) NOT NULL,
    produto VARCHAR(30) NOT NULL,
    descricao VARCHAR(100) NOT NULL,
    familia VARCHAR(50) NOT NULL,
    numero_serie VARCHAR(50) NOT NULL,
    status VARCHAR(10) NOT NULL,
    tempo_ciclo_segundos INTEGER NOT NULL,
    meta_ciclo_segundos INTEGER NOT NULL,
    meta_pass_pct NUMERIC(6,2) NOT NULL,
    desvio_meta_segundos INTEGER NOT NULL,
    percentual_tempo_meta NUMERIC(8,2),
    flag_pass INTEGER NOT NULL,
    flag_fail INTEGER NOT NULL,
    flag_dentro_meta INTEGER NOT NULL,
    classificacao_operacional VARCHAR(20) NOT NULL,
    CONSTRAINT uq_producao_consolidada_serial UNIQUE (numero_serie)
);

CREATE TABLE IF NOT EXISTS resumo_producao_consolidado (
    id BIGSERIAL PRIMARY KEY,
    linha VARCHAR(10) NOT NULL,
    produto VARCHAR(30) NOT NULL,
    total_testados BIGINT NOT NULL,
    total_pass BIGINT NOT NULL,
    total_fail BIGINT NOT NULL,
    total_dentro_meta BIGINT NOT NULL,
    tempo_medio NUMERIC(10,2),
    menor_tempo INTEGER,
    maior_tempo INTEGER,
    desvio_medio NUMERIC(10,2),
    meta_pass_pct NUMERIC(6,2),
    taxa_pass_pct NUMERIC(6,2),
    taxa_fail_pct NUMERIC(6,2),
    aderencia_meta_pct NUMERIC(6,2),
    atingiu_meta_qualidade VARCHAR(3),
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
