CREATE INDEX idx_participa_hash_id_ativ ON rl_participa USING hash (id_atividade);
CREATE INDEX idx_participa_hash_id_part ON rl_participa USING hash (id_participante);
        
CREATE INDEX idx_participante_hash ON tb_participante USING hash (id_participante);
CREATE INDEX idx_atividade_hash ON tb_atividade USING hash (id_atividade);
       
CREATE INDEX idx_participante_tp_btree ON tb_participante(tp_participacao);
CREATE INDEX idx_atividade_data_btree ON tb_atividade(dt_atividade);