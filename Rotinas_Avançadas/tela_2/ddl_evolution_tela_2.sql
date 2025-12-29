CREATE TABLE IF NOT EXISTS tb_log_validacao (
  id_log SERIAL PRIMARY KEY,
  id_participante INT,
  id_atividade INT,
  dt_validacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE tb_participante
ADD COLUMN IF NOT EXISTS dt_ultima_atualizacao TIMESTAMP;