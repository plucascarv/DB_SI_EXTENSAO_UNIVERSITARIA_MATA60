CREATE INDEX idx_participa_btree ON rl_participa(id_atividade, id_participante);
CREATE INDEX idx_parceiro_atividade_btree ON tb_parceiro(id_atividade);

CREATE INDEX idx_participante_tp_btree ON tb_participante(tp_participacao);
CREATE INDEX idx_participa_certificado_btree ON rl_participa(is_certificado)