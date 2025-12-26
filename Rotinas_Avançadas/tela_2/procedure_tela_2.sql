-- Stored Procedure para processar a validação de participação
CREATE OR REPLACE PROCEDURE sp_validar_e_registrar(
    p_id_participante INT,
    p_id_atividade INT,
    p_feedback TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Início da Transação explícita para garantir preservação de dados
    
    -- [Comando INSERT 1]: Registra o histórico da operação de validação
    INSERT INTO tb_log_validacao (id_participante, id_atividade, dt_validacao)
    VALUES (p_id_participante, p_id_atividade, CURRENT_TIMESTAMP);

    -- [Comando UPDATE 1]: Altera o status da participação para validado ('S')
    UPDATE rl_participa 
    SET is_certificado = 'S', 
        ds_feedback = p_feedback
    WHERE id_participante = p_id_participante 
      AND id_atividade = p_id_atividade;

    -- [Comando UPDATE 2]: Atualiza o rastro de última atividade do usuário
    UPDATE tb_participante 
    SET dt_ultima_atualizacao = CURRENT_TIMESTAMP
    WHERE id_participante = p_id_participante;

    -- Finaliza e efetiva a transação no banco de dados
    COMMIT;
END;
$$;