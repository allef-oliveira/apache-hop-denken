# Roteiro Prático — Aula 04: Integração de Múltiplas Fontes e Pipeline ETL Completo

## Identificação

**Módulo:** 6 — Apache Hop  
**Aula:** 04  
**Modalidade:** presencial  
**Duração:** 2 horas  
**Tema:** integração de CSV, PostgreSQL e Excel em um pipeline ETL completo

---

# 1. Objetivo

Nesta prática construiremos um fluxo que integra:

```text
CSV de produção
+
PostgreSQL com cadastro de produtos
+
Excel com metas por linha/produto
```

para produzir:

```text
Base detalhada consolidada
+
Base analítica com KPIs
+
Arquivo de registros sem referência
```

Ao final, você terá trabalhado com:

- `Text File Input`;
- `Table Input`;
- `Microsoft Excel Input`;
- `Stream Lookup`;
- `Sort Rows`;
- `Merge Join`;
- `Filter Rows`;
- `Formula`;
- `Select Values`;
- `Table Output`;
- `Group By`;
- roteamento com `Copy rows`;
- validação quantitativa do ETL.

---

# 2. Estrutura do laboratório

```text
aula04_apache_hop/
├── datasets/
│   ├── producao_limpa_aula04.csv
│   └── metas_producao.xlsx
├── database/
│   ├── docker-compose.yml
│   ├── init_aula04.sql
│   ├── reset_aula04.sql
│   └── consultas_validacao.sql
├── pipelines/
├── output/
└── roteiro_pratico_aula_04_apache_hop.md
```

Crie seu pipeline em:

```text
pipelines/aula04_etl_multiplas_fontes.hpl
```

---

# 3. O cenário

## Produção — CSV

Arquivo:

```text
datasets/producao_limpa_aula04.csv
```

Campos:

```text
data_hora
linha
estacao
produto
numero_serie
status
tempo_ciclo_segundos
```

O arquivo contém **1.000 registros** e já está limpo.

Entretanto, há dois problemas intencionais:

```text
PRODUTO_X / PRODUTO_Y
```

não existem no cadastro corporativo.

E:

```text
L04 + PRODUTO_D
```

possui produto cadastrado, mas não possui meta na planilha.

---

## Cadastro — PostgreSQL

Tabela:

```text
produto
```

Campos:

```text
codigo
descricao
familia
```

Produtos conhecidos:

```text
PRODUTO_A
PRODUTO_B
PRODUTO_C
PRODUTO_D
```

---

## Metas — Excel

Arquivo:

```text
datasets/metas_producao.xlsx
```

Planilha:

```text
METAS
```

Campos:

```text
linha
produto
meta_ciclo_segundos
meta_pass_pct
```

A chave da meta é composta:

```text
linha + produto
```

Isso significa que:

```text
L01 + PRODUTO_A
```

pode possuir uma meta diferente de:

```text
L02 + PRODUTO_A
```

---

# 4. Subir o PostgreSQL

Entre na pasta:

```text
database/
```

Execute:

```bash
docker compose up -d
```

Confira:

```bash
docker compose ps
```

Dados da conexão:

```text
Host: localhost
Port: 5433
Database: hop_aula04
Username: hop
Password: hop123
```

> A porta 5433 foi escolhida para não colidir com o PostgreSQL da Aula 03, caso ele ainda esteja rodando.

No Apache Hop, crie:

```text
PostgreSQL_Aula04
```

e teste a conexão.

---

# 5. Conferir a tabela de produtos

Execute:

```sql
SELECT *
FROM produto
ORDER BY codigo;
```

Você deverá encontrar quatro produtos.

---

# 6. Arquitetura do pipeline

```text
                       PostgreSQL
                           ↓
                      Table Input
                           ↓
CSV ───────────────→ Stream Lookup
                           ↓
                       Sort Rows
                           ↓
                           ├────────────────┐
                           │                │
                           │            Excel Metas
                           │                ↓
                           │            Excel Input
                           │                ↓
                           │            Sort Rows
                           │                │
                           └────────┬───────┘
                                    ↓
                               Merge Join
                                    ↓
                           Referências válidas?
                           ↙                 ↘
                         NÃO                 SIM
                          ↓                   ↓
                    CSV rejeitados          Formula
                                              ↓
                                        Select Values
                                              ↓
                                        COPY ROWS
                                         ↙        ↘
                              Base detalhada      Agregação
                                    ↓                 ↓
                              Table Output         Sort Rows
                                                      ↓
                                                   Group By
                                                      ↓
                                                   Formula
                                                      ↓
                                                Table Output
```

---

# PARTE A — Extração

## 7. Ler o CSV

Adicione:

```text
Text File Input
```

Nome:

```text
Ler produção
```

