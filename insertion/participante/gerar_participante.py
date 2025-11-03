import random
from datetime import date, timedelta

PRIMEIROS_NOMES = [
  'Miguel', 'Arthur', 'Gael', 'Heitor', 'Theo', 'Davi', 'Gabriel', 'Bernardo', 'Samuel', 'João', 'Helena', 'Alice', 'Laura', 'Maria', 'Valentina', 'Heloísa', 'Maria', 'Cecília', 'Júlia', 'Sophia', 'Lucas', 'Matheus', 'Guilherme', 'Pedro', 'Rafael', 'Felipe', 'Enzo', 'Nicolas', 'Leonardo', 'Eduardo', 'Mariana', 'Larissa', 'Beatriz', 'Isabela', 'Gabriela', 'Manuela', 'Luiza', 'Vitória', 'Camila', 'Amanda'
]
NOMES_DO_MEIO = [
  'Alves', 'Pereira', 'Carvalho', 'Ribeiro', 'Gomes', 'Martins', 'Rocha', 'Barbosa', 'Mendes', 'Nunes', 'Jesus', 'Barros', 'Campos', 'Cardoso', 'Teixeira', 'Moraes', 'Correia', 'Bezerra', 'Monteiro', 'Nascimento'
]
ULTIMOS_NOMES = [
  'Silva', 'Santos', 'Oliveira', 'Souza', 'Rodrigues', 'Ferreira', 'Almeida', 'Costa', 'Gomes', 'Martins', 'Araújo', 'Melo', 'Barbosa', 'Ramos', 'Cardoso', 'Lopes', 'Marques', 'Freitas', 'Castro', 'Moura'
]

INSTITUICOES = [
  'UFBA', 'UNEB', 'IFBA', 'UNIFACS', 'FTC', 'SENAI CIMATEC', 'UNIME', 'Estácio', 'UFRB', 'UESC', 'UESB'
]
TIPOS_LOGRADOURO = ['Rua', 'Avenida', 'Praça', 'Travessa', 'Alameda']
NOMES_LOGRADOURO = [
  'das Flores', 'Principal', 'da Saudade', 'dos Girassóis', 'Sete de Setembro', 'Tiradentes', 'do Comércio', 'São José', 'Nossa Senhora Aparecida', 'Dom Pedro II'
]
BAIRROS = [
  'Centro', 'Pituba', 'Itaigara', 'Graça', 'Barra', 'Rio Vermelho', 'Brotas', 'Cabula', 'Imbuí', 'Pernambués'
]

def gerar_cpf_unico(cpfs_gerados):
  while True:
    cpf = ''.join([str(random.randint(0, 9)) for _ in range(11)])
    if cpf not in cpfs_gerados:
      cpfs_gerados.add(cpf)
      return cpf

def gerar_matricula_unica(matriculas_geradas):
  while True:
    ano = random.choice(['2023', '2024', '2025'])
    semestre = str(random.randint(1, 2))
    tipo = random.choice(['A', 'B', 'C', 'D'])
    sufixo = str(random.randint(1, 999)).zfill(3)
    matricula = f"{ano}{semestre}{tipo}{sufixo}"
    if matricula not in matriculas_geradas:
      matriculas_geradas.add(matricula)
      return matricula

def gerar_data_nascimento():
  hoje = date.today()
  dias_atras = random.randint(18 * 365, 60 * 365)
  return hoje - timedelta(days=dias_atras)

def gerar_script_sql(num_linhas):
  cpfs_usados = set()
  matriculas_usadas = set()
  with open('inserts_participantes.sql', 'w', encoding='utf-8') as f:
    f.write("INSERT INTO TB_PARTICIPANTE (ID_PARTICIPANTE, NM_PRIMEIRO, NM_MEIO, NM_ULTIMO, CD_CPF_PARTICIPANTE, DT_NASCIMENTO, DS_ENDERECO, TP_GENERO, TP_PARTICIPACAO, CD_MATRICULA, NM_INSTITUICAO) VALUES\n")
    linhas_sql = []
    for i in range(1, num_linhas + 1):
      id_participante = i
      primeiro_nome = random.choice(PRIMEIROS_NOMES)
      nome_meio = f"'{random.choice(NOMES_DO_MEIO)}'" if random.random() < 0.3 else 'NULL'
      ultimo_nome = random.choice(ULTIMOS_NOMES)
      cpf = gerar_cpf_unico(cpfs_usados)
      dt_nascimento = gerar_data_nascimento().strftime('%Y-%m-%d')
      endereco = (
        f"{random.choice(TIPOS_LOGRADOURO)} {random.choice(NOMES_LOGRADOURO)}, "
        f"{random.randint(1, 1500)}, {random.choice(BAIRROS)}, Salvador - BA"
      )
      genero = random.choice(['M', 'F', 'O'])
      participacao = random.choice(['O', 'M', 'I']) # O-Ouvinte, M-Monitor, I-Instrutor
      matricula = gerar_matricula_unica(matriculas_usadas)
      instituicao = random.choice(INSTITUICOES)
      
      linha = (
        f"({id_participante}, '{primeiro_nome}', {nome_meio}, '{ultimo_nome}', '{cpf}', "
        f"'{dt_nascimento}', '{endereco}', '{genero}', '{participacao}', '{matricula}', '{instituicao}')"
      )
      linhas_sql.append(linha)

  f.write(',\n'.join(linhas_sql))
  f.write(';\n')
  print(f"Arquivo 'inserts_participantes.sql' com {num_linhas} linhas foi gerado com sucesso!")

if __name__ == "__main__":
    gerar_script_sql(5600)