-- Atributo derivado "total" de RESERVA (RD12, RN16).
-- Cada parcela é somada numa subconsulta à parte, para os JOINs
-- não multiplicarem linhas e inflacionarem as somas.

CREATE OR REPLACE VIEW v_reserva_total AS
SELECT
    r.id_reserva,
    r.id_cliente,
    r.estado,
    r.data_entrada_prev,
    r.data_saida_prev,
    (r.data_saida_prev - r.data_entrada_prev)                     AS noites,
    COALESCE(a.total_alojamento, 0)                               AS total_alojamento,
    COALESCE(c.total_consumos, 0)                                 AS total_consumos,
    COALESCE(a.total_alojamento, 0) + COALESCE(c.total_consumos, 0) AS total,
    COALESCE(p.total_pago, 0)                                     AS total_pago,
    COALESCE(a.total_alojamento, 0) + COALESCE(c.total_consumos, 0)
        - COALESCE(p.total_pago, 0)                               AS saldo
FROM reserva r
LEFT JOIN (
    SELECT rq.id_reserva,
           SUM((r2.data_saida_prev - r2.data_entrada_prev) * rq.preco_noite) AS total_alojamento
    FROM reserva_quarto rq
    JOIN reserva r2 ON r2.id_reserva = rq.id_reserva
    GROUP BY rq.id_reserva
) a ON a.id_reserva = r.id_reserva
LEFT JOIN (
    SELECT id_reserva, SUM(quantidade * preco_unitario) AS total_consumos
    FROM consumo
    GROUP BY id_reserva
) c ON c.id_reserva = r.id_reserva
LEFT JOIN (
    SELECT id_reserva, SUM(valor) AS total_pago
    FROM pagamento
    GROUP BY id_reserva
) p ON p.id_reserva = r.id_reserva;