Arquivo:

```text
${PROJECT_HOME}/datasets/producao_limpa_aula04.csv
```

Configuração:

```text
Separador: ,
Enclosure: "
Header: sim
Encoding: UTF-8
```

Campos:

| Campo | Tipo |
|---|---|
| data_hora | Date |
| linha | String |
| estacao | String |
| produto | String |
| numero_serie | String |
| status | String |
| tempo_ciclo_segundos | Integer |

Formato:

```text
yyyy-MM-dd HH:mm:ss
```

Faça preview.

---

## 8. Ler o cadastro do PostgreSQL

Adicione:

```text
Table Input
```

Nome:

```text
Ler cadastro de produtos
```

SQL:

```sql
SELECT
    codigo,
    descricao,
    familia
FROM produto
ORDER BY codigo;
```

Faça preview.

---

## 9. Ler as metas do Excel

Adicione:

```text
Microsoft Excel Input
```

Nome:

```text
Ler metas
```

Arquivo:

```text
${PROJECT_HOME}/datasets/metas_producao.xlsx
```

Planilha:

```text
METAS
```

Leia apenas:

```text
linha
produto
meta_ciclo_segundos
meta_pass_pct
```

Renomeie:

```text
linha   → linha_meta
produto → produto_meta
```

Tipos:

| Campo | Tipo |
|---|---|
| linha_meta | String |
| produto_meta | String |
| meta_ciclo_segundos | Integer |
| meta_pass_pct | Number |

Faça preview.

---

# PARTE B — Stream Lookup

## 10. Enriquecer os produtos

Adicione:

```text
Stream Lookup
```

Nome:

```text
Enriquecer produto
```

Stream principal:

```text
Ler produção
```

Lookup stream:

```text
Ler cadastro de produtos
```

Chave:

```text
produto = codigo
```

Recupere:

```text
descricao
familia
```

Faça preview.

Para produtos conhecidos:

```text
PRODUTO_A
→ Placa Modelo A
→ FAMILY_A
```

Para:

```text
PRODUTO_X
PRODUTO_Y
```

os campos de referência ficarão sem valor.

---

# PARTE C — Preparar o Join

## 11. Ordenar a produção

Após `Stream Lookup`, adicione:

```text
Sort Rows
```

Nome:

```text
Ordenar produção
```

Ordenação:

```text
linha ASC
produto ASC
```

---

## 12. Ordenar as metas

Após `Microsoft Excel Input`, adicione:

```text
Sort Rows
```

Nome:

```text
Ordenar metas
```

Ordenação:

```text
linha_meta ASC
produto_meta ASC
```

---

# PARTE D — Merge Join

## 13. Integrar a planilha de metas

Adicione:

```text
Merge Join
```

Nome:

```text
Integrar metas
```

Primeiro stream:

```text
Ordenar produção
```

Segundo stream:

```text
Ordenar metas
```

Join:

```text
LEFT OUTER
```

Chaves:

```text
linha   = linha_meta
produto = produto_meta
```

Faça preview.

Procure:

```text
L04 + PRODUTO_D
```

Esse registro deverá continuar no pipeline, porém:

```text
meta_ciclo_segundos = null
meta_pass_pct = null
```

Esse comportamento é exatamente o que queremos.

---

# PARTE E — Qualidade da integração

## 14. Separar registros sem referência

Adicione:

```text
Filter Rows
```

Nome:

```text
Referências encontradas?
```

Condição:

```text
descricao IS NOT NULL
AND
meta_ciclo_segundos IS NOT NULL
```

Fluxo:

```text
TRUE  → registros válidos
FALSE → registros sem referência
```

---

## 15. Gravar registros sem referência

Saída `FALSE`:

```text
Text File Output
```

Nome:

```text
Gravar registros sem referência
```

Arquivo:

```text
${PROJECT_HOME}/output/registros_sem_referencia.csv
```

Campos sugeridos:

```text
data_hora
linha
estacao
produto
numero_serie
status
tempo_ciclo_segundos
descricao
familia
meta_ciclo_segundos
meta_pass_pct
```

Ao final, o arquivo deverá conter dois tipos de ocorrência:

```text
Produto sem cadastro
```

e:

```text
Combinação linha/produto sem meta
```

---

# PARTE F — Regras de negócio

## 16. Formula

Na saída válida, adicione:

```text
Formula
```

Nome:

```text
Calcular indicadores do registro
```

Crie os seguintes campos.

### desvio_meta_segundos

Tipo:

```text
Integer
```

Fórmula:

```text
[tempo_ciclo_segundos]-[meta_ciclo_segundos]
```

---

### percentual_tempo_meta

Tipo:

```text
Number
```

Fórmula:

