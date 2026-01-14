-- Em relacao a indexacao RL_PARTICIPA, iD_ATIVIDADE, IS_CERTIFICADO, ID_PARTICIPANTE sao candidatos analisando essas consultas

--CONSULTA 1
--Relatório de atividades com maior participação e taxa de certificação	4.2  Apresentar dados estatísticos sobre participação, presença e emissão de certificados	Fornece dados estatísticos específicos sobre participação e emissão de certificados por atividade

SELECT 
    a.ID_ATIVIDADE,
    a.NM_ATIVIDADE,
    a.TP_ATIVIDADE,
    COUNT(p.ID_PARTICIPANTE) as total_participantes,
    COUNT(CASE WHEN rp.IS_CERTIFICADO = 'S' THEN 1 END) as certificados_emitidos,
    ROUND(COUNT(CASE WHEN rp.IS_CERTIFICADO = 'S' THEN 1 END) * 100.0 / COUNT(p.ID_PARTICIPANTE), 2) as taxa_certificacao
FROM TB_ATIVIDADE a
JOIN RL_PARTICIPA rp ON a.ID_ATIVIDADE = rp.ID_ATIVIDADE
JOIN TB_PARTICIPANTE p ON rp.ID_PARTICIPANTE = p.ID_PARTICIPANTE
GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.TP_ATIVIDADE
ORDER BY total_participantes DESC;

--CONSULTA 2
--Ranking de participantes com maior histórico de atividades concluídas	7.3  Facilitar o registro e visualização do histórico de atividades concluídas	Facilita o acesso rápido ao histórico de atividades concluídas e identifica os participantes mais engajados

SELECT 
    p.ID_PARTICIPANTE,
    p.NM_PRIMEIRO || ' ' || COALESCE(p.NM_MEIO || ' ', '') || p.NM_ULTIMO as nome_completo,
    COUNT(rp.ID_ATIVIDADE) as atividades_concluidas,
    SUM(a.CARGA_HORARIA) as carga_horaria_total,
    RANK() OVER (ORDER BY COUNT(rp.ID_ATIVIDADE) DESC) as ranking
FROM TB_PARTICIPANTE p
JOIN RL_PARTICIPA rp ON p.ID_PARTICIPANTE = rp.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON rp.ID_ATIVIDADE = a.ID_ATIVIDADE
WHERE rp.IS_CERTIFICADO = 'S'
GROUP BY p.ID_PARTICIPANTE, nome_completo
ORDER BY atividades_concluidas DESC;

--CONSULTA 3
--Análise de feedback por tipo de atividade	3.1  Registrar feedbacks dos participantes	Permite registrar e analisar feedbacks agrupados por tipo de atividade

SELECT 
    a.TP_ATIVIDADE,
    COUNT(rp.ID_PARTICIPANTE) as total_participantes,
    COUNT(rp.DS_FEEDBACK) as feedbacks_recebidos,
    ROUND(COUNT(rp.DS_FEEDBACK) * 100.0 / COUNT(rp.ID_PARTICIPANTE), 2) as taxa_feedback
FROM TB_ATIVIDADE a
JOIN RL_PARTICIPA rp ON a.ID_ATIVIDADE = rp.ID_ATIVIDADE
JOIN TB_PARTICIPANTE p ON rp.ID_PARTICIPANTE = p.ID_PARTICIPANTE
GROUP BY a.TP_ATIVIDADE
ORDER BY taxa_feedback DESC;

--CONSULTA 4
--Relatório de parceiros por categoria e atividades apoiadas	4.1  Disponibilizar relatórios sobre impacto e participação	Disponibiliza relatório específico sobre o impacto dos parceiros nas atividades

SELECT 
    par.TP_CATEGORIA,
    par.NM_EMPRESA,
    COUNT(DISTINCT par.ID_ATIVIDADE) as atividades_apoiadas,
    COUNT(DISTINCT rp.ID_PARTICIPANTE) as total_participantes_impactados
FROM TB_PARCEIRO par
JOIN TB_ATIVIDADE a ON par.ID_ATIVIDADE = a.ID_ATIVIDADE
JOIN RL_PARTICIPA rp ON a.ID_ATIVIDADE = rp.ID_ATIVIDADE
GROUP BY par.TP_CATEGORIA, par.NM_EMPRESA
ORDER BY atividades_apoiadas DESC, total_participantes_impactados DESC;

----------CONSULTA 5
--Estatísticas de participação por gênero e tipo de participação	4.2  Apresentar dados estatísticos sobre participação, presença e emissão de certificados	Apresenta dados estatísticos demográficos detalhados sobre participação


