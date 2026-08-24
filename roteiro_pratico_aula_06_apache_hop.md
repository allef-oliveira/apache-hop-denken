# Roteiro Prático — Aula 06: Workflows, Parametrização, Automação, Logs e Tratamento de Erros

## 1. Identificação

**Módulo:** 6 — Apache Hop  
**Aula:** 06  
**Modalidade:** presencial  
**Duração:** 3 horas  
**Tema:** operacionalização de pipelines ETL com workflows, parâmetros, validação e monitoramento

---

## 2. Objetivo da aula

Nesta aula, o foco passa a ser a transformação de um pipeline que funciona manualmente em um processo ETL **controlado, repetível e automatizável**.

Arquitetura conceitual:

```text
Validação de entrada
        ↓
Preparação da execução
        ↓
Execução do ETL
        ↓
Validação da carga
        ↓
Sucesso / Falha
        ↓
Logs
```

Ao final, o aluno deverá ser capaz de:

- diferenciar pipeline e workflow;
- utilizar actions e workflow hops;
- criar caminhos de sucesso e falha;
- declarar e utilizar parâmetros;
- compreender parâmetros x variáveis;
- passar parâmetros de workflow para pipeline;
- verificar arquivos antes do processamento;
- executar pipelines dentro de workflows;
- executar SQL em um workflow;
- validar quantitativamente uma carga;
- configurar logs;
- interpretar níveis de logging;
- interromper corretamente uma execução com erro;
- executar workflows através do `hop-run`;
- compreender como o workflow mantém a base consumida pelo dashboard atualizada.

---

## 3. Continuidade do módulo

Até aqui:

```text
Aula 01
Dados → Pipeline

Aula 02
Dados → Qualidade

Aula 03
Dados → Banco

Aula 04
Múltiplas fontes → ETL → KPIs

Aula 05
KPIs → Metabase → Dashboard
```

Agora:

```text
Aula 06

        Workflow
           ↓
     valida entradas
           ↓
      executa ETL
           ↓
       valida carga
           ↓
         logs
           ↓
    banco atualizado
           ↓
       dashboard
```

Antes:

```text
Pessoa
  ↓
abre Hop
  ↓
executa pipeline
```

Depois:

```text
Workflow
   ↓
controla execução
   ↓
Pipeline
```

---

## 4. Cenário prático

Reutilizaremos o pipeline da Aula 04:

```text
aula04_etl_multiplas_fontes.hpl
```

Entradas:

```text
producao_limpa_aula04.csv
metas_producao.xlsx
PostgreSQL
```

Saídas:

```text
producao_consolidada
resumo_producao_consolidado
registros_sem_referencia.csv
```

O objetivo é garantir que:

1. os arquivos existam;
2. as tabelas estejam preparadas;
3. o pipeline execute corretamente;
4. a quantidade final seja a esperada;
5. qualquer problema leve o workflow para falha;
6. a execução deixe evidências em log.

---

## 5. Resultado esperado

Workflow final:

```text
                         START
                           ↓
                 Verificar arquivos
                    ↙            ↘
                FALHA           SUCESSO
                  ↓                ↓
            Abort Workflow    Preparar carga
                                   ↓
                              Executar ETL
                              ↙          ↘
                           FALHA        SUCESSO
                             ↓             ↓
                          Abort       Validar carga
                                          ↓
                                    Total correto?
                                    ↙          ↘
                                  NÃO           SIM
                                   ↓             ↓
                                Abort         Success
```

---

## 6. Cronograma

| Tempo | Etapa |
|---:|---|
| 0–15 min | Revisão e problema de operacionalização |
| 15–35 min | Pipeline x Workflow |
| 35–55 min | Parâmetros e variáveis |
| 55–75 min | Criação do workflow |
| 75–95 min | Validação dos arquivos e preparação |
| 95–105 min | Intervalo |
| 105–125 min | Execução do pipeline e rotas de erro |
| 125–145 min | Validação quantitativa da carga |
| 145–160 min | Logging e troubleshooting |
| 160–172 min | Execução por `hop-run` |
| 172–180 min | Testes de falha e encerramento |

---

# Parte A — Pipeline x Workflow

