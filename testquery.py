import time
import psycopg2
import pandas as pd


# Conexão com o banco

conn = psycopg2.connect(
    dbname="ProjetoFinal",
    user="postgres",
    password="2222",
    host="localhost",
    port="5432"
)

cur = conn.cursor()


#  Consultas intermediárias (10)

consultas_intermediarias = [
    # C1: Relatório de atividades com maior participação e taxa de certificação
    ("inter_01", "SELECT a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.TP_ATIVIDADE, COUNT(p.ID_PARTICIPANTE) as total_participantes, COUNT(CASE WHEN rp.IS_CERTIFICADO = 'S' THEN 1 END) as certificados_emitidos, ROUND(COUNT(CASE WHEN rp.IS_CERTIFICADO = 'S' THEN 1 END) * 100.0 / COUNT(p.ID_PARTICIPANTE), 2) as taxa_certificacao FROM TB_ATIVIDADE a JOIN RL_PARTICIPA rp ON a.ID_ATIVIDADE = rp.ID_ATIVIDADE JOIN TB_PARTICIPANTE p ON rp.ID_PARTICIPANTE = p.ID_PARTICIPANTE GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.TP_ATIVIDADE ORDER BY total_participantes DESC;"),
    # C2: Ranking de participantes com maior histórico de atividades concluídas
    ("inter_02", "SELECT p.ID_PARTICIPANTE, p.NM_PRIMEIRO || ' ' || COALESCE(p.NM_MEIO || ' ', '') || p.NM_ULTIMO as nome_completo, COUNT(rp.ID_ATIVIDADE) as atividades_concluidas, SUM(a.CARGA_HORARIA) as carga_horaria_total, RANK() OVER (ORDER BY COUNT(rp.ID_ATIVIDADE) DESC) as ranking FROM TB_PARTICIPANTE p JOIN RL_PARTICIPA rp ON p.ID_PARTICIPANTE = rp.ID_PARTICIPANTE JOIN TB_ATIVIDADE a ON rp.ID_ATIVIDADE = a.ID_ATIVIDADE WHERE rp.IS_CERTIFICADO = 'S' GROUP BY p.ID_PARTICIPANTE, nome_completo ORDER BY atividades_concluidas DESC;"),
    # C3: Análise de feedback por tipo de atividade
    ("inter_03", "SELECT a.TP_ATIVIDADE, COUNT(rp.ID_PARTICIPANTE) as total_participantes, COUNT(rp.DS_FEEDBACK) as feedbacks_recebidos, ROUND(COUNT(rp.DS_FEEDBACK) * 100.0 / COUNT(rp.ID_PARTICIPANTE), 2) as taxa_feedback FROM TB_ATIVIDADE a JOIN RL_PARTICIPA rp ON a.ID_ATIVIDADE = rp.ID_ATIVIDADE JOIN TB_PARTICIPANTE p ON rp.ID_PARTICIPANTE = p.ID_PARTICIPANTE GROUP BY a.TP_ATIVIDADE ORDER BY taxa_feedback DESC;"),
    # C4: Relatório de parceiros por categoria e atividades apoiadas
    ("inter_04", "SELECT par.TP_CATEGORIA, par.NM_EMPRESA, COUNT(DISTINCT par.ID_ATIVIDADE) as atividades_apoiadas, COUNT(DISTINCT rp.ID_PARTICIPANTE) as total_participantes_impactados FROM TB_PARCEIRO par JOIN TB_ATIVIDADE a ON par.ID_ATIVIDADE = a.ID_ATIVIDADE JOIN RL_PARTICIPA rp ON a.ID_ATIVIDADE = rp.ID_ATIVIDADE GROUP BY par.TP_CATEGORIA, par.NM_EMPRESA ORDER BY atividades_apoiadas DESC, total_participantes_impactados DESC;"),
    # C5: Estatísticas de participação por gênero e tipo de participação
    ("inter_05", "SELECT p.TP_GENERO, p.TP_PARTICIPACAO, COUNT(DISTINCT p.ID_PARTICIPANTE) as total_participantes, COUNT(rp.ID_ATIVIDADE) as total_inscricoes, COUNT(CASE WHEN rp.IS_CERTIFICADO = 'S' THEN 1 END) as certificados_obtidos FROM TB_PARTICIPANTE p JOIN RL_PARTICIPA rp ON p.ID_PARTICIPANTE = rp.ID_PARTICIPANTE JOIN TB_ATIVIDADE a ON rp.ID_ATIVIDADE = a.ID_ATIVIDADE GROUP BY p.TP_GENERO, p.TP_PARTICIPACAO ORDER BY p.TP_GENERO, p.TP_PARTICIPACAO;"),
    # C6: Análise de carga horária total por participante
    ("inter_06", "SELECT p.ID_PARTICIPANTE, p.NM_PRIMEIRO || ' ' || COALESCE(p.NM_MEIO || ' ', '') || p.NM_ULTIMO as nome_completo, p.TP_PARTICIPACAO, COUNT(rp.ID_ATIVIDADE) as atividades_concluidas, SUM(a.CARGA_HORARIA) as carga_horaria_total, ROUND(AVG(a.CARGA_HORARIA), 2) as media_horas_por_atividade, DENSE_RANK() OVER (ORDER BY SUM(a.CARGA_HORARIA) DESC) as ranking_carga_horaria FROM TB_PARTICIPANTE p JOIN RL_PARTICIPA rp ON p.ID_PARTICIPANTE = rp.ID_PARTICIPANTE JOIN TB_ATIVIDADE a ON rp.ID_ATIVIDADE = a.ID_ATIVIDADE WHERE rp.IS_CERTIFICADO = 'S' GROUP BY p.ID_PARTICIPANTE, nome_completo, p.TP_PARTICIPACAO ORDER BY carga_horaria_total DESC;"),
    # C7: Analisar diversidade de áreas distintas concluídas por ouvintes
    ("inter_07", "SELECT concat(p.nm_primeiro,' ',p.nm_ultimo) as nm_ouvinte, p.cd_matricula, count(distinct a.nm_area_estudo) as areas_distintas FROM tb_participante as p JOIN rl_participa as r on p.id_participante = r.id_participante JOIN tb_atividade as a on r.id_atividade = a.id_atividade WHERE p.tp_participacao = 'O' and r.is_certificado = 'S' GROUP BY p.id_participante, p.nm_primeiro, p.nm_ultimo, p.cd_matricula ORDER BY areas_distintas desc;"),
    # C8: Analisar taxa de respostas em feedback por tipo de participante
    ("inter_08", "SELECT p.tp_participacao, count(r.id_participante) as total_inscritos, count(r.ds_feedback) as feedbacks_recebidos, concat(round((count(r.ds_feedback)*100)/(count(r.id_participante)),2),'%') as taxa_feedback FROM tb_participante as p JOIN rl_participa as r on p.id_participante = r.id_participante JOIN tb_atividade as a on r.id_atividade = a.id_atividade GROUP BY p.tp_participacao ORDER BY taxa_feedback desc;"),
    # C9: Analisar impacto do local e infraestrutura das atividades na participação
    ("inter_09", "SELECT a.ds_local, count(r.id_participante) as total_participantes, count(case when r.is_certificado = 'S' then 1 end) as total_certificados, concat(round((count(case when r.is_certificado = 'S' then 1 end) * 100.0) / count(r.id_participante), 2),'%') as taxa_certificacao FROM tb_atividade as a JOIN rl_participa as r on a.id_atividade = r.id_atividade JOIN tb_participante as p on r.id_participante = p.id_participante GROUP BY a.ds_local ORDER BY total_participantes desc;"),
    # C10: Verificar quantos feedbacks estão pendentes por ouvinte que concluiu
    ("inter_10", "SELECT p.id_participante, concat(p.nm_primeiro, ' ', p.nm_ultimo) as nm_ouvinte, count(a.id_atividade) as qtd_feedbacks_pendentes FROM tb_participante as p JOIN rl_participa as r on p.id_participante = r.id_participante JOIN tb_atividade as a on r.id_atividade = a.id_atividade WHERE p.tp_participacao = 'O' and r.is_certificado = 'S' and r.ds_feedback is null GROUP BY p.id_participante, p.nm_primeiro, p.nm_ultimo ORDER BY qtd_feedbacks_pendentes desc;")
]


