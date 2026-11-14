-- Testes das restrições de servico, consumo e pagamento (Fase 2).
-- Cada teste corre numa transação desfeita (ROLLBACK): a BD fica como estava.
-- Os testes "deve falhar" mostram ERROR com o nome da restrição.

\set ON_ERROR_STOP off

\echo '--- T01 consumo válido (deve ser aceite)'
BEGIN;
INSERT INTO consumo (id_reserva, n_seq, quantidade, preco_unitario, id_servico) VALUES (4, 3, 1, 12.00, 2);
ROLLBACK;

\echo '--- T02 n_seq repetido na mesma reserva (deve falhar: pk_consumo)'
BEGIN;
INSERT INTO consumo (id_reserva, n_seq, quantidade, preco_unitario, id_servico) VALUES (4, 1, 1, 12.00, 2);
ROLLBACK;

\echo '--- T03 mesmo n_seq noutra reserva (deve ser aceite: chave parcial)'
BEGIN;
INSERT INTO consumo (id_reserva, n_seq, quantidade, preco_unitario, id_servico) VALUES (3, 1, 1, 12.00, 2);
ROLLBACK;

\echo '--- T04 quantidade 0 (deve falhar: ck_consumo_quantidade)'
BEGIN;
INSERT INTO consumo (id_reserva, n_seq, quantidade, preco_unitario, id_servico) VALUES (4, 3, 0, 12.00, 2);
ROLLBACK;

\echo '--- T05 consumo de reserva inexistente (deve falhar: fk_consumo_reserva)'
BEGIN;
INSERT INTO consumo (id_reserva, n_seq, quantidade, preco_unitario, id_servico) VALUES (999, 1, 1, 12.00, 2);
ROLLBACK;

\echo '--- T06 consumo de serviço inexistente (deve falhar: fk_consumo_servico)'
BEGIN;
INSERT INTO consumo (id_reserva, n_seq, quantidade, preco_unitario, id_servico) VALUES (4, 3, 1, 12.00, 999);
ROLLBACK;

\echo '--- T07 serviço com nome repetido (deve falhar: uq_servico_nome)'
BEGIN;
INSERT INTO servico (nome, preco_unitario) VALUES ('Lavandaria', 5.00);
ROLLBACK;

\echo '--- T08 serviço com preço 0 (deve falhar: ck_servico_preco)'
BEGIN;
INSERT INTO servico (nome, preco_unitario) VALUES ('Oferta', 0);
ROLLBACK;

\echo '--- T09 mudar o preço do serviço não altera consumos antigos (RN13)'
BEGIN;
UPDATE servico SET preco_unitario = 9.90 WHERE id_servico = 1;
SELECT id_reserva, n_seq, preco_unitario AS preco_no_consumo
FROM consumo WHERE id_servico = 1 ORDER BY id_reserva, n_seq;
ROLLBACK;

\echo '--- T10 apagar serviço com consumos (deve falhar: fk_consumo_servico)'
BEGIN;
DELETE FROM servico WHERE id_servico = 7;
ROLLBACK;

\echo '--- T11 pagamento negativo (deve falhar: ck_pagamento_valor)'
BEGIN;
INSERT INTO pagamento (valor, metodo, id_reserva) VALUES (-10, 'cartao', 4);
ROLLBACK;

\echo '--- T12 método fora do conjunto (deve falhar: ck_pagamento_metodo)'
BEGIN;
INSERT INTO pagamento (valor, metodo, id_reserva) VALUES (10, 'paypal', 4);
ROLLBACK;

\echo '--- T13 pagamento sem reserva (deve falhar: NOT NULL)'
BEGIN;
INSERT INTO pagamento (valor, metodo) VALUES (10, 'cartao');
ROLLBACK;

\echo '--- T14 apagar reserva com pagamentos (deve falhar: fk_pagamento_reserva)'
-- Tiram-se primeiro quartos e consumos, para isolar o efeito do pagamento.
BEGIN;
DELETE FROM reserva_quarto WHERE id_reserva = 9;
DELETE FROM consumo WHERE id_reserva = 9;
DELETE FROM reserva WHERE id_reserva = 9;
ROLLBACK;

\echo '--- T15 total da reserva 2 na vista (deve dar 915.00)'
SELECT total FROM v_reserva_total WHERE id_reserva = 2;