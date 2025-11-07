-- 1. Quantidade de participantes por tipo de atividade
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

-- 2. Atividades com maior número de certificados emitidos
-- Objetivo: Emitir certificados e analisar impacto (Requisitos 3 e 4)
SELECT 
    a.nm_atividade,
    COUNT(*) AS certificados_emitidos
FROM rl_participa r
JOIN tb_atividade a ON a.id_atividade = r.id_atividade
JOIN tb_participante p ON r.id_participante = p.id_participante
WHERE r.is_certificado = 'S'
GROUP BY a.nm_atividade
ORDER BY certificados_emitidos DESC
LIMIT 10;

-- 3. Participantes que mais frequentaram atividades
-- Objetivo: Controlar o histórico de participação (Requisito 2)
SELECT 
    p.nm_primeiro || ' ' || p.nm_ultimo AS nome_participante,
    COUNT(r.id_atividade) AS total_atividades,
    RANK() OVER (ORDER BY COUNT(r.id_atividade) DESC) AS posicao
FROM tb_participante p
JOIN rl_participa r ON p.id_participante = r.id_participante
JOIN tb_atividade a ON r.id_atividade = a.id_atividade
GROUP BY p.id_participante, p.nm_primeiro, p.nm_ultimo;

-- 4. Parceiros mais frequentes nas atividades
-- Objetivo: Gerenciar parcerias com empresas e ONGs (Requisito 5)
SELECT 
    pr.nm_empresa,
    COUNT(DISTINCT pr.id_atividade) AS qtd_atividades,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT pr.id_atividade) DESC) AS ranking
FROM tb_parceiro pr
JOIN tb_atividade a ON pr.id_atividade = a.id_atividade
JOIN rl_participa r ON a.id_atividade = r.id_atividade
GROUP BY pr.nm_empresa;

-- 5. Média de feedback por tipo de atividade 
-- Objetivo: Avaliar feedback dos participantes (Requisito 3)
SELECT 
    a.tp_atividade,
    COUNT(r.ds_feedback) AS total_feedbacks,
    ROUND(AVG(LENGTH(r.ds_feedback)), 2) AS media_tamanho_feedback
FROM rl_participa r
JOIN tb_atividade a ON r.id_atividade = a.id_atividade
JOIN tb_participante p ON r.id_participante = p.id_participante
GROUP BY a.tp_atividade;

-- 6. Subconsulta – participantes com mais de 3 certificados 
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

-- 7. Tempo médio de atividades por área de estudo
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

-- 8. Correlação entre participantes e empresas parceiras
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

-- 9. Ranking de atividades com maior número de feedbacks
-- Objetivo: Melhorar engajamento e comunicação (Requisito 7)
SELECT 
    a.nm_atividade,
    COUNT(r.ds_feedback) AS total_feedbacks,
    ROW_NUMBER() OVER (ORDER BY COUNT(r.ds_feedback) DESC) AS ranking_feedback
FROM tb_atividade a
JOIN rl_participa r ON a.id_atividade = r.id_atividade
JOIN tb_participante p ON r.id_participante = p.id_participante
GROUP BY a.id_atividade, a.nm_atividade;

-- 10. Subconsulta – instituições com maior média de certificados
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