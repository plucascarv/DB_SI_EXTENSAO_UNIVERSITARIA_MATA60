-- Querry 1
-- Requisito 1.6: A query visa trazer um relatório de Impacto e Participação por Atividade
SELECT 
    a.ID_ATIVIDADE,
    a.NM_ATIVIDADE,
    a.DT_ATIVIDADE,
    a.TP_ATIVIDADE,
    a.NM_AREA_ESTUDO,
    a.CARGA_HORARIA,
    COUNT(rl.ID_PARTICIPANTE) as total_participantes,
    COUNT(CASE WHEN p.TP_PARTICIPACAO = 'I' THEN 1 END) as total_instrutores,
    COUNT(CASE WHEN p.TP_PARTICIPACAO = 'M' THEN 1 END) as total_monitores,
    COUNT(CASE WHEN p.TP_PARTICIPACAO = 'O' THEN 1 END) as total_ouvintes,
    COUNT(par.ID_PARCEIRO) as total_parceiros,
    COUNT(CASE WHEN rl.IS_CERTIFICADO = 'S' THEN 1 END) as certificados_emitidos,
    ROUND((COUNT(CASE WHEN rl.IS_CERTIFICADO = 'S' THEN 1 END) * 100.0 / COUNT(rl.ID_PARTICIPANTE)), 2) as percentual_certificados,
    AVG(LENGTH(rl.DS_FEEDBACK)) as media_tamanho_feedback,
    RANK() OVER (ORDER BY COUNT(rl.ID_PARTICIPANTE) DESC) as ranking_participacao
FROM TB_ATIVIDADE a
LEFT JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE
LEFT JOIN TB_PARTICIPANTE p ON rl.ID_PARTICIPANTE = p.ID_PARTICIPANTE
LEFT JOIN TB_PARCEIRO par ON a.ID_ATIVIDADE = par.ID_ATIVIDADE
GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.TP_ATIVIDADE, a.NM_AREA_ESTUDO, a.CARGA_HORARIA
ORDER BY a.DT_ATIVIDADE DESC, total_participantes DESC;

-- Querry 2
-- Requisito 1.4: Gestão de Múltiplos Instrutores por Atividade
SELECT 
    a.ID_ATIVIDADE,
    a.NM_ATIVIDADE,
    a.DT_ATIVIDADE,
    a.DS_LOCAL,
    COUNT(CASE WHEN p.TP_PARTICIPACAO = 'I' THEN 1 END) as quantidade_instrutores,
    STRING_AGG(
        DISTINCT CONCAT_WS(' ', p.NM_PRIMEIRO, p.NM_MEIO, p.NM_ULTIMO), ', '
    ) FILTER (WHERE p.TP_PARTICIPACAO = 'I') as nomes_instrutores,
    COUNT(DISTINCT rl.ID_PARTICIPANTE) as total_envolvidos,
    a.CARGA_HORARIA,
    a.DS_ATIVIDADE,
    (SELECT AVG(instr_count) 
     FROM (SELECT COUNT(CASE WHEN p2.TP_PARTICIPACAO = 'I' THEN 1 END) as instr_count
           FROM TB_ATIVIDADE a2 
           JOIN RL_PARTICIPA rl2 ON a2.ID_ATIVIDADE = rl2.ID_ATIVIDADE
           JOIN TB_PARTICIPANTE p2 ON rl2.ID_PARTICIPANTE = p2.ID_PARTICIPANTE
           WHERE a2.TP_ATIVIDADE = a.TP_ATIVIDADE
           GROUP BY a2.ID_ATIVIDADE) as sub) as media_instrutores_tipo,
    RANK() OVER (ORDER BY COUNT(CASE WHEN p.TP_PARTICIPACAO = 'I' THEN 1 END) DESC) as ranking_instrutores
FROM TB_ATIVIDADE a
JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE
JOIN TB_PARTICIPANTE p ON rl.ID_PARTICIPANTE = p.ID_PARTICIPANTE
WHERE p.TP_PARTICIPACAO = 'I'
GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.DS_LOCAL, a.CARGA_HORARIA, a.DS_ATIVIDADE, a.TP_ATIVIDADE
HAVING COUNT(CASE WHEN p.TP_PARTICIPACAO = 'I' THEN 1 END) > 1
ORDER BY quantidade_instrutores DESC;

