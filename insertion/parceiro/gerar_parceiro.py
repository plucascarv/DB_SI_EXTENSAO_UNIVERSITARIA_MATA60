import random

TOTAL_ENTRADAS = 265
TOTAL_ATIVIDADES = 450
PRIMEIROS_NOMES = [
  'Ana', 'Bruno', 'Carla', 'Daniel', 'Elisa', 'Fábio', 'Gabriela', 'Hugo', 'Isabela', 'Juliano', 'Beatriz', 'Caio', 'Diana', 'Eduardo', 'Fernanda', 'Gustavo', 'Heloísa', 'Igor', 'Júlia', 'Leonardo'
]
NOMES_MEIO_E_ULTIMOS = [
  'Andrade', 'Barros', 'Campos', 'Dias', 'Esteves', 'Fernandes', 'Gusmão', 'Henriques', 'Ibrahim', 'Junqueira', 'Alves', 'Pereira', 'Carvalho', 'Ribeiro', 'Gomes', 'Martins', 'Rocha', 'Barbosa', 'Mendes', 'Nunes'
]
PREFIXOS_EMPRESA = [
  'Global', 'Tech', 'Inova', 'Alpha', 'Nexus', 'Future', 'Quantum', 'Data', 'Apex', 'Horizon', 'Vertice', 'Cyber', 'Pinnacle', 'Stellar', 'Axiom'
]
SUFIXOS_EMPRESA = [
  'Soluções', 'Tecnologia', 'Sistemas', 'Consultoria', 'Inovação', 'Labs', 'Digital', 'Group', 'Partners', 'Logistics', 'S.A.', 'Enterprises', 'LTDA', 'Analytics', 'Security'
]
CATEGORIAS = ['F', 'P', 'M', 'O']

def gerar_cpf_unico(cpfs_gerados_set):
  while True:
    cpf = ''.join([str(random.randint(0, 9)) for _ in range(11)])
    if cpf not in cpfs_gerados_set:
      cpfs_gerados_set.add(cpf)
      return cpf

def gerar_script_sql():
  linhas_sql = []
  cpfs_usados = set()
    
  with open('inserts_parceiros.sql', 'w', encoding='utf-8') as f:
    f.write("INSERT INTO TB_PARCEIRO (ID_PARCEIRO, NM_PRIMEIRO, NM_MEIO, NM_ULTIMO, CD_CPF_REPRESENTANTE, NM_EMPRESA, TP_CATEGORIA, ID_ATIVIDADE) VALUES\n")
        
    for i in range(1, TOTAL_ENTRADAS + 1):
      id_parceiro = i
      nm_primeiro = random.choice(PRIMEIROS_NOMES)
      nm_meio = f"'{random.choice(NOMES_MEIO_E_ULTIMOS)}'" if random.random() < 0.3 else 'NULL'
      nm_ultimo = random.choice(NOMES_MEIO_E_ULTIMOS)
      cpf = gerar_cpf_unico(cpfs_usados)
      nm_empresa = f"'{random.choice(PREFIXOS_EMPRESA)} {random.choice(SUFIXOS_EMPRESA)}'"
      tp_categoria = f"'{random.choice(CATEGORIAS)}'"
      id_atividade = random.randint(1, TOTAL_ATIVIDADES)
            
      linha = (
        f"({id_parceiro}, '{nm_primeiro}', {nm_meio}, '{nm_ultimo}', '{cpf}', "
        f"{nm_empresa}, {tp_categoria}, {id_atividade})"
      )
      linhas_sql.append(linha)
            
    f.write(',\n'.join(linhas_sql))
    f.write(';\n')
        
    print(f"Arquivo 'inserts_parceiros.sql' com {len(linhas_sql)} linhas foi gerado.")

if __name__ == "__main__":
    gerar_script_sql()