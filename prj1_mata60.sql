CREATE TABLE PARTICIPANTE(
  id_participante INT PRIMARY KEY,
  primeiro_nome VARCHAR(50) NOT NULL,
  nome_meio VARCHAR(50),
  ultimo_nome VARCHAR(50) NOT NULL,
  cpf_participante CHAR(11) UNIQUE,
  data_nascimento DATE,
  endereco VARCHAR(150),
  genero CHAR(1),
  tipo_participacao CHAR(1),
  matricula VARCHAR(9) UNIQUE,
  instituicao VARCHAR(50)
);

CREATE TABLE ATIVIDADE (
  id_atividade INT PRIMARY KEY,
  data_atividade DATE NOT NULL,
  horario TIME NOT NULL,
  local_atividade VARCHAR(150) NOT NULL,
  tipo_atividade CHAR(1) NOT NULL,
  area_estudo VARCHAR(50) NOT NULL,
  nome_atividade VARCHAR(150) NOT NULL,
  carga_horaria INT NOT NULL,
  descricao VARCHAR(400) NOT NULL,
  relatorio_atividade VARCHAR(400)
);

CREATE TABLE PARTICIPA (
  feedback VARCHAR(400),
  certificacao CHAR(1),
  id_participante INT,
  id_atividade INT,
  PRIMARY KEY (id_participante, id_atividade),
  FOREIGN KEY (id_participante) REFERENCES PARTICIPANTE(id_participante),
  FOREIGN KEY (id_atividade) REFERENCES ATIVIDADE(id_atividade)
);

CREATE TABLE PARCEIRO (
  id_parceiro INT PRIMARY KEY,
  primeiro_nome VARCHAR(50) NOT NULL,
  nome_meio VARCHAR(50),
  ultimo_nome VARCHAR(50) NOT NULL,
  cpf_representante VARCHAR(11) UNIQUE,
  empresa VARCHAR(150) NOT NULL,
  categoria_parceiro CHAR(1) NOT NULL,
  id_atividade INT NOT NULL,
  FOREIGN KEY (id_atividade) REFERENCES ATIVIDADE(id_atividade)
);