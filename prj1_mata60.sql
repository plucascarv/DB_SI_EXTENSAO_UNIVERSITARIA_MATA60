CREATE TABLE PARTICIPANTE(
  id_participante INT NOT NULL,
  primeiro_nome VARCHAR(50) NOT NULL,
  nome_meio VARCHAR(50),
  ultimo_nome VARCHAR(50) NOT NULL,
  cpf_participante CHAR(11) PRIMARY KEY,
  data_nascimento DATE,
  endereço VARCHAR(150),
  gênero CHAR(1),
  tipo_participação CHAR(1),
  matrícula VARCHAR(9),
  instituição VARCHAR(50)
);

CREATE TABLE ATIVIDADE (
  id_atividade INT PRIMARY KEY,
  data DATE NOT NULL,
  horário TIME NOT NULL,
  local VARCHAR(150) NOT NULL,
  tipo_atividade CHAR(1) NOT NULL,
  área_estudo VARCHAR(50) NOT NULL,
  nome_atividade VARCHAR(150) NOT NULL,
  carga_horária INT(2) NOT NULL,
  descrição VARCHAR(400) NOT NULL,
  relatório_atividade VARCHAR(400)
);

CREATE TABLE PARTICIPA (
  feedback VARCHAR(400),
  certificação CHAR(1),
  cpf_participante CHAR(11) PRIMARY KEY,
  id_atividade VARCHAR(150) NOT NULL,
  FOREIGN KEY (cpf_participante) REFERENCES PARTICIPANTE(cpf_participante),
  FOREIGN KEY (id_atividade) REFERENCES ATIVIDADE(id_atividade)
);

CREATE TABLE PARCEIRO (
  id_parceiro INT NOT NULL,
  primeiro_nome VARCHAR(50) NOT NULL,
  nome_meio VARCHAR(50),
  ultimo_nome VARCHAR(50) NOT NULL,
  cpf_representante VARCHAR(11) PRIMARY KEY,
  empresa VARCHAR(150) NOT NULL,
  categoria_parceiro CHAR(1) NOT NULL,
  id_atividade INT NOT NULL,
  FOREIGN KEY (id_atividade) REFERENCES ATIVIDADE(id_atividade)
);