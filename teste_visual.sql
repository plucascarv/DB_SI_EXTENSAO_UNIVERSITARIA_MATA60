-- Abra este arquivo e execute (Ctrl+Shift+P → SQLite: Run Query)
SELECT '🎉 O BANCO ESTÁ FUNCIONANDO!' as status;

-- Ver tabelas criadas
SELECT name FROM sqlite_master WHERE type='table';

-- Ver dados nas tabelas
SELECT * FROM TB_PARTICIPANTE;
SELECT * FROM TB_ATIVIDADE;