# Consultas avançadas (20)

consultas_avancadas = [
    # A1: Relatório de Impacto e Participação Detalhado por Atividade (R. 1.6)
    ("avanc_01", "SELECT a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.TP_ATIVIDADE, a.NM_AREA_ESTUDO, a.CARGA_HORARIA, COUNT(rl.ID_PARTICIPANTE) as total_participantes, COUNT(CASE WHEN p.TP_PARTICIPACAO = 'I' THEN 1 END) as total_instrutores, COUNT(CASE WHEN p.TP_PARTICIPACAO = 'M' THEN 1 END) as total_monitores, COUNT(CASE WHEN p.TP_PARTICIPACAO = 'O' THEN 1 END) as total_ouvintes, COUNT(par.ID_PARCEIRO) as total_parceiros, COUNT(CASE WHEN rl.IS_CERTIFICADO = 'S' THEN 1 END) as certificados_emitidos, ROUND((COUNT(CASE WHEN rl.IS_CERTIFICADO = 'S' THEN 1 END) * 100.0 / COUNT(rl.ID_PARTICIPANTE)), 2) as percentual_certificados, AVG(LENGTH(rl.DS_FEEDBACK)) as media_tamanho_feedback, RANK() OVER (ORDER BY COUNT(rl.ID_PARTICIPANTE) DESC) as ranking_participacao FROM TB_ATIVIDADE a LEFT JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE LEFT JOIN TB_PARTICIPANTE p ON rl.ID_PARTICIPANTE = p.ID_PARTICIPANTE LEFT JOIN TB_PARCEIRO par ON a.ID_ATIVIDADE = par.ID_ATIVIDADE GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.TP_ATIVIDADE, a.NM_AREA_ESTUDO, a.CARGA_HORARIA ORDER BY a.DT_ATIVIDADE DESC, total_participantes DESC;"),
    # A2: Análise de Atividades com Múltiplos Instrutores (R. 1.4)
    ("avanc_02", "SELECT a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.DS_LOCAL, COUNT(CASE WHEN p.TP_PARTICIPACAO = 'I' THEN 1 END) as quantidade_instrutores, STRING_AGG(DISTINCT CONCAT_WS(' ', p.NM_PRIMEIRO, p.NM_MEIO, p.NM_ULTIMO), ', ') FILTER (WHERE p.TP_PARTICIPACAO = 'I') as nomes_instrutores, COUNT(DISTINCT rl.ID_PARTICIPANTE) as total_envolvidos, a.CARGA_HORARIA, a.DS_ATIVIDADE, (SELECT AVG(instr_count) FROM (SELECT COUNT(CASE WHEN p2.TP_PARTICIPACAO = 'I' THEN 1 END) as instr_count FROM TB_ATIVIDADE a2 JOIN RL_PARTICIPA rl2 ON a2.ID_ATIVIDADE = rl2.ID_ATIVIDADE JOIN TB_PARTICIPANTE p2 ON rl2.ID_PARTICIPANTE = p2.ID_PARTICIPANTE WHERE a2.TP_ATIVIDADE = a.TP_ATIVIDADE GROUP BY a2.ID_ATIVIDADE) as sub) as media_instrutores_tipo, RANK() OVER (ORDER BY COUNT(CASE WHEN p.TP_PARTICIPACAO = 'I' THEN 1 END) DESC) as ranking_instrutores FROM TB_ATIVIDADE a JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE JOIN TB_PARTICIPANTE p ON rl.ID_PARTICIPANTE = p.ID_PARTICIPANTE WHERE p.TP_PARTICIPACAO = 'I' GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.DS_LOCAL, a.CARGA_HORARIA, a.DS_ATIVIDADE, a.TP_ATIVIDADE HAVING COUNT(CASE WHEN p.TP_PARTICIPACAO = 'I' THEN 1 END) > 1 ORDER BY quantidade_instrutores DESC;"),
    # A3: Análise de Parcerias por Categoria e Impacto (R. 1.5)
    ("avanc_03", "SELECT par.TP_CATEGORIA, par.NM_EMPRESA, COUNT(DISTINCT par.ID_ATIVIDADE) as total_atividades_apoiadas, STRING_AGG(DISTINCT a.NM_ATIVIDADE, '; ') as atividades_apoiadas, COUNT(DISTINCT rl.ID_PARTICIPANTE) as total_participantes_impactados, SUM(a.CARGA_HORARIA) as carga_horaria_total_apoiada, COUNT(DISTINCT a.NM_AREA_ESTUDO) as areas_estudo_envolvidas, CASE WHEN par.TP_CATEGORIA = 'F' THEN 'Financeiro' WHEN par.TP_CATEGORIA = 'P' THEN 'Palestrante' WHEN par.TP_CATEGORIA = 'M' THEN 'Material' ELSE 'Outro' END as tipo_parceria, (SELECT COUNT(DISTINCT par2.NM_EMPRESA) FROM TB_PARCEIRO par2 WHERE par2.TP_CATEGORIA = par.TP_CATEGORIA) as total_empresas_categoria, RANK() OVER (PARTITION BY par.TP_CATEGORIA ORDER BY COUNT(DISTINCT rl.ID_PARTICIPANTE) DESC) as ranking_impacto_categoria FROM TB_PARCEIRO par JOIN TB_ATIVIDADE a ON par.ID_ATIVIDADE = a.ID_ATIVIDADE LEFT JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE GROUP BY par.TP_CATEGORIA, par.NM_EMPRESA ORDER BY total_atividades_apoiadas DESC, total_participantes_impactados DESC;"),
    # A4: Relatório de Certificados Pendentes Pós-Atividade (R. 1.7)
    ("avanc_04", "SELECT p.ID_PARTICIPANTE, CONCAT_WS(' ', p.NM_PRIMEIRO, p.NM_MEIO, P.NM_ULTIMO) as nome_completo, p.CD_CPF_PARTICIPANTE, a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.CARGA_HORARIA, a.NM_AREA_ESTUDO, p.TP_PARTICIPACAO, CASE WHEN p.TP_PARTICIPACAO = 'I' THEN 'Instrutor' WHEN p.TP_PARTICIPACAO = 'M' THEN 'Monitor' WHEN p.TP_PARTICIPACAO = 'O' THEN 'Ouvinte' END as funcao_atividade, rl.IS_CERTIFICADO as certificado_emitido, CASE WHEN rl.IS_CERTIFICADO = 'N' THEN 'PENDENTE' ELSE 'EMITIDO' END as status_certificado, (SELECT COUNT(*) FROM RL_PARTICIPA rl2 JOIN TB_ATIVIDADE a2 ON rl2.ID_ATIVIDADE = a2.ID_ATIVIDADE WHERE rl2.ID_PARTICIPANTE = p.ID_PARTICIPANTE AND a2.DT_ATIVIDADE <= CURRENT_DATE AND rl2.IS_CERTIFICADO = 'N') as total_pendentes_participante, RANK() OVER (PARTITION BY a.ID_ATIVIDADE ORDER BY p.TP_PARTICIPACAO DESC) as prioridade_emissao FROM TB_PARTICIPANTE p JOIN RL_PARTICIPA rl ON p.ID_PARTICIPANTE = rl.ID_PARTICIPANTE JOIN TB_ATIVIDADE a ON rl.ID_ATIVIDADE = a.ID_ATIVIDADE WHERE a.DT_ATIVIDADE <= CURRENT_DATE AND rl.IS_CERTIFICADO = 'N' ORDER BY a.DT_ATIVIDADE, p.NM_ULTIMO, p.NM_PRIMEIRO;"),
    # A5: Dashboard de Atividades por Status e Tipo (R. 1.3)
    ("avanc_05", "WITH status_atividade AS ( SELECT a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.TP_ATIVIDADE, a.NM_AREA_ESTUDO, CASE WHEN a.DT_ATIVIDADE > CURRENT_DATE THEN 'AGENDADA' WHEN a.DT_ATIVIDADE = CURRENT_DATE THEN 'EM ANDAMENTO' ELSE 'REALIZADA' END as status_atividade, COUNT(DISTINCT rl.ID_PARTICIPANTE) as total_participantes, COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) as instrutores, COUNT(DISTINCT par.ID_PARCEIRO) as parceiros, COUNT(DISTINCT CASE WHEN rl.IS_CERTIFICADO = 'S' THEN rl.ID_PARTICIPANTE END) as certificados_emitidos, (SELECT AVG(part_count) FROM (SELECT COUNT(DISTINCT rl2.ID_PARTICIPANTE) as part_count FROM TB_ATIVIDADE a2 JOIN RL_PARTICIPA rl2 ON a2.ID_ATIVIDADE = rl2.ID_ATIVIDADE WHERE a2.TP_ATIVIDADE = a.TP_ATIVIDADE GROUP BY a2.ID_ATIVIDADE) as sub) as media_geral_tipo FROM TB_ATIVIDADE a LEFT JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE LEFT JOIN TB_PARTICIPANTE p ON rl.ID_PARTICIPANTE = p.ID_PARTICIPANTE LEFT JOIN TB_PARCEIRO par ON a.ID_ATIVIDADE = par.ID_ATIVIDADE GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.TP_ATIVIDADE, a.NM_AREA_ESTUDO) SELECT status_atividade, TP_ATIVIDADE, COUNT(*) as quantidade_atividades, SUM(total_participantes) as total_participantes, AVG(total_participantes) as media_participantes, RANK() OVER (PARTITION BY status_atividade ORDER BY SUM(total_participantes) DESC) as ranking_participacao, SUM(instrutores) as total_instrutores, SUM(parceiros) as total_parceiros, SUM(certificados_emitidos) as total_certificados, AVG(media_geral_tipo) as media_geral_tipo_atividade FROM status_atividade GROUP BY status_atividade, TP_ATIVIDADE ORDER BY CASE status_atividade WHEN 'AGENDADA' THEN 1 WHEN 'EM ANDAMENTO' THEN 2 ELSE 3 END, TP_ATIVIDADE;"),
    # A6: Análise de Feedback e Satisfação por Área de Estudo (R. 1.6)
    ("avanc_06", "SELECT a.TP_ATIVIDADE, CASE WHEN a.TP_ATIVIDADE = 'E' THEN 'Evento' WHEN a.TP_ATIVIDADE = 'P' THEN 'Palestra' WHEN a.TP_ATIVIDADE = 'W' THEN 'Workshop' WHEN a.TP_ATIVIDADE = 'C' THEN 'Curso' ELSE 'Outros' END as descricao_tipo, a.NM_AREA_ESTUDO, COUNT(rl.ID_PARTICIPANTE) as total_participantes, COUNT(rl.DS_FEEDBACK) as feedbacks_recebidos, ROUND((COUNT(rl.DS_FEEDBACK) * 100.0 / COUNT(rl.ID_PARTICIPANTE)), 2) as taxa_resposta, (SELECT ROUND(AVG(feedback_rate), 2) FROM (SELECT a2.NM_AREA_ESTUDO, (COUNT(rl2.DS_FEEDBACK) * 100.0 / COUNT(rl2.ID_PARTICIPANTE)) as feedback_rate FROM TB_ATIVIDADE a2 JOIN RL_PARTICIPA rl2 ON a2.ID_ATIVIDADE = rl2.ID_ATIVIDADE GROUP BY a2.NM_AREA_ESTUDO) as sub WHERE sub.NM_AREA_ESTUDO = a.NM_AREA_ESTUDO) as taxa_media_area, AVG(LENGTH(rl.DS_FEEDBACK)) as media_tamanho_feedback, COUNT(CASE WHEN LENGTH(rl.DS_FEEDBACK) > 50 THEN 1 END) as feedbacks_detalhados, RANK() OVER (ORDER BY (COUNT(rl.DS_FEEDBACK) * 100.0 / COUNT(rl.ID_PARTICIPANTE)) DESC) as ranking_satisfacao FROM TB_ATIVIDADE a JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE JOIN TB_PARTICIPANTE p ON rl.ID_PARTICIPANTE = p.ID_PARTICIPANTE WHERE rl.DS_FEEDBACK IS NOT NULL GROUP BY a.TP_ATIVIDADE, a.NM_AREA_ESTUDO HAVING COUNT(rl.ID_PARTICIPANTE) >= 5 ORDER BY taxa_resposta DESC, total_participantes DESC;"),
    # A7: Relatório de Participação por Instituição e Área de Estudo (R. 1.6)
    ("avanc_07", "SELECT p.NM_INSTITUICAO, a.NM_AREA_ESTUDO, COUNT(DISTINCT p.ID_PARTICIPANTE) as total_participantes_unicos, COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades_participadas, SUM(a.CARGA_HORARIA) as carga_horaria_total, COUNT(DISTINCT p.ID_PARTICIPANTE) FILTER (WHERE p.TP_PARTICIPACAO = 'I') as instrutores, COUNT(DISTINCT p.ID_PARTICIPANTE) FILTER (WHERE p.TP_PARTICIPACAO = 'M') as monitores, COUNT(DISTINCT p.ID_PARTICIPANTE) FILTER (WHERE p.TP_PARTICIPACAO = 'O') as ouvintes, ROUND(CAST(COUNT(*) AS DECIMAL) / COUNT(DISTINCT p.ID_PARTICIPANTE), 2) as media_atividades_por_participante, (SELECT COUNT(DISTINCT p2.NM_INSTITUICAO) FROM TB_PARTICIPANTE p2 JOIN RL_PARTICIPA rl2 ON p2.ID_PARTICIPANTE = rl2.ID_PARTICIPANTE JOIN TB_ATIVIDADE a2 ON rl2.ID_ATIVIDADE = a2.ID_ATIVIDADE WHERE a2.NM_AREA_ESTUDO = a.NM_AREA_ESTUDO AND p2.NM_INSTITUICAO IS NOT NULL) as total_instituicoes_area, RANK() OVER (PARTITION BY a.NM_AREA_ESTUDO ORDER BY COUNT(DISTINCT p.ID_PARTICIPANTE) DESC) as ranking_instituicao_area FROM TB_PARTICIPANTE p JOIN RL_PARTICIPA rl ON p.ID_PARTICIPANTE = rl.ID_PARTICIPANTE JOIN TB_ATIVIDADE a ON rl.ID_ATIVIDADE = a.ID_ATIVIDADE WHERE p.NM_INSTITUICAO IS NOT NULL GROUP BY p.NM_INSTITUICAO, a.NM_AREA_ESTUDO HAVING COUNT(DISTINCT p.ID_PARTICIPANTE) >= 3 ORDER BY p.NM_INSTITUICAO, total_participantes_unicos DESC;"),
    # A8: Gestão de Cronograma e Alocação de Recursos Futuros (R. 1.1)
    ("avanc_08", "SELECT a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.HR_ATIVIDADE, a.DS_LOCAL, a.TP_ATIVIDADE, a.NM_AREA_ESTUDO, a.CARGA_HORARIA, COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) as instrutores_alocados, COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'M' THEN p.ID_PARTICIPANTE END) as monitores_alocados, COUNT(DISTINCT par.ID_PARCEIRO) as parceiros_envolvidos, COUNT(DISTINCT rl.ID_PARTICIPANTE) as participantes_confirmados, (SELECT ROUND(AVG(part_count), 2) FROM (SELECT COUNT(DISTINCT rl2.ID_PARTICIPANTE) as part_count FROM TB_ATIVIDADE a2 JOIN RL_PARTICIPA rl2 ON a2.ID_ATIVIDADE = rl2.ID_ATIVIDADE WHERE a2.TP_ATIVIDADE = a.TP_ATIVIDADE AND a2.DT_ATIVIDADE < CURRENT_DATE GROUP BY a2.ID_ATIVIDADE) as sub) as media_historica_participantes, RANK() OVER (ORDER BY COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) DESC) as ranking_instrutores, CASE WHEN COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) = 0 THEN 'SEM INSTRUTOR' WHEN COUNT(DISTINCT CASE WHEN p.TP_PARTICIPACAO = 'I' THEN p.ID_PARTICIPANTE END) = 1 THEN 'INSTRUTOR ÚNICO' ELSE 'MÚLTIPLOS INSTRUTORES' END as status_alocacao_instrutores FROM TB_ATIVIDADE a LEFT JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE LEFT JOIN TB_PARTICIPANTE p ON rl.ID_PARTICIPANTE = p.ID_PARTICIPANTE LEFT JOIN TB_PARCEIRO par ON a.ID_ATIVIDADE = par.ID_ATIVIDADE WHERE a.DT_ATIVIDADE >= CURRENT_DATE GROUP BY a.ID_ATIVIDADE, a.NM_ATIVIDADE, a.DT_ATIVIDADE, a.HR_ATIVIDADE, a.DS_LOCAL, a.TP_ATIVIDADE, a.NM_AREA_ESTUDO, a.CARGA_HORARIA ORDER BY a.DT_ATIVIDADE, a.HR_ATIVIDADE;"),
    # A9: Análise de Eficiência por Tipo de Parceria e Impacto (R. 1.5)
    ("avanc_09", "SELECT par.TP_CATEGORIA, CASE WHEN par.TP_CATEGORIA = 'F' THEN 'Financeiro' WHEN par.TP_CATEGORIA = 'P' THEN 'Palestrante' WHEN par.TP_CATEGORIA = 'M' THEN 'Material' ELSE 'Outro' END as descricao_categoria, COUNT(DISTINCT par.ID_PARCEIRO) as total_parceiros, COUNT(DISTINCT par.ID_ATIVIDADE) as total_atividades_apoiadas, COUNT(DISTINCT rl.ID_PARTICIPANTE) as total_participantes_impactados, SUM(a.CARGA_HORARIA) as carga_horaria_total, ROUND(AVG(COUNT(DISTINCT rl.ID_PARTICIPANTE)) OVER (PARTITION BY par.TP_CATEGORIA), 2) as media_participantes_por_parceiro, (SELECT ROUND(AVG(part_count) * 1.1, 0) FROM (SELECT COUNT(DISTINCT rl2.ID_PARTICIPANTE) as part_count FROM TB_PARCEIRO par2 JOIN TB_ATIVIDADE a2 ON par2.ID_ATIVIDADE = a2.ID_ATIVIDADE JOIN RL_PARTICIPA rl2 ON a2.ID_ATIVIDADE = rl2.ID_ATIVIDADE WHERE par2.TP_CATEGORIA = par.TP_CATEGORIA GROUP BY par2.ID_PARCEIRO) as sub) as participantes_ideais, RANK() OVER (ORDER BY COUNT(DISTINCT rl.ID_PARTICIPANTE) DESC) as ranking_impacto_geral, ROUND((COUNT(DISTINCT rl.ID_PARTICIPANTE) * 100.0 / SUM(COUNT(DISTINCT rl.ID_PARTICIPANTE)) OVER ()), 2) as percentual_impacto_total FROM TB_PARCEIRO par JOIN TB_ATIVIDADE a ON par.ID_ATIVIDADE = a.ID_ATIVIDADE LEFT JOIN RL_PARTICIPA rl ON a.ID_ATIVIDADE = rl.ID_ATIVIDADE GROUP BY par.TP_CATEGORIA ORDER BY total_participantes_impactados DESC;"),
    # A10: Relatório Consolidado de Métricas para Diretoria (R. 1.6)
    ("avanc_10", "WITH metricas_consolidadas AS ( SELECT (SELECT COUNT(*) FROM TB_ATIVIDADE) as total_atividades, (SELECT COUNT(*) FROM TB_PARTICIPANTE) as total_participantes, (SELECT COUNT(*) FROM TB_PARCEIRO) as total_parceiros, (SELECT COUNT(*) FROM RL_PARTICIPA) as total_participacoes, (SELECT COUNT(*) FROM TB_ATIVIDADE WHERE TP_ATIVIDADE = 'E') as eventos, (SELECT COUNT(*) FROM TB_ATIVIDADE WHERE TP_ATIVIDADE = 'P') as palestras, (SELECT COUNT(*) FROM TB_ATIVIDADE WHERE TP_ATIVIDADE = 'W') as workshops, (SELECT COUNT(*) FROM TB_ATIVIDADE WHERE TP_ATIVIDADE = 'C') as cursos, (SELECT COUNT(*) FROM RL_PARTICIPA WHERE IS_CERTIFICADO = 'S') as certificados_emitidos, (SELECT COUNT(*) FROM RL_PARTICIPA WHERE DS_FEEDBACK IS NOT NULL) as feedbacks_recebidos ), analise_detalhada AS ( SELECT m.*, (SELECT AVG(a.CARGA_HORARIA) FROM TB_ATIVIDADE a) as carga_horaria_media, (SELECT COUNT(DISTINCT a.NM_AREA_ESTUDO) FROM TB_ATIVIDADE a) as areas_estudo_unicas, RANK() OVER (ORDER BY m.total_participacoes DESC) as dummy_rank, (SELECT COUNT(*) FROM (SELECT COUNT(rl.ID_PARTICIPANTE) FROM RL_PARTICIPA rl JOIN TB_ATIVIDADE a ON rl.ID_ATIVIDADE = a.ID_ATIVIDADE GROUP BY a.TP_ATIVIDADE) as sub) as grupos_tipo_atividade, ROUND((m.certificados_emitidos * 100.0 / m.total_participacoes), 2) as taxa_certificacao, ROUND((m.feedbacks_recebidos * 100.0 / m.total_participacoes), 2) as taxa_feedback FROM metricas_consolidadas m) SELECT total_atividades, total_participantes, total_parceiros, total_participacoes, eventos, palestras, workshops, cursos, certificados_emitidos, feedbacks_recebidos, carga_horaria_media, areas_estudo_unicas, taxa_certificacao, taxa_feedback, ROW_NUMBER() OVER (ORDER BY total_participacoes DESC) as exemplo_window FROM analise_detalhada;"),
    # A11: Quantidade de Participantes por Tipo de Atividade (R. 4 e 7)
    ("avanc_11", "SELECT a.tp_atividade, COUNT(DISTINCT p.id_participante) AS total_participantes, ROUND(AVG(a.carga_horaria), 2) AS media_carga_horaria FROM tb_atividade a JOIN rl_participa r ON a.id_atividade = r.id_atividade JOIN tb_participante p ON r.id_participante = p.id_participante GROUP BY a.tp_atividade ORDER BY total_participantes DESC;"),
    # A12: Atividades com Maior Número de Certificados Emitidos (R. 3 e 4)
    ("avanc_12", "SELECT a.nm_atividade, COUNT(*) AS certificados_emitidos FROM rl_participa r JOIN tb_atividade a ON a.id_atividade = r.id_atividade JOIN tb_participante p ON r.id_participante = p.id_participante WHERE r.is_certificado = 'S' GROUP BY a.nm_atividade ORDER BY certificados_emitidos DESC;"),
    # A13: Ranking de Participantes por Total de Atividades (R. 2)
    ("avanc_13", "SELECT p.nm_primeiro || ' ' || p.nm_ultimo AS nome_participante, COUNT(r.id_atividade) AS total_atividades, RANK() OVER (ORDER BY COUNT(r.id_atividade) DESC) AS posicao FROM tb_participante p JOIN rl_participa r ON p.id_participante = r.id_participante JOIN tb_atividade a ON r.id_atividade = a.id_atividade GROUP BY p.id_participante, p.nm_primeiro, p.nm_ultimo;"),
    # A14: Ranking de Parceiros Mais Frequentes nas Atividades (R. 5)
    ("avanc_14", "SELECT pr.nm_empresa, COUNT(DISTINCT pr.id_atividade) AS qtd_atividades, DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT pr.id_atividade) DESC) AS ranking FROM tb_parceiro pr JOIN tb_atividade a ON pr.id_atividade = a.id_atividade JOIN rl_participa r ON a.id_atividade = r.id_atividade GROUP BY pr.nm_empresa;"),
    # A15: Média de Tamanho de Feedback por Tipo de Atividade (R. 3)
    ("avanc_15", "SELECT a.tp_atividade, COUNT(r.ds_feedback) AS total_feedbacks, ROUND(AVG(LENGTH(r.ds_feedback)), 2) AS media_tamanho_feedback FROM rl_participa r JOIN tb_atividade a ON r.id_atividade = a.id_atividade JOIN tb_participante p ON r.id_participante = p.id_participante GROUP BY a.tp_atividade;"),
    # A16: Subconsulta - Participantes com Mais de 3 Certificados (R. 2 e 3)
    ("avanc_16", "SELECT p.nm_primeiro || ' ' || p.nm_ultimo AS nome_participante, total_certificados FROM ( SELECT r.id_participante, COUNT(*) AS total_certificados FROM rl_participa r JOIN tb_atividade a ON r.id_atividade = a.id_atividade WHERE r.is_certificado = 'S' GROUP BY r.id_participante ) sub JOIN tb_participante p ON p.id_participante = sub.id_participante WHERE total_certificados > 3 ORDER BY total_certificados DESC;"),
    # A17: Tempo Médio de Atividades por Área de Estudo com Filtro (R. 4)
    ("avanc_17", "SELECT a.nm_area_estudo, ROUND(AVG(a.carga_horaria), 2) AS media_carga, COUNT(DISTINCT a.id_atividade) AS qtd_atividades, RANK() OVER (ORDER BY ROUND(AVG(a.carga_horaria), 2) DESC) as ranking_carga FROM tb_atividade a JOIN rl_participa r ON a.id_atividade = r.id_atividade JOIN tb_parceiro pr ON a.id_atividade = pr.id_atividade GROUP BY a.nm_area_estudo HAVING COUNT(DISTINCT a.id_atividade) > 2;"),
    # A18: Correlação entre Instituições Participantes e Empresas Parceiras (R. 1 e 5)
    ("avanc_18", "SELECT p.nm_instituicao, COUNT(DISTINCT pr.nm_empresa) AS total_empresas_parceiras, COUNT(DISTINCT r.id_participante) AS total_participantes FROM tb_participante p JOIN rl_participa r ON p.id_participante = r.id_participante JOIN tb_atividade a ON r.id_atividade = a.id_atividade JOIN tb_parceiro pr ON pr.id_atividade = a.id_atividade GROUP BY p.nm_instituicao ORDER BY total_empresas_parceiras DESC;"),
    # A19: Ranking de Atividades com Maior Número de Feedbacks (R. 7)
    ("avanc_19", "SELECT a.nm_atividade, COUNT(r.ds_feedback) AS total_feedbacks, ROW_NUMBER() OVER (ORDER BY COUNT(r.ds_feedback) DESC) AS ranking_feedback FROM tb_atividade a JOIN rl_participa r ON a.id_atividade = r.id_atividade JOIN tb_participante p ON r.id_participante = p.id_participante GROUP BY a.id_atividade, a.nm_atividade;"),
    # A20: Subconsulta - Instituições com Maior Média de Certificados (R. 4 e 7)
    ("avanc_20", "SELECT p.nm_instituicao, ROUND(AVG(sub.total_certificados), 2) AS media_certificados FROM ( SELECT r.id_participante, COUNT(*) AS total_certificados FROM rl_participa r JOIN tb_atividade a ON r.id_atividade = a.id_atividade WHERE r.is_certificado = 'S' GROUP BY r.id_participante ) sub JOIN tb_participante p ON p.id_participante = sub.id_participante GROUP BY p.nm_instituicao ORDER BY media_certificados DESC;")
]


