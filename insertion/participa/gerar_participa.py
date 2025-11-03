import random

TOTAL_PARTICIPANTES = 5600
TOTAL_ATIVIDADES = 450
TOTAL_INSCRICOES_DESEJADAS = 7512
FEEDBACKS_POSITIVOS = [
    'Ótima palestra, muito esclarecedora!',
    'Excelente workshop, aprendi muito.',
    'Organização impecável, parabéns!',
    'O conteúdo foi muito relevante para minha área.',
    'Palestrante com ótima didática.',
    'Gostei muito, mas poderia ser mais longo.',
    'Perfeito! Aguardando os próximos.',
    'Tema muito atual e necessário.'
]
FEEDBACKS_CONSTRUTIVOS = [
    'O áudio estava um pouco baixo.',
    'Gostaria de mais exemplos práticos.',
    'Achei o ritmo um pouco acelerado.',
    'A sala estava muito cheia, difícil de ver os slides.',
    'O material de apoio poderia ser disponibilizado antes.'
]

def gerar_linha_sql(id_p, id_a):
  is_certificado = "'S'" if random.random() < 0.8 else "'N'"
  ds_feedback = 'NULL'
  if is_certificado == "'S'":
    if random.random() < 0.3:
      if random.random() < 0.8:
        feedback = random.choice(FEEDBACKS_POSITIVOS)
      else:
        feedback = random.choice(FEEDBACKS_CONSTRUTIVOS)
    feedback_sql = feedback.replace("'", "''") 
    ds_feedback = f"'{feedback_sql}'"
    return f"({id_p}, {id_a}, {is_certificado}, {ds_feedback})"

def gerar_script_sql():
  participacoes_geradas = set()
  linhas_sql = []
    
  for id_p in range(1, TOTAL_PARTICIPANTES + 1):
    id_a = random.randint(1, TOTAL_ATIVIDADES)
    par = (id_p, id_a)
    participacoes_geradas.add(par)
    linhas_sql.append(gerar_linha_sql(id_p, id_a))

  tentativas = 0
  max_tentativas = TOTAL_INSCRICOES_DESEJADAS * 10 

  while len(participacoes_geradas) < TOTAL_INSCRICOES_DESEJADAS and tentativas < max_tentativas:
    id_p = random.randint(1, TOTAL_PARTICIPANTES)
    id_a = random.randint(1, TOTAL_ATIVIDADES) 
    par = (id_p, id_a)    
    if par not in participacoes_geradas:
      participacoes_geradas.add(par)
      linhas_sql.append(gerar_linha_sql(id_p, id_a))
    tentativas += 1

  with open('inserts_participa.sql', 'w', encoding='utf-8') as f:
    f.write("INSERT INTO RL_PARTICIPA (ID_PARTICIPANTE, ID_ATIVIDADE, IS_CERTIFICADO, DS_FEEDBACK) VALUES\n")
    f.write(',\n'.join(linhas_sql))
    f.write(';\n')

  print(f"Arquivo 'inserts_participa.sql' com {len(linhas_sql)} linhas foi gerado.")

if __name__ == "__main__":
    gerar_script_sql()