-- Querry 3
-- Requisito 1.5: Análise de Parcerias com Empresas e ONGs
SELECT 
    par.TP_CATEGORIA,
    par.NM_EMPRESA,
    COUNT(DISTINCT par.ID_ATIVIDADE) as total_atividades_apoiadas,
    STRING_AGG(DISTINCT a.NM_ATIVIDADE, '; ') as atividades_apoiadas,
    COUNT(DISTINCT rl.ID_PARTICIPANTE) as total_participantes_impactados,
    SUM(a.CARGA_HORARIA) as carga_horaria_total_apoiada,
    COUNT(DISTINCT a.NM_AREA_ESTUDO) as areas_estudo_envolvidas,
    CASE 
        WHEN par.TP_CATEGORIA = 'F' THEN 'Financeiro'
        WHEN par.TP_CATEGORIA = 'P' THEN 'Palestrante'
        WHEN par.TP_CATEGORIA = 'M' THEN 'Material'
        ELSE 'Outro'
    END as tipo_parceria,
    (SELECT COUNT(DISTINCT par2.NM_EMPRESA)
     FROM TB_PARCEIRO par2
     WHERE par2.TP_CATEGORIA = par.TP_CATEGORIA) as total_empresas_categoria,
    RANK() OVER (PARTITION BY par.TP_CATEGORIA ORDER BY COUNT(DISTINCT rl.ID_PARTICIPANTE) DESC) as ranking_impacto_categoria
FROM TB_PARCEIRO par
JOIN TB_ATIVIDADE a ON par.ID_ATIVIDADE = a.ID_ATIVIDADE
LEFT JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE
GROUP BY par.TP_CATEGORIA, par.NM_EMPRESA
ORDER BY total_atividades_apoiadas DESC, total_participantes_impactados DESC;

-- Querry 4
-- Requisito 1.7: Emissão Automática de Certificados
SELECT 
    p.ID_PARTICIPANTE,
    CONCAT_WS(' ', p.NM_PRIMEIRO, p.NM_MEIO, P.NM_ULTIMO) as nome_completo,
    p.CD_CPF_PARTICIPANTE,
    a.ID_ATIVIDADE,
    a.NM_ATIVIDADE,
    a.DT_ATIVIDADE,
    a.CARGA_HORARIA,
    a.NM_AREA_ESTUDO,
    p.TP_PARTICIPACAO,
    CASE 
        WHEN p.TP_PARTICIPACAO = 'I' THEN 'Instrutor'
        WHEN p.TP_PARTICIPACAO = 'M' THEN 'Monitor' 
        WHEN p.TP_PARTICIPACAO = 'O' THEN 'Ouvinte'
    END as funcao_atividade,
    rl.IS_CERTIFICADO as certificado_emitido,
    CASE 
        WHEN rl.IS_CERTIFICADO = 'N' THEN 'PENDENTE'
        ELSE 'EMITIDO'
    END as status_certificado,
    (SELECT COUNT(*) 
     FROM RL_PARTICIPA rl2 
     JOIN TB_ATIVIDADE a2 ON rl2.ID_ATIVIDADE = a2.ID_ATIVIDADE 
     WHERE rl2.ID_PARTICIPANTE = p.ID_PARTICIPANTE 
     AND a2.DT_ATIVIDADE <= CURRENT_DATE
     AND rl2.IS_CERTIFICADO = 'N') as total_pendentes_participante,
    RANK() OVER (PARTITION BY a.ID_ATIVIDADE ORDER BY p.TP_PARTICIPACAO DESC) as prioridade_emissao
FROM TB_PARTICIPANTE p
JOIN RL_PARTICIPA rl ON p.ID_PARTICIPANTE = rl.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON rl.ID_ATIVIDADE = a.ID_ATIVIDADE
WHERE a.DT_ATIVIDADE <= CURRENT_DATE
  AND rl.IS_CERTIFICADO = 'N'
ORDER BY a.DT_ATIVIDADE, p.NM_ULTIMO, p.NM_PRIMEIRO;

