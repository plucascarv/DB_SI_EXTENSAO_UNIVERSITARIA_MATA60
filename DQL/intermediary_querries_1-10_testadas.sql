
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

---CONSULTA 7
-- (Requisito 7.3) A querry busca analisar a diversidade 
-- nos ouvintes que concluíram o maior número de atividades
-- em áreas distintas.

SELECT
    CONCAT(P.NM_PRIMEIRO,' ',P.NM_ULTIMO) AS nm_ouvinte,
    P.CD_MATRICULA,
    COUNT(DISTINCT A.NM_AREA_ESTUDO) AS areas_distintas
FROM TB_PARTICIPANTE P
JOIN RL_PARTICIPA R ON P.ID_PARTICIPANTE = R.ID_PARTICIPANTE
JOIN TB_ATIVIDADE A ON R.ID_ATIVIDADE = A.ID_ATIVIDADE
WHERE P.TP_PARTICIPACAO = 'O' AND R.IS_CERTIFICADO = 'S'
GROUP BY P.ID_PARTICIPANTE, P.NM_PRIMEIRO, P.NM_ULTIMO, P.CD_MATRICULA
ORDER BY areas_distintas DESC;

---CONSULTA 8

-- (Requisito 3.1) A querry busca analisar a taxa de respostas
-- em feedback por tipo de participante, para entender que tipo
-- de ouvinte deixa mais feedback.

SELECT
    P.TP_PARTICIPACAO,
    COUNT(R.ID_PARTICIPANTE) AS total_inscritos,
    COUNT(R.DS_FEEDBACK) AS feedbacks_recebidos,
    CONCAT(ROUND((COUNT(R.DS_FEEDBACK)*100.0)/(COUNT(R.ID_PARTICIPANTE)),2),'%') AS taxa_feedback
FROM TB_PARTICIPANTE P
JOIN RL_PARTICIPA R ON P.ID_PARTICIPANTE = R.ID_PARTICIPANTE
JOIN TB_ATIVIDADE A ON R.ID_ATIVIDADE = A.ID_ATIVIDADE
GROUP BY P.TP_PARTICIPACAO
ORDER BY taxa_feedback DESC;

---CONSULTA 9

-- (Requisito 4.1) A querry busca analisar o impacto do local e
-- infraestrutura das atividades na participação e da conclusão
-- nas mesmas.

SELECT
    A.DS_LOCAL,
    COUNT(R.ID_PARTICIPANTE) AS total_participantes,
    COUNT(CASE WHEN R.IS_CERTIFICADO = 'S' THEN 1 END) AS total_certificados,
    CONCAT(ROUND(
        (COUNT(CASE WHEN R.IS_CERTIFICADO = 'S' THEN 1 END) * 100.0) /
        COUNT(R.ID_PARTICIPANTE),
        2
    ),'%') AS taxa_certificacao
FROM TB_ATIVIDADE A
JOIN RL_PARTICIPA R ON A.ID_ATIVIDADE = R.ID_ATIVIDADE
JOIN TB_PARTICIPANTE P ON R.ID_PARTICIPANTE = P.ID_PARTICIPANTE
GROUP BY A.DS_LOCAL
ORDER BY total_participantes DESC;

---CONSULTA 10

-- (Requisitos 7.1 e 3.1) A querry busca verificar quantos feedbacks pedem
-- de ser fornecidos por cada ouvinte que concluiu uma atividade, para poder
-- implementar um sistema de notificação por email (e.g.).

SELECT
    P.ID_PARTICIPANTE,
    CONCAT(P.NM_PRIMEIRO, ' ', P.NM_ULTIMO) AS nm_ouvinte,
    COUNT(A.ID_ATIVIDADE) AS qtd_feedbacks_pendentes
FROM TB_PARTICIPANTE P
JOIN RL_PARTICIPA R ON P.ID_PARTICIPANTE = R.ID_PARTICIPANTE
JOIN TB_ATIVIDADE A ON R.ID_ATIVIDADE = A.ID_ATIVIDADE
WHERE P.TP_PARTICIPACAO = 'O' AND R.IS_CERTIFICADO = 'S' AND R.DS_FEEDBACK IS NULL
GROUP BY P.ID_PARTICIPANTE, P.NM_PRIMEIRO, P.NM_ULTIMO
ORDER BY qtd_feedbacks_pendentes DESC;