## 7. O que é um pipeline?

Pipeline trabalha diretamente com dados:

```text
CSV
 ↓
Transform
 ↓
Transform
 ↓
Banco
```

Pergunta central:

```text
Como os dados serão processados?
```

---

## 8. O que é um workflow?

Workflow trabalha com ações:

```text
Verificar arquivo
      ↓
Executar SQL
      ↓
Executar pipeline
      ↓
Validar resultado
```

Pergunta central:

```text
Quando e sob quais condições os processos serão executados?
```

---

## 9. Workflow hops

Tipos:

```text
Success
✓
```

Segue apenas quando a action anterior termina com sucesso.

```text
Failure
✗
```

Segue quando a action anterior falha.

```text
Unconditional
→
```

Continua independentemente do resultado anterior.

Exemplo:

```text
Verificar arquivo
       │
       ├── ✓ → Executar pipeline
       │
       └── ✗ → Abort workflow
```

---

# Parte B — Parametrização

## 10. Problema do hardcode

Antes:

```text
${PROJECT_HOME}/datasets/producao_limpa_aula04.csv
```

Queremos:

```text
${ARQUIVO_PRODUCAO}
```

Assim:

```text
Execução A
ARQUIVO_PRODUCAO = producao_dia_01.csv
```

```text
Execução B
ARQUIVO_PRODUCAO = producao_dia_02.csv
```

O pipeline permanece o mesmo.

---

## 11. Parâmetro x variável

Conceitualmente:

```text
Parâmetro
→ entrada explícita de um processo
```

```text
Variável
→ configuração disponível em determinado escopo
```

---

# Parte C — Parametrizar o pipeline da Aula 04

## 12. Declarar parâmetros

Abra:

```text
aula04_etl_multiplas_fontes.hpl
```

Declare:

```text
ARQUIVO_PRODUCAO
```

Default:

```text
${PROJECT_HOME}/datasets/producao_limpa_aula04.csv
```

Descrição:

```text
Arquivo CSV de entrada da produção
```

Também:

```text
ARQUIVO_METAS
```

Default:

```text
${PROJECT_HOME}/datasets/metas_producao.xlsx
```

---

## 13. Alterar os inputs

No `Text File Input`:

Antes:

```text
${PROJECT_HOME}/datasets/producao_limpa_aula04.csv
```

Depois:

```text
${ARQUIVO_PRODUCAO}
```

No `Microsoft Excel Input`:

```text
${ARQUIVO_METAS}
```

Teste o pipeline novamente.

---

# Parte D — Criar o workflow

## 14. Novo workflow

Crie:

```text
workflows/aula06_orquestracao_etl.hwf
```

Adicione:

```text
Start
```

Depois:

```text
Checks if files exist
```

---

# Parte E — Parâmetros do workflow

## 15. Declarar parâmetros

No workflow:

```text
ARQUIVO_PRODUCAO
```

Default:

```text
${PROJECT_HOME}/datasets/producao_limpa_aula04.csv
```

```text
ARQUIVO_METAS
```

Default:

```text
${PROJECT_HOME}/datasets/metas_producao.xlsx
```

```text
TOTAL_ESPERADO
```

Default:

```text
964
```

Na prática da Aula 04:

```text
1000 entradas
-
16 produtos sem cadastro
-
20 combinações sem meta
=
964 registros válidos
```

---

# Parte F — Verificar arquivos

## 16. Checks if files exist

Nome:

```text
Verificar arquivos de entrada
```

Arquivos:

```text
${ARQUIVO_PRODUCAO}
${ARQUIVO_METAS}
```

Fluxo:

```text
Start
  ↓
Verificar arquivos
```

Crie:

```text
SUCCESS → Preparar execução
FAILURE → Abort workflow
```

---

# Parte G — Abort Workflow

## 17. Caminho de falha

Adicione:

```text
Abort workflow
```

Nome:

```text
Falha na execução
```

Mensagem:

```text
A execução do ETL foi interrompida. Verifique os logs.
```

---

# Parte H — Preparar o banco

## 18. Action SQL

Adicione:

```text
SQL
```

Nome:

```text
Preparar tabelas
```

Conexão:

```text
PostgreSQL_Aula04
```