-- Querry 5
-- Requisito 1.3: Dashboard de Atividades - Status e Métricas
WITH status_atividade AS (
    SELECT 
        a.ID_ATIVIDADE,
        a.NM_ATIVIDADE,
        a.DT_ATIVIDADE,
        a.TP_ATIVIDADE,
        a.NM_AREA_ESTUDO,
        CASE 
            WHEN a.DT_ATIVIDADE > CURRENT_DATE THEN 'AGENDADA'
            WHEN a.DT_ATIVIDADE = CURRENT_DATE THEN 'EM ANDAMENTO'
            ELSE 'REALIZADA'
        END as status_atividade,
        COUNT(DISTINCT rl.ID_PARTICIPANTE) as total_participantes,
        COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) as instrutores,
        COUNT(DISTINCT par.ID_PARCEIRO) as parceiros,
        COUNT(DISTINCT CASE WHEN rl.IS_CERTIFICADO = 'S' THEN rl.ID_PARTICIPANTE END) as certificados_emitidos,
        (SELECT AVG(part_count) 
         FROM (SELECT COUNT(DISTINCT rl2.ID_PARTICIPANTE) as part_count
               FROM TB_ATIVIDADE a2 
               JOIN RL_PARTICIPA rl2 ON a2.ID_ATIVIDADE = rl2.ID_ATIVIDADE
               WHERE a2.TP_ATIVIDADE = a.TP_ATIVIDADE
               GROUP BY a2.ID_ATIVIDADE) as sub) as media_geral_tipo
    FROM TB_ATIVIDADE a
    LEFT JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE
    LEFT JOIN TB_PARTICIPANTE p ON rl.ID_PARTICIPANTE = p.ID_PARTICIPANTE
    LEFT JOIN TB_PARCEIRO par ON a.ID_ATIVIDADE = par.ID_ATIVIDADE
    GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.TP_ATIVIDADE, a.NM_AREA_ESTUDO
)
SELECT 
    status_atividade,
    TP_ATIVIDADE,
    COUNT(*) as quantidade_atividades,
    SUM(total_participantes) as total_participantes,
    AVG(total_participantes) as media_participantes,
    RANK() OVER (PARTITION BY status_atividade ORDER BY SUM(total_participantes) DESC) as ranking_participacao,
    SUM(instrutores) as total_instrutores,
    SUM(parceiros) as total_parceiros,
    SUM(certificados_emitidos) as total_certificados,
    AVG(media_geral_tipo) as media_geral_tipo_atividade
FROM status_atividade
GROUP BY status_atividade, TP_ATIVIDADE
ORDER BY 
    CASE status_atividade
        WHEN 'AGENDADA' THEN 1
        WHEN 'EM ANDAMENTO' THEN 2
        ELSE 3
    END, TP_ATIVIDADE;

-- Querry 6
-- Requisito 1.6: Análise de Feedback e Satisfação por Tipo de Atividade
SELECT 
    a.TP_ATIVIDADE,
    CASE 
        WHEN a.TP_ATIVIDADE = 'E' THEN 'Evento'
        WHEN a.TP_ATIVIDADE = 'P' THEN 'Palestra' 
        WHEN a.TP_ATIVIDADE = 'W' THEN 'Workshop'
        WHEN a.TP_ATIVIDADE = 'C' THEN 'Curso'
        ELSE 'Outros'
    END as descricao_tipo,
    a.NM_AREA_ESTUDO,
    COUNT(rl.ID_PARTICIPANTE) as total_participantes,
    COUNT(rl.DS_FEEDBACK) as feedbacks_recebidos,
    ROUND((COUNT(rl.DS_FEEDBACK) * 100.0 / COUNT(rl.ID_PARTICIPANTE)), 2) as taxa_resposta,
    (SELECT ROUND(AVG(feedback_rate), 2)
     FROM (SELECT 
               a2.NM_AREA_ESTUDO,
               (COUNT(rl2.DS_FEEDBACK) * 100.0 / COUNT(rl2.ID_PARTICIPANTE)) as feedback_rate
           FROM TB_ATIVIDADE a2
           JOIN RL_PARTICIPA rl2 ON a2.ID_ATIVIDADE = rl2.ID_ATIVIDADE
           GROUP BY a2.NM_AREA_ESTUDO) as sub
     WHERE sub.NM_AREA_ESTUDO = a.NM_AREA_ESTUDO) as taxa_media_area,
    AVG(LENGTH(rl.DS_FEEDBACK)) as media_tamanho_feedback,
    COUNT(CASE WHEN LENGTH(rl.DS_FEEDBACK) > 50 THEN 1 END) as feedbacks_detalhados,
    RANK() OVER (ORDER BY (COUNT(rl.DS_FEEDBACK) * 100.0 / COUNT(rl.ID_PARTICIPANTE)) DESC) as ranking_satisfacao
