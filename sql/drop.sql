-- =====================================================================
-- Remove todas as tabelas do projeto (ordem das mais dependentes para
-- as menos dependentes), para a BD poder ser recriada do zero.
-- =====================================================================

DROP TABLE IF EXISTS consumo        CASCADE;
DROP TABLE IF EXISTS pagamento      CASCADE;
DROP TABLE IF EXISTS reserva_quarto CASCADE;
DROP TABLE IF EXISTS reserva        CASCADE;
DROP TABLE IF EXISTS servico        CASCADE;
DROP TABLE IF EXISTS quarto         CASCADE;
DROP TABLE IF EXISTS tipo_quarto    CASCADE;
DROP TABLE IF EXISTS funcionario    CASCADE;
DROP TABLE IF EXISTS cliente        CASCADE;