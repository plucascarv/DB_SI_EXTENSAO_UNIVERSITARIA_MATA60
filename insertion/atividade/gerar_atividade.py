import random
from datetime import date, time, timedelta

LOCAIS = [
  'Auditório Principal - Prédio A', 'Laboratório de Informática 303', 'Sala de Conferências B-201',
  'Plataforma Zoom (Online)', 'Google Meet (Híbrido)', 'Salão Nobre da Reitoria',
  'Pátio Central (Evento ao ar livre)', 'Sala 105 - Bloco de Aulas', 'Biblioteca Central - Sala de Estudos'
]
AREAS_ESTUDO = [
  'Computação', 'Redes de Computadores', 'Filosofia', 'Matemática', 'Engenharia de Software',
  'Sistemas Operacionais', 'Gestão de Projetos', 'Inteligência Artificial', 'Saúde e Bem-estar',
  'Design Gráfico', 'Administração', 'Direito', 'Internet das Coisas', 'Lógica de Programação'
]
ATIVIDADE_INFO = {
  'E': {
    'nomes': ['Simpósio de', 'Semana Acadêmica de', 'Congresso de', 'Feira de Tecnologia em'],
    'descricoes': ['Um grande evento reunindo especialistas, estudantes e empresas da área de', 'Evento com múltiplas palestras e atividades sobre os avanços em'],
    'cargas_horarias': [8, 16, 24, 40]
  },
  'P': {
    'nomes': ['Palestra: O Futuro da', 'Palestra: Tópicos Emergentes em', 'Apresentação sobre', 'Debate: Os Desafios da'],
    'descricoes': ['Apresentação de 1 a 2 horas sobre um tema específico em', 'Palestra com especialista renomado para discutir as tendências em'],
    'cargas_horarias': [1, 2, 3]
  },
  'W': {
    'nomes': ['Workshop Prático de', 'Oficina de', 'Treinamento Intensivo em', 'Workshop: Ferramentas para'],
    'descricoes': ['Atividade prática e "mão na massa" para desenvolvimento de habilidades em', 'Treinamento focado em uma ferramenta ou metodologia específica de'],
    'cargas_horarias': [4, 6, 8]
  },
  'C': {
    'nomes': ['Curso de Extensão em', 'Curso Completo de', 'Fundamentos de', 'Curso de Aperfeiçoamento em'],
    'descricoes': ['Curso de longa duração com certificado para capacitação profissional em', 'Módulos de aprendizado cobrindo os fundamentos e tópicos avançados de'],
    'cargas_horarias': [16, 20, 40, 60]
  },
  'O': {
    'nomes': ['Encontro do Grupo de Estudos em', 'Mesa Redonda sobre', 'Visita Técnica a', 'Maratona de Programação em'],
    'descricoes': ['Atividade complementar para a comunidade acadêmica focada em', 'Discussão aberta ou atividade de campo relacionada a'],
    'cargas_horarias': [2, 4, 8]
  }
}

def gerar_data_hora():
  start_date = date(2025, 1, 1)
  dias_aleatorios = random.randint(0, 364)
  dt_atividade = start_date + timedelta(days=dias_aleatorios) 
  hora = random.randint(8, 21)
  minuto = random.choice([0, 15, 30, 45])
  hr_atividade = time(hora, minuto, 0)
  return dt_atividade.strftime('%Y-%m-%d'), hr_atividade.strftime('%H:%M:%S')

def gerar_script_sql(num_linhas): 
  with open('inserts_atividades.sql', 'w', encoding='utf-8') as f:
    f.write("INSERT INTO TB_ATIVIDADE (ID_ATIVIDADE, DT_ATIVIDADE, HR_ATIVIDADE, DS_LOCAL, TP_ATIVIDADE, NM_AREA_ESTUDO, NM_ATIVIDADE, CARGA_HORARIA, DS_ATIVIDADE, DS_RELATORIO) VALUES\n")

    linhas_sql = []
    for i in range(1, num_linhas + 1):
      id_atividade = i
      dt_atividade, hr_atividade = gerar_data_hora()
      ds_local = random.choice(LOCAIS)
            
      tp_atividade = random.choice(['E', 'P', 'W', 'C', 'O'])
      nm_area_estudo = random.choice(AREAS_ESTUDO)
            
      info = ATIVIDADE_INFO[tp_atividade]
            
      nm_atividade = f"{random.choice(info['nomes'])} {nm_area_estudo}"
      carga_horaria = random.choice(info['cargas_horarias'])
      ds_atividade = f"{random.choice(info['descricoes'])} {nm_area_estudo}."
            
      ds_relatorio = (
        f"'Atividade concluída com sucesso. Participação de {random.randint(20, 150)} pessoas.'" 
        if random.random() < 0.25 
        else 'NULL'
      )

      linha = (
        f"({id_atividade}, '{dt_atividade}', '{hr_atividade}', '{ds_local}', '{tp_atividade}', "
        f"'{nm_area_estudo}', '{nm_atividade}', {carga_horaria}, '{ds_atividade}', {ds_relatorio})"
      )
      linhas_sql.append(linha)

      f.write(',\n'.join(linhas_sql))
      f.write(';\n')

  print(f"Arquivo 'inserts_atividades.sql' com {num_linhas} linhas foi gerado com sucesso!")

if __name__ == "__main__":
  gerar_script_sql(450)