FROM TB_ATIVIDADE a
JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE
JOIN TB_PARTICIPANTE p ON rl.ID_PARTICIPANTE = p.ID_PARTICIPANTE
WHERE rl.DS_FEEDBACK IS NOT NULL
GROUP BY a.TP_ATIVIDADE, a.NM_AREA_ESTUDO
HAVING COUNT(rl.ID_PARTICIPANTE) >= 5
ORDER BY taxa_resposta DESC, total_participantes DESC;

-- Querry 7
-- Requisito 1.6: Relatório de Participação por Instituição e Área de Estudo
SELECT
    p.NM_INSTITUICAO,
    a.NM_AREA_ESTUDO,
    COUNT(DISTINCT p.ID_PARTICIPANTE) as total_participantes_unicos,
    COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades_participadas,
    SUM(a.CARGA_HORARIA) as carga_horaria_total,
    COUNT(DISTINCT p.ID_PARTICIPANTE) FILTER (WHERE p.TP_PARTICIPACAO = 'I') as instrutores,
    COUNT(DISTINCT p.ID_PARTICIPANTE) FILTER (WHERE p.TP_PARTICIPACAO = 'M') as monitores,
    COUNT(DISTINCT p.ID_PARTICIPANTE) FILTER (WHERE p.TP_PARTICIPACAO = 'O') as ouvintes,
    ROUND(CAST(COUNT(*) AS DECIMAL) / COUNT(DISTINCT p.ID_PARTICIPANTE), 2) as media_atividades_por_participante,
    (SELECT COUNT(DISTINCT p2.NM_INSTITUICAO)
     FROM TB_PARTICIPANTE p2
     JOIN RL_PARTICIPA rl2 ON p2.ID_PARTICIPANTE = rl2.ID_PARTICIPANTE
     JOIN TB_ATIVIDADE a2 ON rl2.ID_ATIVIDADE = a2.ID_ATIVIDADE
     WHERE a2.NM_AREA_ESTUDO = a.NM_AREA_ESTUDO
       AND p2.NM_INSTITUICAO IS NOT NULL) as total_instituicoes_area,
    RANK() OVER (PARTITION BY a.NM_AREA_ESTUDO ORDER BY COUNT(DISTINCT p.ID_PARTICIPANTE) DESC) as ranking_instituicao_area
FROM TB_PARTICIPANTE p
JOIN RL_PARTICIPA rl ON p.ID_PARTICIPANTE = rl.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON rl.ID_ATIVIDADE = a.ID_ATIVIDADE
WHERE p.NM_INSTITUICAO IS NOT NULL
GROUP BY p.NM_INSTITUICAO, a.NM_AREA_ESTUDO
HAVING COUNT(DISTINCT p.ID_PARTICIPANTE) >= 3
ORDER BY p.NM_INSTITUICAO, total_participantes_unicos DESC;

-- Querry 8
-- Requisito 1.1: Gestão de Cronograma e Alocação de Recursos
SELECT 
    a.ID_ATIVIDADE,
    a.NM_ATIVIDADE,
    a.DT_ATIVIDADE,
    a.HR_ATIVIDADE,
    a.DS_LOCAL,
    a.TP_ATIVIDADE,
    a.NM_AREA_ESTUDO,
    a.CARGA_HORARIA,
    COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) as instrutores_alocados,
    COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'M' THEN p.ID_PARTICIPANTE END) as monitores_alocados,
    COUNT(DISTINCT par.ID_PARCEIRO) as parceiros_envolvidos,
    COUNT(DISTINCT rl.ID_PARTICIPANTE) as participantes_confirmados,
    (SELECT ROUND(AVG(part_count), 2)
     FROM (SELECT COUNT(DISTINCT rl2.ID_PARTICIPANTE) as part_count
           FROM TB_ATIVIDADE a2 
           JOIN RL_PARTICIPA rl2 ON a2.ID_ATIVIDADE = rl2.ID_ATIVIDADE
           WHERE a2.TP_ATIVIDADE = a.TP_ATIVIDADE
             AND a2.DT_ATIVIDADE < CURRENT_DATE
           GROUP BY a2.ID_ATIVIDADE) as sub) as media_historica_participantes,
    RANK() OVER (ORDER BY COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) DESC) as ranking_instrutores,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) = 0 
        THEN 'SEM INSTRUTOR'
        WHEN COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) = 1 
        THEN 'INSTRUTOR ÚNICO'
        ELSE 'MÚLTIPLOS INSTRUTORES'
    END as status_alocacao_instrutores
