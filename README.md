# Banco de Dados para Proposta de Sistema de Informação para Extensão Universitária

Este repositório contém os scripts SQL para a criação, povoamentom, querrying e teste de performance de um banco de dados para gerenciamento de atividades de extensão. Este projeto foi desenvolvido como parte da avaliação da matéria MATA60 - Banco de Dados na Universidade Federal da Bahia.

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

      * [cite\_start]`DDL_table_creation.sql` [cite: 1]

**Importante:** Os scripts de inserção de dados (`INSERT`) devem ser executados **após** a criação das tabelas (`DDL`) e **na ordem correta** para respeitar as chaves estrangeiras.

4.  Execute os scripts de povoamento (INSERTs) **nesta ordem**:

      * [cite\_start]`inserts_participantes.sql` [cite: 2]
      * [cite\_start]`inserts_atividades.sql` [cite: 5]
      * [cite\_start]`inserts_parceiros.sql` [cite: 4]
      * [cite\_start]`inserts_participa.sql` [cite: 3] (Este deve ser o último, pois depende dos participantes e atividades).

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
      * [cite\_start]`plano_1.sql` [cite: 6]
2.  Execute suas consultas de teste e registre os tempos.

#### Teste 3: Plano de Indexação 2

1.  **Limpe os índices do Plano 1.** Você pode fazer isso executando os comandos `DROP INDEX` relevantes (veja a seção "Limpando Índices" abaixo).
2.  Execute o script para criar os índices do Plano 2:
      * [cite\_start]`plano_2.sql` [cite: 7]
3.  Execute suas consultas de teste e registre os tempos.

-----

### Limpando Índices (Resetando os Testes)

Para trocar do Plano 1 para o Plano 2 (ou voltar ao Baseline), você deve "dropar" os índices criados.

[cite\_start]**Para remover os índices do Plano 1:** [cite: 6]

```sql
DROP INDEX IF EXISTS idx_participa_hash_id_ativ;
DROP INDEX IF EXISTS idx_participa_hash_id_part;
DROP INDEX IF EXISTS idx_participante_hash;
DROP INDEX IF EXISTS idx_atividade_hash;
DROP INDEX IF EXISTS idx_participante_tp_btree;
DROP INDEX IF EXISTS idx_atividade_data_btree;
```

[cite\_start]**Para remover os índices do Plano 2:** [cite: 7]

```sql
DROP INDEX IF EXISTS idx_participa_btree;
DROP INDEX IF EXISTS idx_parceiro_atividade_btree;
DROP INDEX IF EXISTS idx_participante_tp_btree;
DROP INDEX IF EXISTS idx_participa_certificado_btree;
```

## Descrição dos Arquivos

  * [cite\_start]`DDL_table_creation.sql`: [cite: 1] Define a estrutura de 4 tabelas (`TB_PARTICIPANTE`, `TB_ATIVIDADE`, `RL_PARTICIPA`, `TB_PARCEIRO`).
  * [cite\_start]`inserts_participantes.sql`: [cite: 2] Script de povoamento da tabela `TB_PARTICIPANTE`.
  * [cite\_start]`inserts_atividades.sql`: [cite: 5] Script de povoamento da tabela `TB_ATIVIDADE`.
  * [cite\_start]`inserts_parceiros.sql`: [cite: 4] Script de povoamento da tabela `TB_PARCEIRO`.
  * [cite\_start]`inserts_participa.sql`: [cite: 3] Script de povoamento da tabela de relacionamento `RL_PARTICIPA`.
  * [cite\_start]`plano_1.sql`: [cite: 6] Cria um conjunto de índices B-Tree e Hash para otimização.
  * [cite\_start]`plano_2.sql`: [cite: 7] Cria um conjunto alternativo de índices B-Tree para otimização.