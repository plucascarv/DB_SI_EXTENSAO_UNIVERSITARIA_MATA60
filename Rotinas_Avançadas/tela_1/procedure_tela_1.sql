CREATE OR REPLACE PROCEDURE sp_cadastrar_atividade_parceria(
  -- Parâmetros da Atividade
  p_id_atividade INT,
  p_dt_atividade DATE,
  p_hr_atividade TIME,
  p_ds_local VARCHAR,
  p_tp_atividade CHAR,
  p_nm_area_estudo VARCHAR,
  p_nm_atividade VARCHAR,
  p_carga_horaria INT,
  p_ds_atividade VARCHAR,
  -- Parâmetros do Parceiro
  p_id_parceiro INT DEFAULT NULL,
  p_nm_primeiro VARCHAR DEFAULT NULL,
  p_nm_ultimo VARCHAR DEFAULT NULL,
  p_nm_empresa VARCHAR DEFAULT NULL,
  p_tp_categoria CHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_existe INT;
BEGIN
  SELECT COUNT(*) INTO v_existe FROM TB_ATIVIDADE WHERE ID_ATIVIDADE = p_id_atividade
  IF v_existe > 0 THEN
    RAISE EXCEPTION 'Já existe atividade com o ID fornecido.', p_id_atividade;
  END IF;

  INSERT INTO TB_ATIVIDADE (
    ID_ATIVIDADE, DT_ATIVIDADE, HR_ATIVIDADE, DS_LOCAL, TP_ATIVIDADE, NM_AREA_ESTUDO, NM_ATIVIDADE, CARGA_HORARIA, DS_ATIVIDADE
  ) VALUES (
    p_id_atividade, p_dt_atividade, p_hr_atividade, p_ds_local, p_tp_atividade, p_nm_area_estudo, p_nm_atividade, p_carga_horaria, p_ds_atividade
  );

  UPDATE TB_ATIVIDADE SET NM_ATIVIDADE = UPPER(NM_ATIVIDADE) WHERE ID_ATIVIDADE = p_id_atividade;

  IF p_id_parceiro IS NOT NULL THEN
    INSERT INTO TB_PARCEIRO (
      ID_PARCEIRO, NM_PRIMEIRO, NM_ULTIMO, NM_EMPRESA, TP_CATEGORIA, ID_ATIVIDADE
    ) VALUES (
      p_id_parceiro, p_nm_primeiro, p_nm_ultimo, p_nm_empresa, p_tp_categoria, p_id_atividade
    );

    UPDATE TB_PARCEIRO SET NM_EMPRESA = UPPER(NM_EMPRESA) WHERE ID_PARCEIRO = p_id_parceiro;
  END IF;

  RAISE NOTICE "Cadastro realizado com sucesso.";
END;
$$;