FROM TB_ATIVIDADE a
LEFT JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE
LEFT JOIN TB_PARTICIPANTE p ON rl.ID_PARTICIPANTE = p.ID_PARTICIPANTE
LEFT JOIN TB_PARCEIRO par ON a.ID_ATIVIDADE = par.ID_ATIVIDADE
WHERE a.DT_ATIVIDADE >= CURRENT_DATE
GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.HR_ATIVIDADE, a.DS_LOCAL, a.TP_ATIVIDADE, a.NM_AREA_ESTUDO, a.CARGA_HORARIA
ORDER BY a.DT_ATIVIDADE, a.HR_ATIVIDADE;

-- Querry 9
-- Requisito 1.5: Análise de Eficiência por Tipo de Parceria
SELECT 
    par.TP_CATEGORIA,
    CASE 
        WHEN par.TP_CATEGORIA = 'F' THEN 'Financeiro'
        WHEN par.TP_CATEGORIA = 'P' THEN 'Palestrante'
        WHEN par.TP_CATEGORIA = 'M' THEN 'Material'
        ELSE 'Outro'
    END as descricao_categoria,
    COUNT(DISTINCT par.ID_PARCEIRO) as total_parceiros,
    COUNT(DISTINCT par.ID_ATIVIDADE) as total_atividades_apoiadas,
    COUNT(DISTINCT rl.ID_PARTICIPANTE) as total_participantes_impactados,
    SUM(a.CARGA_HORARIA) as carga_horaria_total,
    ROUND(AVG(COUNT(DISTINCT rl.ID_PARTICIPANTE)) OVER (PARTITION BY par.TP_CATEGORIA), 2) as media_participantes_por_parceiro,
    (SELECT ROUND(AVG(part_count) * 1.1, 0)
     FROM (SELECT COUNT(DISTINCT rl2.ID_PARTICIPANTE) as part_count
           FROM TB_PARCEIRO par2
           JOIN TB_ATIVIDADE a2 ON par2.ID_ATIVIDADE = a2.ID_ATIVIDADE
           JOIN RL_PARTICIPA rl2 ON a2.ID_ATIVIDADE = rl2.ID_ATIVIDADE
           WHERE par2.TP_CATEGORIA = par.TP_CATEGORIA
           GROUP BY par2.ID_PARCEIRO) as sub) as participantes_ideais,
    RANK() OVER (ORDER BY COUNT(DISTINCT rl.ID_PARTICIPANTE) DESC) as ranking_impacto_geral,
    ROUND((COUNT(DISTINCT rl.ID_PARTICIPANTE) * 100.0 / SUM(COUNT(DISTINCT rl.ID_PARTICIPANTE)) OVER ()), 2) as percentual_impacto_total
FROM TB_PARCEIRO par
JOIN TB_ATIVIDADE a ON par.ID_ATIVIDADE = a.ID_ATIVIDADE
LEFT JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE
GROUP BY par.TP_CATEGORIA
ORDER BY total_participantes_impactados DESC;