```text
([tempo_ciclo_segundos]/[meta_ciclo_segundos])*100
```

---

### flag_pass

Tipo:

```text
Integer
```

Fórmula:

```text
IF([status]="PASS",1,0)
```

---

### flag_fail

Tipo:

```text
Integer
```

Fórmula:

```text
IF([status]="FAIL",1,0)
```

---

### flag_dentro_meta

Tipo:

```text
Integer
```

Fórmula:

```text
IF([tempo_ciclo_segundos]<=[meta_ciclo_segundos],1,0)
```

---

### classificacao_operacional

Tipo:

```text
String
```

Fórmula:

```text
IF(OR([status]="FAIL",[tempo_ciclo_segundos]>[meta_ciclo_segundos]*1.2),"CRITICO","NORMAL")
```

Faça preview.

Observe que um registro pode ser:

```text
PASS
```

e ainda assim:

```text
CRITICO
```

caso o tempo de ciclo esteja muito acima da meta.

---

# PARTE G — Preparar a base consolidada

## 17. Select Values

Adicione:

```text
Select Values
```

Nome:

```text
Preparar base consolidada
```

Mantenha:

```text
data_hora
linha
estacao
produto
descricao
familia
numero_serie
status
tempo_ciclo_segundos
meta_ciclo_segundos
meta_pass_pct
desvio_meta_segundos
percentual_tempo_meta
flag_pass
flag_fail
flag_dentro_meta
classificacao_operacional
```

Remova campos auxiliares como:

```text
codigo
linha_meta
produto_meta
```

---

# PARTE H — Dividir o fluxo corretamente

## 18. Base detalhada + agregação

Precisamos que **todos os registros válidos** sigam para dois destinos:

```text
Base detalhada
```

e:

```text
Agregação
```

Crie dois hops saindo de:

```text
Preparar base consolidada
```

Depois, no roteamento do transform, selecione:

```text
Copy rows
```

e não:

```text
Distribute rows
```

A diferença é importante:

```text
Copy rows
→ cada ramo recebe todas as linhas
```

```text
Distribute rows
→ as linhas são divididas entre os ramos
```

Se você distribuir as linhas, a base detalhada e o `Group By` receberão apenas partes diferentes da produção, produzindo resultados incorretos.

---

# PARTE I — Base detalhada

## 19. Table Output

Em um dos ramos, adicione:

```text
Table Output
```

Nome:

```text
Gravar produção consolidada
```

Tabela:

```text
producao_consolidada
```

Conexão:

```text
PostgreSQL_Aula04
```

Mapeie os campos de mesmo nome.

Não envie:

```text
id
```

---

# PARTE J — Agregação

## 20. Ordenar para o Group By

No segundo ramo, adicione:

```text
Sort Rows
```

Nome:

```text
Ordenar para agregação
```

Ordenação:

```text
linha ASC
produto ASC
```

---

## 21. Group By

Adicione:

```text
Group By
```

Nome:

```text
Consolidar indicadores
```

Agrupar por:

```text
linha
produto
```

Agregações:

| Campo de saída | Campo de entrada | Operação |
|---|---|---|
| total_testados | — | Number of rows |
| total_pass | flag_pass | Sum |
| total_fail | flag_fail | Sum |
| total_dentro_meta | flag_dentro_meta | Sum |
| tempo_medio | tempo_ciclo_segundos | Average |
| menor_tempo | tempo_ciclo_segundos | Minimum |
| maior_tempo | tempo_ciclo_segundos | Maximum |
| desvio_medio | desvio_meta_segundos | Average |
| meta_pass_pct | meta_pass_pct | First non-null value |

Faça preview.

Agora:

```text
muitos seriais
```

foram transformados em:

```text
uma linha por linha + produto
```

---

# PARTE K — KPIs

## 22. Formula após o Group By

Adicione:

```text
Formula
```

Nome:

```text
Calcular KPIs
```

### taxa_pass_pct

```text
([total_pass]/[total_testados])*100
```

### taxa_fail_pct

```text
([total_fail]/[total_testados])*100
```

### aderencia_meta_pct

```text
([total_dentro_meta]/[total_testados])*100
```

### atingiu_meta_qualidade

```text
IF([taxa_pass_pct]>=[meta_pass_pct],"SIM","NAO")
```

---

# PARTE L — Base analítica

## 23. Table Output

Adicione:

```text
Table Output
```

Nome:

```text
Gravar resumo consolidado
```

Tabela:

```text
resumo_producao_consolidado
```

Mapeie:

```text
linha
produto
total_testados
total_pass
total_fail
total_dentro_meta
tempo_medio
menor_tempo
maior_tempo
desvio_medio
meta_pass_pct
taxa_pass_pct
taxa_fail_pct
aderencia_meta_pct
atingiu_meta_qualidade
```

