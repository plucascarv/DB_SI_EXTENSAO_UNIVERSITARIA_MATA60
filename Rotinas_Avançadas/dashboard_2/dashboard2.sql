-- Limpeza para reexecução
DROP MATERIALIZED VIEW IF EXISTS mv_dashboard2_participacao_anual;
DROP MATERIALIZED VIEW IF EXISTS mv_dashboard2_certificacao_anual;
DROP MATERIALIZED VIEW IF EXISTS mv_dashboard2_area_estudo_historico;
DROP MATERIALIZED VIEW IF EXISTS mv_dashboard2_impacto_institucional;
DROP MATERIALIZED VIEW IF EXISTS mv_dashboard2_tipo_atividade;
DROP MATERIALIZED VIEW IF EXISTS mv_dashboard2_media_participacao;

-- Materialized Views

-- Evolução anual da participação
CREATE MATERIALIZED VIEW mv_dashboard2_participacao_anual AS
SELECT
    date_trunc('year', a.dt_atividade) AS ano,
    COUNT(r.id_participante) AS total_participacoes,
    COUNT(DISTINCT r.id_participante) AS participantes_unicos
FROM tb_atividade a
JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY date_trunc('year', a.dt_atividade)
ORDER BY ano;

-- Taxa anual de certificação
CREATE MATERIALIZED VIEW mv_dashboard2_certificacao_anual AS
SELECT
    date_trunc('year', a.dt_atividade) AS ano,
    COUNT(r.id_participante) AS total_participacoes,
    COUNT(*) FILTER (WHERE r.is_certificado = 'S') AS total_certificados,
    ROUND(
        (COUNT(*) FILTER (WHERE r.is_certificado = 'S')::decimal /
         NULLIF(COUNT(r.id_participante), 0)) * 100, 2
    ) AS taxa_certificacao_percent
FROM tb_atividade a
JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY date_trunc('year', a.dt_atividade)
ORDER BY ano;

-- Participação por área de estudo (histórico)
CREATE MATERIALIZED VIEW mv_dashboard2_area_estudo_historico AS
SELECT
    date_trunc('year', a.dt_atividade) AS ano,
    a.nm_area_estudo,
    COUNT(r.id_participante) AS total_participacoes
FROM tb_atividade a
JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY date_trunc('year', a.dt_atividade), a.nm_area_estudo
ORDER BY ano, total_participacoes DESC;

-- Impacto institucional (CORRIGIDA)
-- Removido o JOIN com tb_instituicao inexistente e ajustado para usar NM_INSTITUICAO
CREATE MATERIALIZED VIEW mv_dashboard2_impacto_institucional AS
SELECT
    p.nm_instituicao,
    COUNT(r.id_participante) AS total_participacoes,
    COUNT(*) FILTER (WHERE r.is_certificado = 'S') AS total_certificados,
    ROUND(
        (COUNT(*) FILTER (WHERE r.is_certificado = 'S')::decimal /
         NULLIF(COUNT(r.id_participante), 0)) * 100, 2
    ) AS taxa_certificacao_percent
FROM tb_participante p
JOIN rl_participa r ON r.id_participante = p.id_participante
WHERE p.nm_instituicao IS NOT NULL -- Filtra nulos para não sujar o gráfico
GROUP BY p.nm_instituicao
ORDER BY total_participacoes DESC;

-- Distribuição por tipo de atividade (CORRIGIDA)
-- Ajustado nome da coluna para TP_ATIVIDADE
CREATE MATERIALIZED VIEW mv_dashboard2_tipo_atividade AS
SELECT
    date_trunc('year', a.dt_atividade) AS ano,
    a.tp_atividade, -- Corrigido de tipo_atividade para tp_atividade
    COUNT(r.id_participante) AS total_participacoes
FROM tb_atividade a
JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY date_trunc('year', a.dt_atividade), a.tp_atividade
ORDER BY ano, total_participacoes DESC;

-- Média histórica de participação por atividade
CREATE MATERIALIZED VIEW mv_dashboard2_media_participacao AS
SELECT
    a.nm_atividade,
    COUNT(r.id_participante) AS total_participacoes,
    ROUND(
        COUNT(r.id_participante)::decimal /
        NULLIF(COUNT(DISTINCT a.id_atividade), 0), 2
    ) AS media_participacao
FROM tb_atividade a
JOIN rl_participa r ON r.id_atividade = a.id_atividade
GROUP BY a.nm_atividade
ORDER BY media_participacao DESC;

-- -------------------------
-- Procedures de refresh
-- -------------------------

CREATE OR REPLACE PROCEDURE sp_refresh_dashboard2()
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW mv_dashboard2_participacao_anual;
  REFRESH MATERIALIZED VIEW mv_dashboard2_certificacao_anual;
  REFRESH MATERIALIZED VIEW mv_dashboard2_area_estudo_historico;
  REFRESH MATERIALIZED VIEW mv_dashboard2_impacto_institucional;
  REFRESH MATERIALIZED VIEW mv_dashboard2_tipo_atividade;
  REFRESH MATERIALIZED VIEW mv_dashboard2_media_participacao;
END;
$$;