-- Querry 10
-- Requisito 1.6 Relatório Consolidado para Diretoria
WITH metricas_consolidadas AS (
    SELECT 
        (SELECT COUNT(*) FROM TB_ATIVIDADE) as total_atividades,
        (SELECT COUNT(*) FROM TB_PARTICIPANTE) as total_participantes,
        (SELECT COUNT(*) FROM TB_PARCEIRO) as total_parceiros,
        (SELECT COUNT(*) FROM RL_PARTICIPA) as total_participacoes,
        (SELECT COUNT(*) FROM TB_ATIVIDADE WHERE TP_ATIVIDADE = 'E') as eventos,
        (SELECT COUNT(*) FROM TB_ATIVIDADE WHERE TP_ATIVIDADE = 'P') as palestras,
        (SELECT COUNT(*) FROM TB_ATIVIDADE WHERE TP_ATIVIDADE = 'W') as workshops,
        (SELECT COUNT(*) FROM TB_ATIVIDADE WHERE TP_ATIVIDADE = 'C') as cursos,
        (SELECT COUNT(*) FROM RL_PARTICIPA WHERE IS_CERTIFICADO = 'S') as certificados_emitidos,
        (SELECT COUNT(*) FROM RL_PARTICIPA WHERE DS_FEEDBACK IS NOT NULL) as feedbacks_recebidos
),
analise_detalhada AS (
    SELECT 
        m.*,
        (SELECT AVG(a.CARGA_HORARIA) FROM TB_ATIVIDADE a) as carga_horaria_media,
        (SELECT COUNT(DISTINCT a.NM_AREA_ESTUDO) FROM TB_ATIVIDADE a) as areas_estudo_unicas,
        RANK() OVER (ORDER BY m.total_participacoes DESC) as dummy_rank,
        (SELECT COUNT(*) 
         FROM (SELECT COUNT(rl.ID_PARTICIPANTE) 
               FROM RL_PARTICIPA rl 
               JOIN TB_ATIVIDADE a ON rl.ID_ATIVIDADE = a.ID_ATIVIDADE
               GROUP BY a.TP_ATIVIDADE) as sub) as grupos_tipo_atividade,
        ROUND((m.certificados_emitidos * 100.0 / m.total_participacoes), 2) as taxa_certificacao,
        ROUND((m.feedbacks_recebidos * 100.0 / m.total_participacoes), 2) as taxa_feedback
    FROM metricas_consolidadas m
)
SELECT 
    total_atividades,
    total_participantes,
    total_parceiros,
    total_participacoes,
    eventos,
    palestras,
    workshops,
    cursos,
    certificados_emitidos,
    feedbacks_recebidos,
    carga_horaria_media,
    areas_estudo_unicas,
    taxa_certificacao,
    taxa_feedback,
    ROW_NUMBER() OVER (ORDER BY total_participacoes DESC) as exemplo_window
FROM analise_detalhada;

-- 11. Quantidade de participantes por tipo de atividade
-- Objetivo: Relatório sobre impacto e participação (Requisito 4 e 7)
SELECT 
    a.tp_atividade,
    COUNT(DISTINCT p.id_participante) AS total_participantes,
    ROUND(AVG(a.carga_horaria), 2) AS media_carga_horaria
FROM tb_atividade a
JOIN rl_participa r ON a.id_atividade = r.id_atividade
JOIN tb_participante p ON r.id_participante = p.id_participante
GROUP BY a.tp_atividade
ORDER BY total_participantes DESC;

-- 12. Atividades com maior número de certificados emitidos
-- Objetivo: Emitir certificados e analisar impacto (Requisitos 3 e 4)
SELECT 
    a.nm_atividade,
    COUNT(*) AS certificados_emitidos
FROM rl_participa r
JOIN tb_atividade a ON a.id_atividade = r.id_atividade
JOIN tb_participante p ON r.id_participante = p.id_participante
WHERE r.is_certificado = 'S'
GROUP BY a.nm_atividade
ORDER BY certificados_emitidos DESC;

-- 13. Participantes que mais frequentaram atividades
-- Objetivo: Controlar o histórico de participação (Requisito 2)
SELECT 
    p.nm_primeiro || ' ' || p.nm_ultimo AS nome_participante,
    COUNT(r.id_atividade) AS total_atividades,
    RANK() OVER (ORDER BY COUNT(r.id_atividade) DESC) AS posicao
FROM tb_participante p
JOIN rl_participa r ON p.id_participante = r.id_participante
JOIN tb_atividade a ON r.id_atividade = a.id_atividade
GROUP BY p.id_participante, p.nm_primeiro, p.nm_ultimo;

-- 14. Parceiros mais frequentes nas atividades
-- Objetivo: Gerenciar parcerias com empresas e ONGs (Requisito 5)
SELECT 
    pr.nm_empresa,
    COUNT(DISTINCT pr.id_atividade) AS qtd_atividades,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT pr.id_atividade) DESC) AS ranking