SQL:

```sql
TRUNCATE TABLE resumo_producao_consolidado RESTART IDENTITY;
TRUNCATE TABLE producao_consolidada RESTART IDENTITY;
```

### Observação

Esse `TRUNCATE` é adequado apenas ao laboratório de carga completa.

Em um cenário real, avaliar:

```text
carga incremental
UPSERT
staging
transação
swap de tabelas
```

---

# Parte I — Executar o ETL

## 19. Pipeline Action

Adicione:

```text
Pipeline
```

Nome:

```text
Executar ETL de produção
```

Pipeline:

```text
${PROJECT_HOME}/pipelines/aula04_etl_multiplas_fontes.hpl
```

Run configuration:

```text
Local
```

---

## 20. Passar parâmetros

Na aba:

```text
Parameters
```

Habilite:

```text
Pass parameter values to sub pipeline
```

Queremos:

```text
WORKFLOW
ARQUIVO_PRODUCAO
ARQUIVO_METAS
      ↓
PIPELINE
ARQUIVO_PRODUCAO
ARQUIVO_METAS
```

---

## 21. Fluxo parcial

```text
Start
  ↓
Verificar arquivos
  ↓ ✓
Preparar tabelas
  ↓ ✓
Executar ETL
```

Cada etapa também deve possuir um hop de falha para:

```text
Falha na execução
```

---

# Parte J — Validar a carga

## 22. Criar pipeline de validação

Crie:

```text
pipelines/aula06_validar_carga.hpl
```

Transform inicial:

```text
Table Input
```

SQL:

```sql
SELECT
    COUNT(*) AS total_carregado
FROM producao_consolidada;
```

Depois:

```text
Table Input
        ↓
Copy rows to result
```

Resultado esperado:

```text
total_carregado = 964
```

---

# Parte K — Executar validação no workflow

## 23. Segundo Pipeline Action

Adicione:

```text
Validar carga
```

Pipeline:

```text
${PROJECT_HOME}/pipelines/aula06_validar_carga.hpl
```

Fluxo:

```text
Executar ETL
      ↓
Validar carga
```

---

# Parte L — Simple Evaluation

## 24. Conferir a quantidade

Adicione:

```text
Simple evaluation
```

Nome:

```text
Quantidade está correta?
```

Source:

```text
Field from previous result
```

Field:

```text
total_carregado
```

Tipo:

```text
Integer
```

Condição:

```text
If value equal to
```

Valor:

```text
${TOTAL_ESPERADO}
```

---

# Parte M — Finalizar

## 25. Success

Adicione:

```text
Success
```

Nome:

```text
ETL concluído
```

Fluxo:

```text
Quantidade correta?
        │
        ├── ✓ → ETL concluído
        │
        └── ✗ → Falha na execução
```

---

## 26. Workflow completo

```text
                         START
                           ↓
                 Verificar arquivos
                  ↙              ↘
              FALHA             SUCESSO
                ↓                  ↓
              ABORT        Preparar tabelas
                                  ↙  ↘
                              FALHA  SUCESSO
                                ↓       ↓
                              ABORT  Executar ETL
                                       ↙  ↘
                                   FALHA  SUCESSO
                                     ↓       ↓
                                   ABORT   Validar carga
                                              ↓
                                     Quantidade correta?
                                       ↙            ↘
                                     NÃO            SIM
                                      ↓              ↓
                                    ABORT          SUCCESS
```

---

# Parte N — Primeiro teste

## 27. Executar normalmente

Parâmetros:

```text
ARQUIVO_PRODUCAO =
${PROJECT_HOME}/datasets/producao_limpa_aula04.csv
```

```text
ARQUIVO_METAS =
${PROJECT_HOME}/datasets/metas_producao.xlsx
```

```text
TOTAL_ESPERADO = 964
```

Resultado esperado:

```text
START
 ↓
arquivos OK
 ↓
tabelas preparadas
 ↓
pipeline OK
 ↓
964 registros
 ↓
SUCCESS
```

---

# Parte O — Testar falhas

## 28. Teste 1 — Arquivo inexistente

Altere:

```text
ARQUIVO_PRODUCAO =
${PROJECT_HOME}/datasets/arquivo_inexistente.csv
```

