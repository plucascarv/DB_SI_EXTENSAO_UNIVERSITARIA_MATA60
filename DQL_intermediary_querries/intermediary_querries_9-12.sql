-- (Requisito 7.3) A querry busca analisar a diversidade 
-- nos ouvintes que concluíram o maior número de atividades
-- em áreas distintas.

SELECT
    concat(p.nm_primeiro,' ',p.nm_ultimo) as nm_ouvinte,
    p.cd_matricula,
    count(distinct a.nm_area_estudo) as areas_distintas
FROM
    tb_participante as p
JOIN
    rl_participa as r on p.id_participante = r.id_participante
JOIN
    tb_atividade as a on r.id_atividade = a.id_atividade
WHERE
    p.tp_participacao = 'O' and r.is_certificado = 'S'
GROUP BY
    p.id_participante, p.nm_primeiro, p.nm_ultimo, p.cd_matricula
ORDER BY
    areas_distintas desc;

-- (Requisito 3.1) A querry busca analisar a taxa de respostas
-- em feedback por tipo de participante, para entender que tipo
-- de ouvinte deixa mais feedback.

SELECT
    p.tp_participacao,
    count(r.id_participante) as total_inscritos,
    count(r.ds_feedback) as feedbacks_recebidos,
    concat(round((count(r.ds_feedback)*100)/(count(r.id_participante)),2),'%') as taxa_feedback
FROM
    tb_participante as p
JOIN
    rl_participa as r on p.id_participante = r.id_participante
JOIN
    tb_atividade as a on r.id_atividade = a.id_atividade
GROUP BY
    p.tp_participacao
ORDER BY
    taxa_feedback desc;

-- (Requisito 4.1) A querry busca analisar o impacto do local e
-- infraestrutura das atividades na participação e da conclusão
-- nas mesmas.

SELECT
    a.ds_local,
    count(r.id_participante) as total_participantes,
    count(case when r.is_certificado = 'S' then 1 end) as total_certificados,
    concat(round(
        (count(case when r.is_certificado = 'S' then 1 end) * 100.0) / 
        count(r.id_participante),
        2
    ),'%') as taxa_certificacao
FROM
    tb_atividade as a
JOIN
    rl_participa as r on a.id_atividade = r.id_atividade
JOIN
    tb_participante as p on r.id_participante = p.id_participante
GROUP BY
    a.ds_local
ORDER BY
    total_participantes desc;

-- (Requisitos 7.1 e 3.1) A querry busca verificar quantos feedbacks pedem
-- de ser fornecidos por cada ouvinte que concluiu uma atividade, para poder
-- implementar um sistema de notificação por email (e.g.).

SELECT
    p.id_participante,
    concat(p.nm_primeiro, ' ', p.nm_ultimo) as nm_ouvinte,
    count(a.id_atividade) as qtd_feedbacks_pendentes
FROM
    tb_participante as p
JOIN
    rl_participa as r on p.id_participante = r.id_participante
JOIN
    tb_atividade as a on r.id_atividade = a.id_atividade
WHERE
    p.tp_participacao = 'O' and r.is_certificado = 'S' and r.ds_feedback is null
GROUP BY
    p.id_participante, p.nm_primeiro, p.nm_ultimo
ORDER BY
    qtd_feedbacks_pendentes desc;