FROM tb_parceiro pr
JOIN tb_atividade a ON pr.id_atividade = a.id_atividade
JOIN rl_participa r ON a.id_atividade = r.id_atividade
GROUP BY pr.nm_empresa;

-- 15. Média de feedback por tipo de atividade 
-- Objetivo: Avaliar feedback dos participantes (Requisito 3)
SELECT 
    a.tp_atividade,
    COUNT(r.ds_feedback) AS total_feedbacks,
    ROUND(AVG(LENGTH(r.ds_feedback)), 2) AS media_tamanho_feedback
FROM rl_participa r
JOIN tb_atividade a ON r.id_atividade = a.id_atividade
JOIN tb_participante p ON r.id_participante = p.id_participante
GROUP BY a.tp_atividade;

-- 16. Subconsulta – participantes com mais de 3 certificados 
-- Objetivo: Histórico e certificação (Requisitos 2 e 3)
SELECT 
    p.nm_primeiro || ' ' || p.nm_ultimo AS nome_participante,
    total_certificados
FROM (
    SELECT 
        r.id_participante,
        COUNT(*) AS total_certificados
    FROM rl_participa r
    JOIN tb_atividade a ON r.id_atividade = a.id_atividade
    WHERE r.is_certificado = 'S'
    GROUP BY r.id_participante
) sub
JOIN tb_participante p ON p.id_participante = sub.id_participante
WHERE total_certificados > 3
ORDER BY total_certificados DESC;

-- 17. Tempo médio de atividades por área de estudo
-- Objetivo: Relatório de desempenho e impacto (Requisito 4)
SELECT 
    a.nm_area_estudo,
    ROUND(AVG(a.carga_horaria), 2) AS media_carga,
    COUNT(DISTINCT a.id_atividade) AS qtd_atividades,
    RANK() OVER (ORDER BY ROUND(AVG(a.carga_horaria), 2) DESC) as ranking_carga
FROM tb_atividade a
JOIN rl_participa r ON a.id_atividade = r.id_atividade
JOIN tb_parceiro pr ON a.id_atividade = pr.id_atividade
GROUP BY a.nm_area_estudo
HAVING COUNT(DISTINCT a.id_atividade) > 2;

-- 18. Correlação entre participantes e empresas parceiras
-- Objetivo: Analisar impacto e colaboração (Requisitos 1 e 5)
SELECT 
    p.nm_instituicao,
    COUNT(DISTINCT pr.nm_empresa) AS total_empresas_parceiras,
    COUNT(DISTINCT r.id_participante) AS total_participantes
FROM tb_participante p
JOIN rl_participa r ON p.id_participante = r.id_participante
JOIN tb_atividade a ON r.id_atividade = a.id_atividade
JOIN tb_parceiro pr ON pr.id_atividade = a.id_atividade
GROUP BY p.nm_instituicao
ORDER BY total_empresas_parceiras DESC;

-- 19. Ranking de atividades com maior número de feedbacks
-- Objetivo: Melhorar engajamento e comunicação (Requisito 7)
SELECT 
    a.nm_atividade,
    COUNT(r.ds_feedback) AS total_feedbacks,
    ROW_NUMBER() OVER (ORDER BY COUNT(r.ds_feedback) DESC) AS ranking_feedback
FROM tb_atividade a
JOIN rl_participa r ON a.id_atividade = r.id_atividade
JOIN tb_participante p ON r.id_participante = p.id_participante
GROUP BY a.id_atividade, a.nm_atividade;

-- 20. Subconsulta – instituições com maior média de certificados
-- Objetivo: Relatórios de impacto institucional (Requisito 4 e 7)
SELECT 
    p.nm_instituicao,
    ROUND(AVG(sub.total_certificados), 2) AS media_certificados
FROM (
    SELECT 
        r.id_participante,
        COUNT(*) AS total_certificados
    FROM rl_participa r
    JOIN tb_atividade a ON r.id_atividade = a.id_atividade
    WHERE r.is_certificado = 'S'
    GROUP BY r.id_participante
) sub
JOIN tb_participante p ON p.id_participante = sub.id_participante
GROUP BY p.nm_instituicao
ORDER BY media_certificados DESC;
