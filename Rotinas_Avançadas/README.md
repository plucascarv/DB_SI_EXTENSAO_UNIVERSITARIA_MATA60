# Sistema de Informação para Gestão de Atividades de Extensão - Rotinas Avançadas

Esta porção do repositório contém os scripts SQL referentes à implementação da camada de dados avançada (Etapa 2) do projeto da disciplina **MATA60 - Banco de Dados**. O foco é a implementação de rotinas avançadas na lógica de negócio no servidor utilizando PostgreSQL.

## Estrutura do Repositório

Os scripts estão organizados dentro da pasta `rotinas_avancadas`, segmentados por artefato funcional. Abaixo está a descrição do conteúdo de cada diretório:

### `rotinas_avancadas/`

#### 1. `tela_1/` (Cadastro e Performance)
Scripts referentes à tela de cadastro de atividades.
* **`view_tela_1.sql`**: Criação da Materialized View `mv_performance_areas` para análise prévia de ociosidade e performance por área.
* **`procedure_tela_1.sql`**: Procedure `sp_cadastrar_atividade_parceria` que gerencia a inserção segura de atividades e parceiros, com validação e sanitização de dados.

#### 2. `tela_2/` (Validação, Auditoria e Transações)
Scripts referentes à tela de validação de participantes e emissão de certificados.
* **`ddl_evolution_tela_2.sql`**: **(Executar Primeiro)** Altera o esquema do banco, criando a tabela de log (`tb_log_validacao`) e adicionando colunas de auditoria.
* **`view_tela_2.sql`**: Criação da Materialized View `mv_pendencias_validacao` para listar alunos aguardando certificação.
* **`procedure_tela_2.sql`**: Procedure `sp_validar_e_registrar` que utiliza controle transacional (`COMMIT`) para validar participação e gerar log atomicamente.
* **`transacao_tela_2.sql`**: Script de manutenção para remoção segura de registros não certificados (`DELETE`).

#### 3. `dashboard_1/` (Estratégico - Diretoria)
* **`dashboard1.sql`**: Contém as consultas analíticas complexas e a definição das Materialized Views para indicadores macro (Desempenho Mensal, Gênero, Parceiros, Carga Horária) e suas respectivas procedures de atualização (`sp_refresh_...`).

#### 4. `dashboard_2/` (Operacional - Gestão Tática)
* **`dashboard2.sql`**: Contém as Materialized Views para análise histórica detalhada (Evolução Anual, Taxa de Certificação, Impacto Institucional) e a procedure orquestradora `sp_refresh_dashboard2`.

---

## Guia de Execução (Passo a Passo)

Para reproduzir o ambiente sem erros de dependência, siga estritamente a ordem abaixo no seu cliente SQL:

### Passo 0: Pré-requisitos
Certifique-se de que as tabelas base (`TB_PARTICIPANTE`, `TB_ATIVIDADE`, `RL_PARTICIPA`, `TB_PARCEIRO`) já foram criadas e povoadas (scripts da Etapa 1).

### Passo 1: Configurar Tela 1 (Cadastro)
1. Execute `rotinas_avancadas/tela_1/view_tela_1.sql`.
2. Execute `rotinas_avancadas/tela_1/procedure_tela_1.sql`.

### Passo 2: Configurar Tela 2 (Validação)
**Atenção:** A ordem aqui é crítica.
1. **Obrigatório:** Execute `rotinas_avancadas/tela_2/ddl_evolution_tela_2.sql` primeiro para criar as tabelas de log.
2. Execute `rotinas_avancadas/tela_2/view_tela_2.sql`.
3. Execute `rotinas_avancadas/tela_2/procedure_tela_2.sql`.
4. (Opcional) Utilize `transacao_tela_2.sql` apenas quando precisar limpar dados de teste.

### Passo 3: Configurar Dashboards
1. Execute `rotinas_avancadas/dashboard_1/dashboard1.sql`.
2. Execute `rotinas_avancadas/dashboard_2/dashboard2.sql`.

---

## Como Testar as Funcionalidades

### 1. Teste de Cadastro (Procedure)
```sql
CALL sp_cadastrar_atividade_parceria(
    100, '2025-12-01', '09:00', 'Lab 3', 'W', 
    'Tecnologia', 'Intro ao SQL', 4, 'Curso Básico', 
    NULL, NULL, NULL, NULL, NULL
);

```

### 2. Teste de Validação (Transação)

```sql
-- Validar participação do Aluno X na Atividade Y
CALL sp_validar_e_registrar(1, 1, 'Aluno participativo.');

-- Verificar Log
SELECT * FROM tb_log_validacao;

```

### 3. Teste do Dashboard Estratégico (Dashboard 1)

```sql
-- Executa a rotina de atualização (Refresh) dos indicadores mensais
CALL sp_refresh_desempenho_mensal();

-- Consulta a visão materializada para ver os KPIs (Taxa de Certificação, etc.)
SELECT * FROM mv_dashboard1_desempenho_mensal;

-- Consulta o impacto das parcerias (Categorias vs. Participantes Afetados)
SELECT * FROM mv_dashboard1_impacto_parceiros;

```

### 4. Teste do Dashboard Operacional (Dashboard 2)

```sql
-- Executa a rotina orquestradora que atualiza TODAS as views operacionais
CALL sp_refresh_dashboard2();

-- Consulta a evolução anual de participações
SELECT * FROM mv_dashboard2_participacao_anual;

```