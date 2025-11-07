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

-- Requisito 1.4: Gestão de Múltiplos Instrutores por Atividade
SELECT 
    a.ID_ATIVIDADE,
    a.NM_ATIVIDADE,
    a.DT_ATIVIDADE,
    a.DS_LOCAL,
    COUNT(CASE WHEN p.TP_PARTICIPACAO = 'I' THEN 1 END) as quantidade_instrutores,
    GROUP_CONCAT(DISTINCT CONCAT(p.NM_PRIMEIRO, ' ', COALESCE(p.NM_MEIO, ''), ' ', p.NM_ULTIMO) SEPARATOR ', ') as nomes_instrutores,
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

-- Requisito 1.5: Análise de Parcerias com Empresas e ONGs
SELECT 
    par.TP_CATEGORIA,
    par.NM_EMPRESA,
    COUNT(DISTINCT par.ID_ATIVIDADE) as total_atividades_apoiadas,
    GROUP_CONCAT(DISTINCT a.NM_ATIVIDADE SEPARATOR '; ') as atividades_apoiadas,
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

-- Requisito 1.7: Emissão Automática de Certificados
SELECT 
    p.ID_PARTICIPANTE,
    CONCAT(p.NM_PRIMEIRO, ' ', COALESCE(p.NM_MEIO, ''), ' ', p.NM_ULTIMO) as nome_completo,
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
     AND a2.DT_ATIVIDADE <= CURDATE() 
     AND rl2.IS_CERTIFICADO = 'N') as total_pendentes_participante,
    RANK() OVER (PARTITION BY a.ID_ATIVIDADE ORDER BY p.TP_PARTICIPACAO DESC) as prioridade_emissao
FROM TB_PARTICIPANTE p
JOIN RL_PARTICIPA rl ON p.ID_PARTICIPANTE = rl.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON rl.ID_ATIVIDADE = a.ID_ATIVIDADE
WHERE a.DT_ATIVIDADE <= CURDATE()
  AND rl.IS_CERTIFICADO = 'N'
ORDER BY a.DT_ATIVIDADE, p.NM_ULTIMO, p.NM_PRIMEIRO;

-- Requisito 1.3: Dashboard de Atividades - Status e Métricas
WITH status_atividade AS (
    SELECT 
        a.ID_ATIVIDADE,
        a.NM_ATIVIDADE,
        a.DT_ATIVIDADE,
        a.TP_ATIVIDADE,
        a.NM_AREA_ESTUDO,
        CASE 
            WHEN a.DT_ATIVIDADE > CURDATE() THEN 'AGENDADA'
            WHEN a.DT_ATIVIDADE = CURDATE() THEN 'EM ANDAMENTO'
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

-- Requisito 1.6: Relatório de Participação por Instituição e Área de Estudo
SELECT 
    p.NM_INSTITUICAO,
    a.NM_AREA_ESTUDO,
    COUNT(DISTINCT p.ID_PARTICIPANTE) as total_participantes_unicos,
    COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades_participadas,
    SUM(a.CARGA_HORARIA) as carga_horaria_total,
    COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) as instrutores,
    COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'M' THEN p.ID_PARTICIPANTE END) as monitores,
    COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'O' THEN p.ID_PARTICIPANTE END) as ouvintes,
    ROUND(AVG(COUNT(DISTINCT a.ID_ATIVIDADE)) OVER (PARTITION BY p.NM_INSTITUICAO), 2) as media_atividades_por_participante,
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
HAVING total_participantes_unicos >= 3
ORDER BY p.NM_INSTITUICAO, total_atividades_participadas DESC;

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
             AND a2.DT_ATIVIDADE < CURDATE()
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
WHERE a.DT_ATIVIDADE >= CURDATE()
GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.HR_ATIVIDADE, a.DS_LOCAL, a.TP_ATIVIDADE, a.NM_AREA_ESTUDO, a.CARGA_HORARIA
ORDER BY a.DT_ATIVIDADE, a.HR_ATIVIDADE;

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