Não envie:

```text
id
criado_em
```

O PostgreSQL preencherá esses campos automaticamente.

---

# PARTE M — Antes de executar novamente

## 24. Reset do laboratório

O `Table Output` realiza inserções.

Se você executar o pipeline novamente sem limpar as tabelas:

```text
producao_consolidada
resumo_producao_consolidado
```

poderá ter conflito com a chave única de serial ou duplicar os resumos.

Para repetir a prática, execute:

```text
database/reset_aula04.sql
```

ou:

```sql
TRUNCATE TABLE resumo_producao_consolidado RESTART IDENTITY;
TRUNCATE TABLE producao_consolidada RESTART IDENTITY;
```

---

# PARTE N — Validação

## 25. Reconciliação

Entrada:

```text
1000 registros
```

Preencha:

| Métrica | Quantidade |
|---|---:|
| Entrada CSV | 1000 |
| Registros sem referência | |
| Registros válidos | |
| `producao_consolidada` | |

A relação esperada é:

```text
Entrada
=
Válidos
+
Sem referência
```

e:

```text
Válidos
=
producao_consolidada
```

---

## 26. Consultas

Utilize:

```text
database/consultas_validacao.sql
```

Verifique:

```sql
SELECT COUNT(*)
FROM producao_consolidada;
```

Depois:

```sql
SELECT *
FROM resumo_producao_consolidado
ORDER BY taxa_pass_pct, aderencia_meta_pct;
```

---

# PARTE O — Análise

## 27. Perguntas

Responda:

1. Qual combinação `linha + produto` apresenta maior taxa de falha?
2. Qual apresenta maior tempo médio?
3. Qual possui maior desvio médio?
4. Qual possui menor aderência ao tempo-meta?
5. Existe uma combinação com boa taxa PASS, mas desempenho de ciclo ruim?
6. Qual combinação deveria receber atenção primeiro?
7. Quantos registros ficaram sem referência?
8. Entre os rejeitados, quais são problemas de cadastro e quais são problemas de meta?

---

# PARTE P — Desafio

## 28. Pior cenário operacional

Escolha uma combinação:

```text
linha + produto
```

e justifique a prioridade de investigação utilizando no mínimo três indicadores:

```text
taxa_pass_pct
taxa_fail_pct
tempo_medio
desvio_medio
aderencia_meta_pct
```

Responda também:

> O problema parece estar relacionado principalmente à qualidade, à eficiência do processo ou aos dois?

---

# 29. Evidências para entrega

Entregar:

```text
pipelines/aula04_etl_multiplas_fontes.hpl
output/registros_sem_referencia.csv
```

E capturas de:

- preview do CSV;
- preview do PostgreSQL;
- preview do Excel;
- `Stream Lookup`;
- `Merge Join`;
- `Filter Rows`;
- campos criados no `Formula`;
- roteamento `Copy rows`;
- `Group By`;
- tabela `producao_consolidada`;
- tabela `resumo_producao_consolidado`.

---

# 30. Checklist

- [ ] PostgreSQL iniciado
- [ ] conexão criada e testada
- [ ] CSV lido
- [ ] cadastro lido
- [ ] Excel lido
- [ ] Stream Lookup configurado
- [ ] streams ordenados
- [ ] Merge Join configurado
- [ ] rejeitados separados
- [ ] métricas por registro calculadas
- [ ] Select Values configurado
- [ ] roteamento configurado como Copy rows
- [ ] base detalhada persistida
- [ ] stream ordenado para Group By
- [ ] Group By configurado
- [ ] KPIs calculados
- [ ] base analítica persistida
- [ ] quantidades reconciliadas
- [ ] análise final realizada

---

# 31. Resultado conceitual

```text
CSV + PostgreSQL + Excel
          ↓
      Integração
          ↓
     Enriquecimento
          ↓
      Validação
          ↓
  Regras de negócio
          ↓
   Base detalhada
          ↓
      Agregação
          ↓
         KPIs
```

Esses KPIs serão utilizados na **Aula 05 — Visualização de Dados e Dashboards**.

---

# 32. Referências oficiais

- Stream Lookup: https://hop.apache.org/manual/latest/pipeline/transforms/streamlookup.html
- Merge Join: https://hop.apache.org/manual/latest/pipeline/transforms/mergejoin.html
- Microsoft Excel Input: https://hop.apache.org/manual/latest/pipeline/transforms/excelinput.html
- Group By: https://hop.apache.org/manual/latest/pipeline/transforms/groupby.html
- Formula: https://hop.apache.org/manual/latest/pipeline/transforms/formula.html
- Criação e roteamento de pipelines: https://hop.apache.org/manual/latest/pipeline/create-pipeline.html
