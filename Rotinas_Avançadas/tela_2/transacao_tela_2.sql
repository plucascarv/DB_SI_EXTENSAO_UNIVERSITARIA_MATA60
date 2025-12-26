-- [Comando DELETE 1]: Remoção de participações inválidas ou negadas pelo administrador
-- Utilizado quando a inscrição não atende aos critérios mínimos de presença
DELETE FROM rl_participa 
WHERE id_participante = 10 
  AND id_atividade = 5 
  AND is_certificado = 'N';