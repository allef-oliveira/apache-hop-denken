-- Cadastro
SELECT * FROM produto ORDER BY codigo;

-- Quantidade detalhada
SELECT COUNT(*) AS total_consolidado
FROM producao_consolidada;

-- PASS x FAIL
SELECT status, COUNT(*) AS quantidade
FROM producao_consolidada
GROUP BY status
ORDER BY status;

-- Desempenho por linha/produto
SELECT
    linha,
    produto,
    COUNT(*) AS total,
    ROUND(AVG(tempo_ciclo_segundos), 2) AS tempo_medio,
    ROUND(AVG(desvio_meta_segundos), 2) AS desvio_medio,
    ROUND(100.0 * SUM(flag_dentro_meta) / NULLIF(COUNT(*), 0), 2) AS aderencia_meta_pct
FROM producao_consolidada
GROUP BY linha, produto
ORDER BY linha, produto;

-- Casos mais críticos
SELECT
    numero_serie,
    linha,
    produto,
    status,
    tempo_ciclo_segundos,
    meta_ciclo_segundos,
    desvio_meta_segundos,
    classificacao_operacional
FROM producao_consolidada
ORDER BY desvio_meta_segundos DESC
LIMIT 20;

-- Camada analítica
SELECT *
FROM resumo_producao_consolidado
ORDER BY taxa_pass_pct ASC, aderencia_meta_pct ASC;