Resultado:

```text
Verificar arquivos
       ↓
     FAILURE
       ↓
      ABORT
```

---

## 29. Teste 2 — Quantidade incorreta

Execute com:

```text
TOTAL_ESPERADO = 999
```

Resultado:

```text
ETL executa
   ↓
total_carregado = 964
   ↓
964 != 999
   ↓
ABORT
```

Mensagem:

```text
execução técnica com sucesso
≠
resultado funcional correto
```

---

# Parte P — Logging

## 30. Por que logs?

Sem logs:

```text
Falhou.
```

Com logs:

```text
Qual workflow?
Qual action?
Qual pipeline?
Quando?
Quanto tempo?
Qual erro?
```

---

## 31. Níveis de logging

Para a aula:

```text
BASIC
→ execução normal
```

```text
DETAILED
→ troubleshooting
```

```text
DEBUG
→ investigação aprofundada
```

```text
ROWLEVEL
→ cuidado com grande volume de logs
```

---

## 32. Log próprio do pipeline

Abra:

```text
Executar ETL de produção
```

Aba:

```text
Logging
```

Configure:

```text
Specify logfile: ✓
```

Nome:

```text
${PROJECT_HOME}/logs/aula06_etl
```

Extension:

```text
log
```

Marque:

```text
Create parent folder
Include date in filename
Include time in filename
```

Resultado:

```text
logs/
└── aula06_etl_20260819_113500.log
```

---

# Parte Q — Tratamento de erros

## 33. Dois níveis de erro

### Erro de registro

```text
PIPELINE
↓
data inválida
número inválido
registro malformado
```

Pode ser tratado com:

```text
Transform error handling
```

### Erro de processo

```text
WORKFLOW
↓
arquivo não existe
pipeline falhou
banco indisponível
quantidade incorreta
```

Pode ser tratado com:

```text
Failure hop
Abort workflow
```

---

## 34. Estratégia recomendada

```text
Registro ruim
→ error handling
→ arquivo/tabela de rejeitados
```

```text
Processo impossível de continuar
→ workflow failure
→ Abort workflow
```

> Nem todo erro precisa derrubar o processo, mas todo erro precisa ser tratado.

---

# Parte R — Automação com hop-run

## 35. Executar fora do Hop GUI

Windows:

```text
hop-run.bat
```

Linux/macOS:

```text
hop-run.sh
```

---

## 36. Execução básica

Exemplo no Windows:

```bat
hop-run.bat ^
  -j MeuProjeto ^
  -r local ^
  -f "${PROJECT_HOME}/workflows/aula06_orquestracao_etl.hwf"
```

---

## 37. Passar parâmetros

```bat
hop-run.bat ^
  -j MeuProjeto ^
  -r local ^
  -f "${PROJECT_HOME}/workflows/aula06_orquestracao_etl.hwf" ^
  -p ARQUIVO_PRODUCAO="${PROJECT_HOME}/datasets/producao_limpa_aula04.csv",TOTAL_ESPERADO=964
```

---

## 38. Gerar log

```bat
hop-run.bat ^
  -j MeuProjeto ^
  -r local ^
  -f "${PROJECT_HOME}/workflows/aula06_orquestracao_etl.hwf" ^
  -l BASIC ^
  -lf "C:\hop-logs\aula06.log"
```

---

## 39. Código de saída

Conceito:

```text
Agendador
   ↓
hop-run
   ↓
exit code
   ↓
0 → OK
1 → erro
```

Isso permite integração com:

```text
Task Scheduler
cron
CI/CD
orquestradores
scripts BAT/PowerShell
```

---

# Parte S — Relação com o dashboard

## 40. Fluxo operacional

```text
            ARQUIVOS
               ↓
            WORKFLOW
               ↓
             ETL
               ↓
          PostgreSQL
               ↓
            Metabase
               ↓
           Dashboard
```

A Aula 05 criou a camada de consumo.

A Aula 06 cria a camada operacional que mantém os dados atualizados.

---

# Parte T — Desafio

## 41. Criar uma proteção adicional

Escolha uma alternativa.

### Opção A — Table Exists

Antes do ETL, verificar se:

