-- Inserir Participantes (Ignora se o ID já existir)
INSERT INTO TB_PARTICIPANTE VALUES
(1, 'João', 'Silva', 'Santos', '12345678901', '1990-05-15', 'Rua A, 123', 'M', 'I', 'MAT001', 'UFABC'),
(2, 'Maria', 'Oliveira', 'Costa', '23456789012', '1992-08-20', 'Av B, 456', 'F', 'M', 'MAT002', 'USP'),
(3, 'Pedro', NULL, 'Lima', '34567890123', '1988-12-10', 'Rua C, 789', 'M', 'O', 'MAT003', 'UNIFESP')
ON CONFLICT (ID_PARTICIPANTE) DO NOTHING;

-- Inserir Atividades
INSERT INTO TB_ATIVIDADE VALUES
(1, '2024-03-15', '14:00:00', 'Auditório Principal', 'P', 'Tecnologia', 'IA Generativa', 4, 'Workshop sobre IA', NULL),
(2, '2024-03-20', '09:00:00', 'Sala 101', 'W', 'Gestão', 'Liderança', 8, 'Curso de liderança', NULL),
(3, '2024-04-01', '19:00:00', 'Auditório Secundário', 'E', 'Inovação', 'Startup Day', 6, 'Evento de startups', NULL)
ON CONFLICT (ID_ATIVIDADE) DO NOTHING;

-- Inserir Inscrições (Relacionamento)
INSERT INTO RL_PARTICIPA VALUES
(1, 1, 'S', 'Excelente workshop!'),
(2, 1, 'S', 'Muito bom conteúdo'),
(3, 1, 'N', NULL),
(1, 2, 'S', 'Curso muito útil')
ON CONFLICT (ID_PARTICIPANTE, ID_ATIVIDADE) DO NOTHING;

-- Inserir Parceiros
INSERT INTO TB_PARCEIRO VALUES
(1, 'Carlos', NULL, 'Empresário', '45678901234', 'Tech Solutions', 'F', 1),
(2, 'Ana', 'Maria', 'Consultora', '56789012345', 'Inova Consult', 'P', 1),
(3, 'Roberto', NULL, 'Gestor', '67890123456', 'Materiais SA', 'M', 2)
ON CONFLICT (ID_PARCEIRO) DO NOTHING;