# Banco de Dados para Proposta de Sistema de Informação para Extensão Universitária

Este repositório contém os scripts SQL para a criação, povoamento, querrying, indexação e teste de performance de um banco de dados para gerenciamento de atividades de extensão. Este projeto foi desenvolvido como parte da avaliação da matéria MATA60 - Banco de Dados na Universidade Federal da Bahia.

O objetivo principal deste projeto é construir o banco, povoá-lo, realizar consultas e comparar o desempenho destas sob diferentes estratégias de indexação.

## Pré-requisitos

Para reproduzir este projeto, você precisará de:

  * Um sistema de gerenciamento de banco de dados **PostgreSQL** instalado.
  * Uma ferramenta de administração de banco de dados, como **PgAdmin**.

## Como Reproduzir o Ambiente

Para configurar o banco de dados e executar os testes, siga esta ordem.

### 1\. Criação e Povoamento do Banco

1.  Crie um novo banco de dados no seu PostgreSQL:

    ```sql
    CREATE DATABASE gestao_atividades_extensao;
    ```

3.  Execute o script de criação das tabelas na Querry Tool:

      * `DDL_table_creation.sql`

**Importante:** Os scripts de inserção de dados (`INSERT`) devem ser executados **após** a criação das tabelas (`DDL`) e **na ordem correta** para respeitar as chaves estrangeiras.

4.  Execute os scripts de povoamento (INSERTs) **nesta ordem**:

      * `inserts_participantes.sql`
      * `inserts_atividades.sql`
      * `inserts_parceiros.sql`
      * `inserts_participa.sql` (Este deve ser o último, pois depende dos participantes e atividades).

Neste ponto, você tem o banco de dados no estado baseline.

### 2\. Executando os Testes de Performance

Para cada um dos planos abaixo, você deve:

1.  Aplicar o plano (executar o script de índice).
2.  Executar seu conjunto de consultas de teste (ex: `Q1`, `Q2`, etc.).
3.  Registrar os tempos de execução.
4.  **Limpar os índices** antes de testar o próximo plano.

#### Teste 1: Baseline

Execute suas consultas de teste diretamente após o povoamento (Passo 1.4). Os únicos índices existentes serão os criados automaticamente pelas `PRIMARY KEY` e `UNIQUE`.

#### Teste 2: Plano de Indexação 1

1.  Execute o script para criar os índices do Plano 1:
      * `plano_1.sql`
2.  Execute suas consultas de teste e registre os tempos.

#### Teste 3: Plano de Indexação 2

1.  **Limpe os índices do Plano 1.** Você pode fazer isso executando os comandos `DROP INDEX` relevantes (veja a seção "Limpando Índices" abaixo).
2.  Execute o script para criar os índices do Plano 2:
      * `plano_2.sql`
3.  Execute suas consultas de teste e registre os tempos.

-----

### Limpando Índices (Resetando os Testes)

Para trocar do Plano 1 para o Plano 2 (ou voltar ao Baseline), você deve "dropar" os índices criados.

**Para remover os índices do Plano 1:**

```sql
DROP INDEX IF EXISTS idx_participa_hash_id_ativ;
DROP INDEX IF EXISTS idx_participa_hash_id_part;
DROP INDEX IF EXISTS idx_participante_hash;
DROP INDEX IF EXISTS idx_atividade_hash;
DROP INDEX IF EXISTS idx_participante_tp_btree;
DROP INDEX IF EXISTS idx_atividade_data_btree;
```

**Para remover os índices do Plano 2:**

```sql
DROP INDEX IF EXISTS idx_participa_btree;
DROP INDEX IF EXISTS idx_parceiro_atividade_btree;
DROP INDEX IF EXISTS idx_participante_tp_btree;
DROP INDEX IF EXISTS idx_participa_certificado_btree;
```

## Descrição dos Arquivos

  * `DDL_table_creation.sql`: Define a estrutura de 4 tabelas (`TB_PARTICIPANTE`, `TB_ATIVIDADE`, `RL_PARTICIPA`, `TB_PARCEIRO`).
  * `inserts_participantes.sql`: Script de povoamento da tabela `TB_PARTICIPANTE`.
  * `inserts_atividades.sql`: Script de povoamento da tabela `TB_ATIVIDADE`.
  * `inserts_parceiros.sql`: Script de povoamento da tabela `TB_PARCEIRO`.
  * `inserts_participa.sql`: Script de povoamento da tabela de relacionamento `RL_PARTICIPA`.
  * `plano_1.sql`: Cria um conjunto de índices B-Tree e Hash para otimização.
  * `plano_2.sql`: Cria um conjunto alternativo de índices B-Tree para otimização.
