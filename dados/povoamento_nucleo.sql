-- Dados fictícios; fotografia operacional de 2026-11-14.
-- Executar através de sql/run_all.sql, após recriar as tabelas.
-- A ordem dos INSERT gera as reservas 1 a 9 referidas nos serviços.
INSERT INTO tipo_quarto (nome, descricao, capacidade_max, preco_base_noite) VALUES
    ('Individual', 'Uma cama individual', 1, 50.00),
    ('Duplo', 'Uma cama de casal ou duas camas individuais', 2, 80.00),
    ('Suite', 'Quarto com sala e sofá-cama', 3, 130.00),
    ('Familiar', 'Dois espaços para uma família', 4, 140.00);

INSERT INTO quarto (numero, andar, estado, id_tipo) VALUES
    (101, 1, 'operacional', 2), (102, 1, 'operacional', 2),
    (103, 1, 'operacional', 1), (104, 1, 'operacional', 1),
    (105, 1, 'manutencao', 2),
    (201, 2, 'operacional', 2), (202, 2, 'operacional', 2),
    (203, 2, 'operacional', 2), (204, 2, 'operacional', 2),
    (205, 2, 'operacional', 2),
    (301, 3, 'operacional', 3), (302, 3, 'operacional', 3),
    (303, 3, 'operacional', 4), (304, 3, 'operacional', 4),
    (305, 3, 'operacional', 1);

INSERT INTO cliente (nome, n_documento, nif, email, telefone, nacionalidade) VALUES
    ('Ana Silva', 'DOC-PT-001', '200000001', 'ana@example.com', '910000001', 'Portuguesa'),
    ('Bruno Costa', 'DOC-PT-002', '200000002', 'bruno@example.com', '910000002', 'Portuguesa'),
    ('Carla Martins', 'DOC-PT-003', '200000003', 'carla@example.com', '910000003', 'Portuguesa'),
    ('David García', 'PASS-ES-004', NULL, 'david@example.com', '+34600000004', 'Espanhola'),
    ('Eva Sousa', 'DOC-PT-005', '200000005', 'eva@example.com', '910000005', 'Portuguesa'),
    ('Fátima Rocha', 'DOC-PT-006', '200000006', NULL, '910000006', 'Portuguesa'),
    ('Gonçalo Pinto', 'DOC-PT-007', '200000007', 'goncalo@example.com', NULL, 'Portuguesa'),
    ('Helen Brown', 'PASS-GB-008', NULL, 'helen@example.com', '+447000000008', 'Britânica'),
    ('Inês Lopes', 'DOC-PT-009', '200000009', 'ines@example.com', '910000009', 'Portuguesa');

INSERT INTO funcionario (nome, funcao) VALUES
    ('Marta Almeida', 'Rececionista'), ('Pedro Santos', 'Rececionista'),
    ('Rita Ferreira', 'Gestora'), ('Tiago Melo', 'Rececionista');

INSERT INTO reserva (data_criacao, data_entrada_prev, data_saida_prev, estado,
                     observacoes, id_cliente, id_funcionario) VALUES
    ('2026-05-20', '2026-06-05', '2026-06-08', 'concluida', 'Tarifa acordada: 50 euros/noite', 1, 1),
    ('2026-06-16', '2026-07-10', '2026-07-15', 'concluida', 'Dois quartos; alojamento de 700 euros', 2, 2),
    ('2026-07-01', '2026-07-31', '2026-08-03', 'concluida', 'Estadia entre dois meses, sem serviços', 3, 1),
    ('2026-10-02', '2026-11-10', '2026-11-15', 'em_curso', 'Check-out ainda não realizado', 4, 2),
    ('2026-11-06', '2026-11-20', '2026-11-27', 'confirmada', 'Sinal de 30 por cento', 5, 1),
    ('2026-05-21', '2026-06-05', '2026-06-08', 'cancelada', 'Não bloqueia o quarto da reserva 1', 6, 1),
    ('2026-08-30', '2026-09-12', '2026-09-14', 'concluida', 'Saldo em dívida de 80 euros', 7, 3),
    ('2026-11-07', '2026-12-01', '2026-12-03', 'cancelada', 'Sem consumos, pagamentos ou check-in', 6, 2),
    ('2025-09-15', '2025-09-30', '2025-10-04', 'concluida', 'Preços históricos de alojamento e serviços', 8, 3),
    ('2026-05-25', '2026-06-08', '2026-06-09', 'concluida', 'Entrada no dia da saída da reserva 1', 1, 1);

-- Preços acordados explícitos, independentes dos preços atuais do catálogo.
-- Canceladas conservam os quartos previstos, sem check-in/out.
INSERT INTO reserva_quarto (id_reserva, numero_quarto, preco_noite, n_hospedes,
                           data_checkin_real, data_checkout_real) VALUES
    (1, 101, 50.00, 2, '2026-06-05 15:00', '2026-06-08 11:00'),
    (2, 201, 60.00, 2, '2026-07-10 15:00', '2026-07-15 12:00'),
    (2, 301, 80.00, 2, '2026-07-10 15:05', '2026-07-15 12:00'),
    (3, 202, 80.00, 2, '2026-07-31 15:00', '2026-08-03 11:00'),
    (4, 102, 65.00, 1, '2026-11-10 13:30', NULL),
    (5, 302, 130.00, 3, NULL, NULL),
    (6, 101, 50.00, 2, NULL, NULL),
    (7, 101, 55.00, 2, '2026-09-12 15:00', '2026-09-14 10:00'),
    (8, 204, 80.00, 2, NULL, NULL),
    (9, 203, 82.50, 2, '2025-09-30 15:00', '2025-10-04 10:30'),
    (10, 101, 50.00, 1, '2026-06-08 15:00', '2026-06-09 11:00');
