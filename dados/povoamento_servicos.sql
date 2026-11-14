-- Povoamento: servico, consumo e pagamento.
-- Corre DEPOIS dos dados do núcleo (consumos e pagamentos referem reservas).
-- Assume as reservas 1 a 9 do núcleo; se o Diogo usar outras, ajustar os id_reserva.

-- servico
INSERT INTO servico (nome, descricao, preco_unitario, ativo) VALUES
    ('Pequeno-almoço',      'Buffet das 7h30 às 10h30, por pessoa',        8.50, TRUE),   -- 1 (antes 7.50)
    ('Lavandaria',          'Lavagem e engomagem, por saco',              12.00, TRUE),   -- 2
    ('Transfer aeroporto',  'Transporte de/para o aeroporto, por viagem', 25.00, TRUE),   -- 3
    ('Massagem',            'Massagem de relaxamento, 50 minutos',        45.00, TRUE),   -- 4
    ('Estacionamento',      'Lugar de garagem, por dia',                  10.00, TRUE),   -- 5
    ('Aluguer de bicicleta','Por dia (nunca consumido nos dados)',        15.00, TRUE),   -- 6
    ('Late check-out',      'Saída até às 15h (descontinuado)',           20.00, FALSE);  -- 7 inativo

-- consumo (n_seq conta dentro de cada reserva: 1, 2, 3...)
-- Só reservas em curso ou concluídas têm consumos (RN11, RN12).
INSERT INTO consumo (id_reserva, n_seq, data_hora, quantidade, preco_unitario, id_servico) VALUES
    (1, 1, '2026-06-06 08:30', 2,  8.50, 1),
    (1, 2, '2026-06-05 15:20', 3, 10.00, 5),
    (2, 1, '2026-07-11 08:45', 4,  8.50, 1),
    (2, 2, '2026-07-12 09:00', 4,  8.50, 1),
    (2, 3, '2026-07-13 17:00', 2, 45.00, 4),
    (2, 4, '2026-07-13 19:30', 1, 12.00, 2),
    (2, 5, '2026-07-15 10:00', 1, 25.00, 3),
    (2, 6, '2026-07-15 11:00', 1, 20.00, 7),   -- late check-out quando ainda estava ativo
    (4, 1, '2026-11-10 14:00', 2, 25.00, 3),
    (4, 2, '2026-11-11 08:15', 1,  8.50, 1),
    (7, 1, '2026-09-12 18:10', 2, 10.00, 5),
    (9, 1, '2025-10-02 08:30', 3,  7.50, 1),   -- preço de 2025 (RN13)
    (9, 2, '2025-10-04 10:00', 1, 18.00, 7);

-- pagamento
-- Nenhuma reserva fica com mais pago do que o total (RN15).
INSERT INTO pagamento (data_hora, valor, metodo, id_reserva) VALUES
    ('2025-10-04 10:15', 370.50, 'numerario',     9),   -- paga exatamente
    ('2026-06-08 10:50', 197.00, 'cartao',        1),   -- paga exatamente, saldo 0
    ('2026-06-16 09:30', 200.00, 'transferencia', 2),   -- sinal
    ('2026-07-15 11:20', 715.00, 'cartao',        2),   -- restante
    ('2026-08-03 10:05', 240.00, 'mbway',         3),
    ('2026-09-14 09:40',  50.00, 'numerario',     7),   -- concluída com dívida
    ('2026-10-02 12:00', 100.00, 'mbway',         4),   -- sinal, estadia a decorrer
    ('2026-11-06 16:45', 273.00, 'transferencia', 5);   -- sinal de 30%