```text
produto
```

existe no PostgreSQL.

Fluxo:

```text
Table Exists
   ↙      ↘
FAIL     SUCCESS
 ↓          ↓
Abort     ETL
```

### Opção B — Wait for file

Substitua a verificação imediata por:

```text
Wait for file
```

Exemplo:

```text
timeout = 60 segundos
check cycle = 5 segundos
```

### Opção C — Variável de ambiente

Crie:

```text
AMBIENTE
```

Valores:

```text
DEV
HOMOLOG
PROD
```

Discuta como ambientes diferentes podem utilizar:

```text
bancos diferentes
diretórios diferentes
credenciais diferentes
```

---

# 42. Evidências para entrega

Entregar:

```text
workflows/aula06_orquestracao_etl.hwf
pipelines/aula06_validar_carga.hpl
```

E capturas de:

- parâmetros do workflow;
- parâmetros no pipeline;
- `Checks if files exist`;
- action `SQL`;
- action `Pipeline`;
- parâmetros sendo repassados;
- caminho de sucesso;
- caminho de falha;
- pipeline de validação;
- `Simple evaluation`;
- execução bem-sucedida;
- execução com arquivo inexistente;
- execução com `TOTAL_ESPERADO` incorreto;
- arquivo de log;
- execução via `hop-run`.

---

# 43. Checklist

- [ ] Pipeline da Aula 04 parametrizado
- [ ] `ARQUIVO_PRODUCAO` declarado
- [ ] `ARQUIVO_METAS` declarado
- [ ] Workflow criado
- [ ] parâmetros do workflow definidos
- [ ] arquivos verificados
- [ ] caminho de falha configurado
- [ ] SQL de preparação configurado
- [ ] pipeline chamado pelo workflow
- [ ] parâmetros enviados ao pipeline
- [ ] pipeline de validação criado
- [ ] quantidade retornada ao workflow
- [ ] validação quantitativa configurada
- [ ] action `Success` configurada
- [ ] action `Abort workflow` configurada
- [ ] logging configurado
- [ ] teste de sucesso executado
- [ ] teste de arquivo inexistente executado
- [ ] teste de quantidade incorreta executado
- [ ] workflow executado pelo `hop-run`

---

# 44. Perguntas de revisão

1. Qual é a diferença entre pipeline e workflow?
2. O que diferencia um hop de sucesso de um hop de falha?
3. Por que parametrizar caminhos?
4. Qual é a diferença entre parâmetro e variável?
5. Como um workflow passa parâmetros para um pipeline?
6. Por que verificar o arquivo antes do ETL?
7. Por que “pipeline sem erro” não garante carga correta?
8. Para que serve `Copy rows to result`?
9. Qual é o papel do `Abort workflow`?
10. Quando utilizar `BASIC`, `DETAILED` ou `DEBUG`?
11. Qual é a função do `hop-run`?
12. Qual a diferença entre tratamento de erro de registro e erro de processo?

---

# 45. Resultado conceitual

No início:

```text
Arquivo
 ↓
Pipeline
 ↓
Banco
```

Agora:

```text
                   CONFIGURAÇÃO
                        ↓
                      PARÂMETROS
                        ↓
ENTRADAS → WORKFLOW → PIPELINES
              │          ↓
              │      PostgreSQL
              │          ↓
              │       Metabase
              │
              ├→ validações
              ├→ logs
              └→ tratamento de falhas
```

Evolução:

```text
ETL que funciona
      ↓
ETL controlado
      ↓
ETL automatizável
      ↓
ETL observável
```

---

# 46. Gancho para a Aula 07

Na Aula 07, o foco será o projeto integrador final.

Os grupos deverão combinar:

```text
Integração de fontes
+
Limpeza
+
Banco
+
Regras de negócio
+
KPIs
+
Dashboard
+
Workflow
+
Logs
+
Tratamento de erros
```

Resultado esperado:

```text
FONTES
  ↓
ETL
  ↓
BANCO
  ↓
DASHBOARD

   +

ORQUESTRAÇÃO
VALIDAÇÃO
LOGGING
```

A proposta é encerrar o módulo com uma solução próxima de um processo real de engenharia e integração de dados.
