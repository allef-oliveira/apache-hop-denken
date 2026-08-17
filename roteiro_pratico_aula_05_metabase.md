# Roteiro Prático — Aula 05: Visualização de Dados e Dashboards com Metabase

## 1. Identificação

**Módulo:** 6 — Apache Hop  
**Aula:** 05  
**Modalidade:** presencial  
**Duração:** 3 horas  
**Tema:** criação de dashboards visuais com Metabase a partir dos dados consolidados pelo ETL

---

## 2. Objetivo da aula

Nesta aula, o foco deixa de ser a construção do pipeline ETL e passa a ser a **visualização e interpretação dos dados consolidados**.

Arquitetura:

```text
Apache Hop
    ↓
ETL / Consolidação
    ↓
PostgreSQL
    ↓
Metabase
    ↓
Questions
    ↓
Visualizações
    ↓
Dashboard
    ↓
Análise e decisão
```

Ao final, o aluno deverá ser capaz de:

- conectar o Metabase ao PostgreSQL;
- explorar tabelas e campos;
- utilizar o Query Builder;
- criar Questions;
- criar KPIs;
- construir gráficos de barras e linhas;
- criar tabelas analíticas;
- montar um dashboard;
- adicionar filtros interativos;
- interpretar os indicadores apresentados;
- justificar decisões a partir dos dados.

---

## 3. Pré-requisitos

A Aula 04 deve ter produzido as tabelas:

```text
producao_consolidada
resumo_producao_consolidado
```

A principal tabela será:

```text
producao_consolidada
```

Campos relevantes:

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

Também será utilizada:

```text
resumo_producao_consolidado
```

---

## 4. Resultado esperado

Ao final da aula, cada grupo deverá possuir um dashboard semelhante a:

```text
┌──────────────────────────────────────────────────────────────┐
│                 DASHBOARD DE PRODUÇÃO                       │
│                                                              │
│ [ Linha ▼ ] [ Produto ▼ ] [ Período ▼ ]                     │
│                                                              │
│ Total testado   Taxa PASS   Taxa FAIL   Dentro da meta      │
│                                                              │
│ Taxa PASS por linha       Tempo médio por produto            │
│ █████████████            ███████████                         │
│ ████████████             █████████████                       │
│                                                              │
│ Produção por hora         Aderência à meta por linha         │
│ ───╱╲────╱──╲──          ████████████                       │
│                                                              │
│ Falhas por estação                                           │
│ ███████████████                                              │
│                                                              │
│ Desempenho por linha e produto                               │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Linha | Produto | PASS | FAIL | Tempo | Desvio | Meta   │ │
│ └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

---

## 5. Cronograma

| Tempo | Etapa |
|---:|---|
| 0–15 min | Introdução: dado, métrica, KPI e dashboard |
| 15–30 min | Escolha correta de visualizações |
| 30–45 min | Arquitetura Metabase + PostgreSQL |
| 45–60 min | Inicialização e conexão |
| 60–80 min | Query Builder e primeira Question |
| 80–100 min | Criação dos KPIs |
| 100–110 min | Intervalo |
| 110–140 min | Construção dos gráficos |
| 140–160 min | Montagem do dashboard |
| 160–172 min | Filtros e interatividade |
| 172–180 min | Desafio analítico e encerramento |

---

# Parte A — Conceitos

## 6. Dado, métrica, KPI e dashboard

Exemplo de dado:

```text
SN04000567
L02
PRODUTO_B
PASS
53 segundos
```

Métrica:

```text
Total de registros PASS
```

KPI:

```text
Taxa PASS = PASS / Total
```

Visualização:

```text
Card com percentual
```

Dashboard:

```text
Conjunto de KPIs + gráficos + filtros + tabelas
```

---

## 7. Antes de criar um gráfico, faça uma pergunta

Não comece por:

```text
Qual gráfico eu quero?
```

Comece por:

```text
O que eu quero descobrir?
```

Exemplos:

```text
Quanto produzimos?
→ Total testado
```

```text
Qual linha apresenta pior qualidade?
→ Taxa FAIL por linha
```

```text
Qual produto possui maior tempo médio?
→ Tempo médio por produto
```

```text
Como a produção evoluiu durante o período?
→ Produção por hora
```

---

## 8. Escolha da visualização

```text
Um único valor
→ KPI / Number
```

```text
Comparação entre categorias
→ Barras
```

```text
Evolução no tempo
→ Linha
```

```text
Detalhamento
→ Tabela
```

```text
Relação entre duas variáveis
→ Dispersão
```

---

# Parte B — Ambiente

## 9. Docker Compose

Utilize o PostgreSQL da Aula 04 e adicione o Metabase:

```yaml
services:
  postgres:
    image: postgres:16
    container_name: hop-postgres-aula04
    restart: unless-stopped
    environment:
      POSTGRES_DB: hop_aula04
      POSTGRES_USER: hop
      POSTGRES_PASSWORD: hop123
    ports:
      - "5433:5432"
    volumes:
      - hop_postgres_aula04_data:/var/lib/postgresql/data
      - ./init_aula04.sql:/docker-entrypoint-initdb.d/01-init.sql:ro

  metabase:
    image: metabase/metabase:latest
    container_name: metabase-aula05
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      MB_DB_TYPE: h2
      MB_DB_FILE: /metabase-data/metabase.db
    volumes:
      - metabase_aula05_data:/metabase-data
    depends_on:
      - postgres

