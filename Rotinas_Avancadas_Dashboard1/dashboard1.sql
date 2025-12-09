------------------ Desempenho mensal
----------------- Objetivo: Analisar, de forma estratégica, o comportamento mensal dos eventos da instituição, exibindo o número total de participações e a quantidade de certificados emitidos.
----------------- A consulta combina TB_ATIVIDADE, RL_PARTICIPA e TB_PARTICIPANTE, agregando os dados por mês/ano. Utiliza JOIN, GROUP BY, COUNT e funções de janela para calcular o total do mês e o percentual de certificados. Permite identificar os meses mais movimentados, sazonalidades e períodos com maior emissão de certificados.
SELECT
    date_trunc('month', a.dt_atividade) AS mes,
    COUNT(r.id_participante) AS total_participacoes,
    COUNT(*) FILTER (WHERE r.is_certificado = 'S') AS total_certificados,
    ROUND(
        (COUNT(*) FILTER (WHERE r.is_certificado = 'S')::decimal /
         NULLIF(COUNT(r.id_participante), 0)) * 100, 2
    ) AS taxa_certificacao_percent
FROM tb_atividade a
JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY date_trunc('month', a.dt_atividade)
ORDER BY mes;
--------------------------- Ranking de Engajamento por Área de Estudo
----------------------------Objetivo: Esta consulta tem como objetivo analisar o interesse dos participantes nas áreas de estudo, segmentando pela variável gênero (M, F, O). Ela fornece uma visão clara sobre quais áreas atraem mais participantes femininos, masculinos ou de gênero diverso, possibilitando comparações diretas entre perfis demográficos.
SELECT
    a.nm_area_estudo AS area_estudo,
    SUM(CASE WHEN p.tp_genero = 'F' THEN 1 ELSE 0 END) AS total_feminino,
    SUM(CASE WHEN p.tp_genero = 'M' THEN 1 ELSE 0 END) AS total_masculino,
    SUM(CASE WHEN p.tp_genero = 'O' THEN 1 ELSE 0 END) AS total_outros
FROM tb_participante p
JOIN rl_participa r ON r.id_participante = p.id_participante
JOIN tb_atividade a ON a.id_atividade = r.id_atividade
GROUP BY a.nm_area_estudo
ORDER BY a.nm_area_estudo;
--------------------------Impacto dos Parceiros nos Eventos
-------------------------- Objetivo: Mensurar como os parceiros contribuem para o volume e a importância das atividades realizadas.
--------------------------Integra TB_PARCEIRO, TB_ATIVIDADE e RL_PARTICIPA, permitindo relacionar o parceiro às atividades e ao número de participantes. Ajuda a identificar quais parceiros agregam mais valor e quais parcerias geram mais participação e resultados relevantes.
SELECT
    pa.tp_categoria,
    COUNT(DISTINCT pa.id_parceiro) AS total_parceiros,
    COUNT(DISTINCT pa.id_atividade) AS atividades_apoiadas,
    COUNT(r.id_participante) AS participantes_afetados
FROM tb_parceiro pa
JOIN tb_atividade a ON a.id_atividade = pa.id_atividade
LEFT JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY pa.tp_categoria
ORDER BY atividades_apoiadas DESC;

----------------------Evolução Mensal da Carga Horária Consumida e Participação
------------------- Objetivo :Acompanhar como evoluem, mês a mês a carga horária total consumida pelas atividades, a quantidade média de horas por atividade, o total de presenças registradas.Isso permite analisar simultaneamente a oferta (horas disponibilizadas) e a demanda (participação dos participantes)
-------------------A consulta faz um agrupamento mensal com três cálculos: carga_total_consumida Soma de todas as cargas horárias das atividades daquele mês ( Mede o tamanho da oferta mensal de atividades). media_carga_por_atividade É a média da carga horária das atividades daquele mês(indica se as atividades daquele mês foram mais longas ou mais curtas). Total_presencas Conta quantas participações ocorreram naquele mês, representa o nível de engajamento do público.
SELECT
    date_trunc('month', a.dt_atividade) AS mes,
    SUM(a.carga_horaria) AS carga_total_consumida,
    AVG(a.carga_horaria) AS media_carga_por_atividade,
    COUNT(r.id_participante) AS total_presencas
FROM tb_atividade a
JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY date_trunc('month', a.dt_atividade)
ORDER BY mes;

--------------------------

CREATE MATERIALIZED VIEW mv_dashboard1_desempenho_mensal AS
SELECT
    date_trunc('month', a.dt_atividade) AS mes,
    COUNT(r.id_participante) AS total_participacoes,
    COUNT(*) FILTER (WHERE r.is_certificado = 'S') AS total_certificados,
    ROUND(
        (COUNT(*) FILTER (WHERE r.is_certificado = 'S')::decimal /
         NULLIF(COUNT(r.id_participante), 0)) * 100, 2
    ) AS taxa_certificacao_percent
FROM tb_atividade a
JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY date_trunc('month', a.dt_atividade)
ORDER BY mes;

---------------------------

CREATE MATERIALIZED VIEW mv_participacao_genero_area AS
SELECT
    a.nm_area_estudo AS area_estudo,
    SUM(CASE WHEN p.tp_genero = 'F' THEN 1 ELSE 0 END) AS total_feminino,
    SUM(CASE WHEN p.tp_genero = 'M' THEN 1 ELSE 0 END) AS total_masculino,
    SUM(CASE WHEN p.tp_genero = 'O' THEN 1 ELSE 0 END) AS total_outros
FROM tb_participante p
JOIN rl_participa r ON r.id_participante = p.id_participante
JOIN tb_atividade a ON a.id_atividade = r.id_atividade
GROUP BY a.nm_area_estudo
ORDER BY a.nm_area_estudo;
---------------------------------

CREATE MATERIALIZED VIEW mv_dashboard1_impacto_parceiros AS
SELECT
    pa.tp_categoria,
    COUNT(DISTINCT pa.id_parceiro) AS total_parceiros,
    COUNT(DISTINCT pa.id_atividade) AS atividades_apoiadas,
    COUNT(r.id_participante) AS participantes_afetados
FROM tb_parceiro pa
JOIN tb_atividade a ON a.id_atividade = pa.id_atividade
LEFT JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY pa.tp_categoria
ORDER BY atividades_apoiadas DESC;

------------------------------------

CREATE MATERIALIZED VIEW mv_dashboard1_carga_horaria_historica AS
SELECT
    date_trunc('month', a.dt_atividade) AS mes,
    SUM(a.carga_horaria) AS carga_total_consumida,
    AVG(a.carga_horaria) AS media_carga_por_atividade,
    COUNT(r.id_participante) AS total_presencas
FROM tb_atividade a
JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY date_trunc('month', a.dt_atividade)
ORDER BY mes;

---------------------------
--atualizacao

-- Desempenho mensal
CREATE OR REPLACE PROCEDURE sp_refresh_desempenho_mensal()
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW mv_dashboard1_desempenho_mensal;
END;
$$;

--Ranking de Engajamento por Área de Estudo
CREATE OR REPLACE PROCEDURE sp_refresh_participacao_genero_area()
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW mv_participacao_genero_area;
END;
$$;

--Impacto dos Parceiros nos Eventos
CREATE OR REPLACE PROCEDURE sp_refresh_impacto_parceiros()
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW mv_dashboard1_impacto_parceiros;
END;
$$;

-- Evolução Mensal da Carga Horária Consumida e Participação
CREATE OR REPLACE PROCEDURE sp_refresh_carga_horaria_historica()
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW mv_dashboard1_carga_horaria_historica;
END;
$$;