SELECT 
    p.TP_GENERO,
    p.TP_PARTICIPACAO,
    COUNT(DISTINCT p.ID_PARTICIPANTE) as total_participantes,
    COUNT(rp.ID_ATIVIDADE) as total_inscricoes,
    COUNT(CASE WHEN rp.IS_CERTIFICADO = 'S' THEN 1 END) as certificados_obtidos
FROM TB_PARTICIPANTE p
JOIN RL_PARTICIPA rp ON p.ID_PARTICIPANTE = rp.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON rp.ID_ATIVIDADE = a.ID_ATIVIDADE
GROUP BY p.TP_GENERO, p.TP_PARTICIPACAO
ORDER BY p.TP_GENERO, p.TP_PARTICIPACAO;


-------CONSULTA 6
--Análise de carga horária total por participante	7.3  Facilitar o registro e visualização do histórico de atividades concluídas	Permite visualização rápida do histórico cumulativo de atividades concluídas por participante

SELECT 
    p.ID_PARTICIPANTE,
    p.NM_PRIMEIRO || ' ' || COALESCE(p.NM_MEIO || ' ', '') || p.NM_ULTIMO as nome_completo,
    p.TP_PARTICIPACAO,
    COUNT(rp.ID_ATIVIDADE) as atividades_concluidas,
    SUM(a.CARGA_HORARIA) as carga_horaria_total,
    ROUND(AVG(a.CARGA_HORARIA), 2) as media_horas_por_atividade,
    DENSE_RANK() OVER (ORDER BY SUM(a.CARGA_HORARIA) DESC) as ranking_carga_horaria
FROM TB_PARTICIPANTE p
JOIN RL_PARTICIPA rp ON p.ID_PARTICIPANTE = rp.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON rp.ID_ATIVIDADE = a.ID_ATIVIDADE
WHERE rp.IS_CERTIFICADO = 'S'
GROUP BY p.ID_PARTICIPANTE, nome_completo, p.TP_PARTICIPACAO
ORDER BY carga_horaria_total DESC;


---------CONSULTA 7
--Relatório mensal de atividades e participação	4.1  Disponibilizar relatórios sobre impacto e participação	Disponibiliza relatório temporal sobre impacto e participação organizado por períodos

SELECT 
    TO_CHAR(a.DT_ATIVIDADE, 'YYYY-MM') as mes_ano,
    COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades,
    COUNT(DISTINCT rp.ID_PARTICIPANTE) as total_participantes_unicos,
    COUNT(rp.ID_PARTICIPANTE) as total_inscricoes,
    COUNT(CASE WHEN rp.IS_CERTIFICADO = 'S' THEN 1 END) as certificados_emitidos,
    ROUND(COUNT(rp.ID_PARTICIPANTE) * 1.0 / COUNT(DISTINCT a.ID_ATIVIDADE), 2) as media_participantes_por_atividade,
    ROUND(COUNT(CASE WHEN rp.IS_CERTIFICADO = 'S' THEN 1 END) * 100.0 / COUNT(rp.ID_PARTICIPANTE), 2) as taxa_certificacao_mensal
FROM TB_ATIVIDADE a
JOIN RL_PARTICIPA rp ON a.ID_ATIVIDADE = rp.ID_ATIVIDADE
JOIN TB_PARTICIPANTE p ON rp.ID_PARTICIPANTE = p.ID_PARTICIPANTE
GROUP BY TO_CHAR(a.DT_ATIVIDADE, 'YYYY-MM')
ORDER BY mes_ano DESC;

---------CONSULTA 8
--Parceiros mais ativos por categoria e área de estudo	4.1  Disponibilizar relatórios sobre impacto e participação	Fornece relatório específico sobre o impacto dos parceiros por categoria e área, atendendo ao subitem 4.1

SELECT 
    par.TP_CATEGORIA,
    a.NM_AREA_ESTUDO,
    COUNT(DISTINCT par.ID_PARCEIRO) as total_parceiros,
    COUNT(DISTINCT par.ID_ATIVIDADE) as total_atividades_apoiadas,
    COUNT(DISTINCT rp.ID_PARTICIPANTE) as participantes_impactados,
    COUNT(CASE WHEN rp.IS_CERTIFICADO = 'S' THEN 1 END) as certificados_emitidos,
    RANK() OVER (PARTITION BY par.TP_CATEGORIA ORDER BY COUNT(DISTINCT par.ID_ATIVIDADE) DESC) as ranking_categoria
FROM TB_PARCEIRO par
JOIN TB_ATIVIDADE a ON par.ID_ATIVIDADE = a.ID_ATIVIDADE
JOIN RL_PARTICIPA rp ON a.ID_ATIVIDADE = rp.ID_ATIVIDADE
GROUP BY par.TP_CATEGORIA, a.NM_AREA_ESTUDO
ORDER BY par.TP_CATEGORIA, total_atividades_apoiadas DESC;