#  Planos de indexação

planos = {
    "baseline": [
        "DROP INDEX IF EXISTS idx_participa_hash_id_ativ;",
        "DROP INDEX IF EXISTS idx_participa_hash_id_part;",
        "DROP INDEX IF EXISTS idx_participante_hash;",
        "DROP INDEX IF EXISTS idx_atividade_hash;",
        "DROP INDEX IF EXISTS idx_participante_tp_btree;",
        "DROP INDEX IF EXISTS idx_atividade_data_btree;",
        "DROP INDEX IF EXISTS idx_parceiro_atividade_btree;",
        "DROP INDEX IF EXISTS idx_participa_certificado_btree;"
    ],
    "plano1": [
        "DROP INDEX IF EXISTS idx_participa_hash_id_ativ;",
        "DROP INDEX IF EXISTS idx_participa_hash_id_part;",
        "DROP INDEX IF EXISTS idx_participante_hash;",
        "DROP INDEX IF EXISTS idx_atividade_hash;",
        "DROP INDEX IF EXISTS idx_participante_tp_btree;",
        "DROP INDEX IF EXISTS idx_atividade_data_btree;",
        "DROP INDEX IF EXISTS idx_parceiro_atividade_btree;",
        "DROP INDEX IF EXISTS idx_participa_certificado_btree;",

        
        "CREATE INDEX idx_participa_hash_id_ativ ON rl_participa USING hash (id_atividade);",
        "CREATE INDEX idx_participa_hash_id_part ON rl_participa USING hash (id_participante);",
        
       
        "CREATE INDEX idx_participante_hash ON tb_participante USING hash (id_participante);",
        "CREATE INDEX idx_atividade_hash ON tb_atividade USING hash (id_atividade);",
       
       
        "CREATE INDEX idx_participante_tp_btree ON tb_participante(tp_participacao);",
        "CREATE INDEX idx_atividade_data_btree ON tb_atividade(dt_atividade);"
    ],
    "plano2": [
        # DROP INDEXES
        "DROP INDEX IF EXISTS idx_participa_btree;",
        "DROP INDEX IF EXISTS idx_parceiro_atividade_btree;",
        "DROP INDEX IF EXISTS idx_participante_tp_btree;",
        "DROP INDEX IF EXISTS idx_participa_certificado_btree;",

        
        "CREATE INDEX idx_participa_btree ON rl_participa(id_atividade, id_participante);",
        "CREATE INDEX idx_parceiro_atividade_btree ON tb_parceiro(id_atividade);",
        "CREATE INDEX idx_participante_tp_btree ON tb_participante(tp_participacao);",
        "CREATE INDEX idx_participa_certificado_btree ON rl_participa(is_certificado);"
    ]
}


# Armazenamento dos resultados

resultados = []


# Loop principal

for nome_plano, comandos in planos.items():
    print(f"\n🧩 Testando consultas com {nome_plano}")

    # aplica ou remove índices conforme o plano
    for cmd in comandos:
        cur.execute(cmd)
    conn.commit()

    # junta intermediárias e avançadas em uma lista só
    consultas = consultas_intermediarias + consultas_avancadas

    for nome_consulta, sql in consultas:
        for i in range(1, 21):  # 20 repetições
            start = time.perf_counter()
            cur.execute(sql)
            _ = cur.fetchall()  # força execução completa
            end = time.perf_counter()
            tempo = end - start

            resultados.append((nome_consulta, nome_plano, i, tempo))
            print(f"{nome_consulta} | {nome_plano} | tentativa {i}: {tempo:.4f}s")


# Salva e mostra resultados

df = pd.DataFrame(resultados, columns=["consulta", "plano", "tentativa", "tempo"])
df.to_csv("resultados_tempo.csv", index=False)

print("\n📊 Estatísticas (média e desvio padrão):")
print(df.groupby(["consulta", "plano"])["tempo"].agg(["mean", "std"]))

cur.close()
conn.close()