volumes:
  hop_postgres_aula04_data:
  metabase_aula05_data:
```

---

## 10. Subir os containers

```bash
docker compose up -d
```

Ou:

```bash
docker compose up -d metabase
```

Confira:

```bash
docker compose ps
```

Acesse:

```text
http://localhost:3000
```

---

# Parte C — Configuração inicial do Metabase

## 11. Criar o usuário inicial

Ao abrir o Metabase pela primeira vez:

1. selecione o idioma;
2. informe nome;
3. informe e-mail;
4. defina a senha;
5. prossiga para a conexão com o banco.

---

## 12. Conectar ao PostgreSQL

Configuração:

```text
Display name: Produção - Aula 04
Database type: PostgreSQL

Host: postgres
Port: 5432
Database: hop_aula04
Username: hop
Password: hop123
```

> Como Metabase e PostgreSQL estão na mesma rede Docker, use `postgres` como host, e não `localhost`.

---

## 13. Conferir as tabelas

Procure:

```text
produto
producao_consolidada
resumo_producao_consolidado
```

Abra:

```text
producao_consolidada
```

Explore alguns registros.

---

# Parte D — Primeira Question

## 14. Criar o total testado

No Metabase:

```text
New
→ Question
→ Produção - Aula 04
→ producao_consolidada
```

Depois:

```text
Summarize
→ Count of rows
```

Visualização:

```text
Number
```

Salvar como:

```text
KPI - Total testado
```

---

# Parte E — KPIs principais

## 15. KPI — Taxa PASS

Em:

```text
Summarize
→ Custom Expression
```

Crie:

```text
Share([status] = "PASS")
```

Visualização:

```text
Number
```

Formatação:

```text
Percentual
1 casa decimal
```

Salvar como:

```text
KPI - Taxa PASS
```

---

## 16. KPI — Taxa FAIL

Crie:

```text
Share([status] = "FAIL")
```

Salvar:

```text
KPI - Taxa FAIL
```

---

## 17. KPI — Aderência ao tempo-meta

Crie:

```text
Share([flag_dentro_meta] = 1)
```

Salvar:

```text
KPI - Aderência à meta
```

---

## 18. Resultado esperado dos KPIs

Primeira linha do dashboard:

```text
Total testado
Taxa PASS
Taxa FAIL
Aderência à meta
```

---

# Parte F — Gráficos

## 19. Taxa PASS por linha

Fonte:

```text
producao_consolidada
```

Summarize:

```text
Share([status] = "PASS")
```

Group by:

```text
linha
```

Visualização:

```text
Bar
```

Título:

```text
Taxa PASS por linha
```

---

## 20. Tempo médio por produto

Summarize:

```text
Average of tempo_ciclo_segundos
```

Group by:

```text
produto
```

Visualização:

```text
Bar
```

Título:

```text
Tempo médio por produto
```

---

## 21. Produção por hora

Summarize:

```text
Count of rows
```

Group by:

```text
data_hora
```

Granularidade:

```text
Hour
```

Visualização:

```text
Line
```

Título:

```text
Produção por hora
```

---

## 22. Falhas por estação

Filtro:

```text
status = FAIL
```

Summarize:

```text
Count of rows
```

Group by:

```text
estacao
```

Visualização:

```text
Bar
```

Título:

```text
Falhas por estação
```

---

## 23. Aderência ao tempo-meta por linha

Summarize:

```text
Share([flag_dentro_meta] = 1)
```

Group by:

```text
linha
```

Visualização:

```text
Bar
```

Título:

```text
Aderência ao tempo-meta por linha
```

---

# Parte G — Tabela analítica

## 24. Utilizar a tabela resumida

Crie uma Question sobre:

```text
resumo_producao_consolidado
```

Exiba:

```text
linha
produto
total_testados
total_pass
total_fail
taxa_pass_pct
taxa_fail_pct
tempo_medio
desvio_medio
aderencia_meta_pct
atingiu_meta_qualidade
```

Ordenar por:

```text
taxa_pass_pct ASC
```

e depois:

```text
aderencia_meta_pct ASC
```

Visualização:

```text
Table
```

Salvar como:

```text
Desempenho por linha e produto
```

---

# Parte H — Criar o dashboard

## 25. Criar

```text
New
→ Dashboard
```

Nome:

```text
Dashboard de Produção e Qualidade
```

---

## 26. Adicionar os cards

Adicionar:

```text
KPI - Total testado
KPI - Taxa PASS
KPI - Taxa FAIL
KPI - Aderência à meta
Taxa PASS por linha
Tempo médio por produto
Produção por hora
Falhas por estação
Aderência ao tempo-meta por linha
Desempenho por linha e produto
```

---

## 27. Organização visual

```text
┌─────────────────────────────────────────────────────────┐
│ Total      PASS       FAIL       Aderência              │
├────────────────────────┬────────────────────────────────┤
│ Taxa PASS por linha    │ Tempo médio por produto        │
├────────────────────────┴────────────────────────────────┤
│ Produção por hora                                       │
├────────────────────────┬────────────────────────────────┤
│ Falhas por estação     │ Aderência por linha            │
├────────────────────────┴────────────────────────────────┤
│ Desempenho por linha e produto                          │
└─────────────────────────────────────────────────────────┘
```

Hierarquia:

```text
Topo
→ KPIs principais
```

```text
Centro
→ comparações e tendência
```

```text
Final
→ detalhamento
```

---

# Parte I — Filtros

## 28. Filtro por linha

Adicione:

```text
Linha
```

Tipo:

```text
Text or Category
```

Conecte ao campo:

```text
linha
```

em todos os cards compatíveis.

Teste:

```text
L01
L02
L03
L04
```

---

## 29. Filtro por produto

Adicione:

```text
Produto
```

Tipo:

```text
Text or Category
```

Conecte ao campo:

```text
produto
```

Teste:

```text
PRODUTO_A
```

---

## 30. Filtro por período

Adicione:

```text
Período
```

Tipo:

```text
Date
```

Conecte:

```text
data_hora
```

aos cards baseados em:

```text
producao_consolidada
```

---

# Parte J — Refinamento visual

## 31. Revisar títulos

Evite:

```text
Question 1
Question 2
Average of tempo_ciclo_segundos
```

Prefira:

```text
Taxa PASS por linha
Tempo médio por produto
Falhas por estação
Produção por hora
```

---

## 32. Revisar unidades

```text
taxas
→ %
```

```text
tempos
→ segundos
```

```text
quantidades
→ número inteiro
```

---

## 33. Evitar excesso visual

Evite:

```text
muitos gráficos
cores demais
gráficos repetidos
cards sem pergunta clara
```

Prefira:

```text
4 KPIs
4 ou 5 gráficos
1 tabela
3 filtros
```

---

# Parte K — Análise orientada

## 34. Utilize o dashboard para responder

1. Qual linha possui pior taxa PASS?
2. Qual linha possui menor aderência ao tempo-meta?
3. Qual produto possui maior tempo médio?
4. Qual estação concentra mais falhas?
5. Existe uma linha com boa taxa PASS, mas baixa aderência à meta?
6. Qual combinação `linha + produto` merece investigação prioritária?

---

## 35. Justificar com múltiplas evidências

Não responda apenas:

```text
L02 está pior.
```

Utilize:

```text
Taxa PASS
+
Taxa FAIL
+
Tempo médio
+
Desvio médio
+
Aderência à meta
```

---

# Parte L — Desafio

## 36. Criar uma Question adicional

Cada grupo deverá criar uma visualização que não tenha sido construída durante a demonstração.

Sugestões:

```text
Top 5 maiores desvios
```

```text
Quantidade de registros críticos por linha
```

```text
Tempo médio por estação
```

```text
PASS x FAIL por produto
```

```text
Produção por estação
```

```text
Desvio médio por produto
```

---

## 37. Adicionar ao dashboard

A Question deverá:

- responder uma pergunta clara;
- utilizar uma visualização adequada;
- possuir título compreensível;
- ser adicionada ao dashboard;
- acrescentar informação nova.

---

# Parte M — Desafio final

## 38. Diagnóstico operacional

Escolha uma situação prioritária.

Utilize pelo menos três visualizações diferentes do dashboard.

Responder:

```text
Qual é o problema?
```

```text
Onde ele ocorre?
```

```text
Quais indicadores sustentam essa conclusão?
```

```text
O problema parece estar relacionado à qualidade,
à eficiência ou aos dois?
```

---

# 39. Evidências para entrega

Capturar:

- conexão do PostgreSQL;
- primeira Question;
- KPI Total;
- KPI Taxa PASS;
- KPI Taxa FAIL;
- KPI Aderência;
- gráfico Taxa PASS por linha;
- gráfico Produção por hora;
- dashboard completo;
- dashboard filtrado por linha;
- dashboard filtrado por produto;
- Question adicional criada.

---

# 40. Checklist

- [ ] Metabase iniciado
- [ ] PostgreSQL conectado
- [ ] tabelas sincronizadas
- [ ] `producao_consolidada` explorada
- [ ] Query Builder utilizado
- [ ] KPI Total criado
- [ ] KPI Taxa PASS criado
- [ ] KPI Taxa FAIL criado
- [ ] KPI Aderência criado
- [ ] Taxa PASS por linha criada
- [ ] Tempo médio por produto criado
- [ ] Produção por hora criada
- [ ] Falhas por estação criada
- [ ] Aderência por linha criada
- [ ] Tabela analítica criada
- [ ] Dashboard criado
- [ ] Layout organizado
- [ ] Filtro Linha criado
- [ ] Filtro Produto criado
- [ ] Filtro Período criado
- [ ] Question adicional criada
- [ ] Diagnóstico operacional concluído

---

# 41. Arquitetura consolidada

```text
CSV ───────────────┐
                   │
PostgreSQL ────────┼→ Apache Hop
                   │       ↓
Excel ─────────────┘      ETL
                           ↓
                      PostgreSQL
                           ↓
                        Metabase
                           ↓
                       Questions
                           ↓
                    Visualizações
                           ↓
                       Dashboard
                           ↓
                    Tomada de decisão
```

---

# 42. Resultado conceitual

```text
dados estruturados
       ↓
    métricas
       ↓
      KPIs
       ↓
    gráficos
       ↓
   dashboard
       ↓
     análise
       ↓
     decisão
```

---

# 43. Encerramento

> Um pipeline ETL entrega dados confiáveis.  
> Um dashboard transforma esses dados em informação acessível para análise e tomada de decisão.

A próxima etapa do módulo será trabalhar **workflows, parâmetros, automação, logs e tratamento de erros**.
