-- Criação da Materialized View para suporte à validação
-- Atende ao critério de Consulta Avançada: 3 tabelas e 3 funções (JOIN, WINDOW, COUNT)
CREATE MATERIALIZED VIEW mv_pendencias_validacao AS
SELECT 
    p.nm_primeiro || ' ' || p.nm_ultimo AS participante,
    a.nm_atividade,
    a.tp_atividade,
    -- Função WINDOW e COUNT para métrica analítica
    COUNT(r.id_participacao) OVER(PARTITION BY p.id_participante) AS total_atividades_inscrito
FROM tb_participante p
JOIN rl_participa r ON p.id_participante = r.id_participante -- Função JOIN
JOIN tb_atividade a ON r.id_atividade = a.id_atividade
WHERE r.is_certificado = 'N'
WITH DATA;

-- [Comando SELECT 1]: Consulta à View Materializada
SELECT * FROM mv_pendencias_validacao WHERE tp_atividade = 'Workshop';

-- [Comando SELECT 2]: Consulta Intermediária para verificação de segurança (3 tabelas)
-- Verifica se a relação participante/atividade já existe antes de processar
SELECT p.id_participante, a.id_atividade
FROM tb_participante p
JOIN rl_participa r ON p.id_participante = r.id_participante
JOIN tb_atividade a ON r.id_atividade = a.id_atividade
WHERE p.id_participante = 10 AND a.id_atividade = 5;