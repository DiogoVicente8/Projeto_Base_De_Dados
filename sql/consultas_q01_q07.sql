
-- Q01. Quartos livres entre duas datas e respetivo tipo.
-- Intervalos [entrada, saída): uma saída no dia da nova entrada não bloqueia.
WITH parametros AS (
    SELECT DATE '2026-06-08' AS entrada, DATE '2026-06-09' AS saida
)
SELECT q.numero, t.nome AS tipo, t.capacidade_max, t.preco_base_noite
FROM quarto q
JOIN tipo_quarto t ON t.id_tipo = q.id_tipo
CROSS JOIN parametros p
WHERE p.saida > p.entrada
  AND q.estado = 'operacional'
  AND NOT EXISTS (
      SELECT 1 FROM reserva_quarto rq
      JOIN reserva r ON r.id_reserva = rq.id_reserva
      WHERE rq.numero_quarto = q.numero AND r.estado <> 'cancelada'
        AND r.data_entrada_prev < p.saida AND r.data_saida_prev > p.entrada
  )
ORDER BY t.nome, q.numero;

-- Q02. Reservas de um cliente, incluindo canceladas; uma linha por quarto.
WITH parametros AS (SELECT 1 AS id_cliente)
SELECT r.id_reserva, cl.nome AS cliente, r.data_entrada_prev, r.data_saida_prev,
       rq.numero_quarto, r.estado
FROM reserva r
JOIN cliente cl ON cl.id_cliente = r.id_cliente
LEFT JOIN reserva_quarto rq ON rq.id_reserva = r.id_reserva
JOIN parametros p ON p.id_cliente = r.id_cliente
ORDER BY r.data_entrada_prev, r.id_reserva, rq.numero_quarto;

-- Q03. Movimentos previstos no dia, por quarto; canceladas não contam.
WITH parametros AS (SELECT DATE '2026-06-08' AS dia)
SELECT 'check-in' AS movimento, r.id_reserva, rq.numero_quarto, cl.nome AS cliente,
       r.data_entrada_prev AS dia, r.estado
FROM reserva r
JOIN reserva_quarto rq ON rq.id_reserva = r.id_reserva
JOIN cliente cl ON cl.id_cliente = r.id_cliente
JOIN parametros p ON p.dia = r.data_entrada_prev
WHERE r.estado <> 'cancelada'
UNION ALL
SELECT 'check-out', r.id_reserva, rq.numero_quarto, cl.nome,
       r.data_saida_prev, r.estado
FROM reserva r
JOIN reserva_quarto rq ON rq.id_reserva = r.id_reserva
JOIN cliente cl ON cl.id_cliente = r.id_cliente
JOIN parametros p ON p.dia = r.data_saida_prev
WHERE r.estado <> 'cancelada'
ORDER BY movimento, numero_quarto, id_reserva;

-- Q04. Total, pagamentos e saldo de todas as reservas.
-- Nas canceladas, o total é o valor previsto, não uma cobrança (ver docs/fase2.md).
SELECT v.id_reserva, cl.nome AS cliente, v.estado, v.noites,
       v.total_alojamento, v.total_consumos, v.total, v.total_pago, v.saldo
FROM v_reserva_total v
JOIN cliente cl ON cl.id_cliente = v.id_cliente
ORDER BY v.id_reserva;

-- Q05. Reservas concluídas com saldo em dívida.
SELECT v.id_reserva, cl.nome AS cliente, v.total, v.total_pago, v.saldo
FROM v_reserva_total v
JOIN cliente cl ON cl.id_cliente = v.id_cliente
WHERE v.estado = 'concluida' AND v.saldo > 0
ORDER BY v.saldo DESC, v.id_reserva;

-- Q06. Ocupação real mensal por tipo, em quartos-noite.
-- Conta noites entre as datas reais de check-in/out; estadias em curso são
-- cortadas na data de referência (só noites já decorridas).
-- Denominador: todos os quartos do tipo x noites decorridas no mês.
-- Não existe histórico de manutenção: mede-se a ocupação do inventário total.
WITH parametros AS (
    SELECT DATE '2026-01-01' AS inicio, DATE '2027-01-01' AS fim,
           DATE '2026-11-14' AS referencia
), meses AS (
    SELECT g::date AS inicio_mes,
           LEAST((g + INTERVAL '1 month')::date, p.fim, p.referencia) AS fim_periodo
    FROM parametros p
    CROSS JOIN LATERAL generate_series(p.inicio::timestamp,
        (LEAST(p.fim, p.referencia) - 1)::timestamp, INTERVAL '1 month') g
), ocupacao AS (
    SELECT q.id_tipo, rq.data_checkin_real::date AS entrada,
           LEAST(COALESCE(rq.data_checkout_real::date, p.referencia), p.referencia) AS saida
    FROM reserva_quarto rq
    JOIN reserva r ON r.id_reserva = rq.id_reserva
    JOIN quarto q ON q.numero = rq.numero_quarto
    CROSS JOIN parametros p
    WHERE r.estado IN ('em_curso', 'concluida') AND rq.data_checkin_real IS NOT NULL
), inventario AS (
    SELECT id_tipo, COUNT(*) AS n_quartos FROM quarto GROUP BY id_tipo
)
SELECT TO_CHAR(m.inicio_mes, 'YYYY-MM') AS mes, t.nome AS tipo,
       COALESCE(SUM(CASE WHEN o.id_tipo IS NULL THEN 0 ELSE GREATEST(0, LEAST(o.saida, m.fim_periodo)
                    - GREATEST(o.entrada, m.inicio_mes)) END), 0) AS noites_ocupadas,
       i.n_quartos * (m.fim_periodo - m.inicio_mes) AS quartos_noite,
       ROUND(100.0 * COALESCE(SUM(CASE WHEN o.id_tipo IS NULL THEN 0 ELSE GREATEST(0, LEAST(o.saida, m.fim_periodo)
                    - GREATEST(o.entrada, m.inicio_mes)) END), 0)
             / NULLIF(i.n_quartos * (m.fim_periodo - m.inicio_mes), 0), 2) AS taxa_ocupacao_pct
FROM meses m
CROSS JOIN tipo_quarto t
JOIN inventario i ON i.id_tipo = t.id_tipo
LEFT JOIN ocupacao o ON o.id_tipo = t.id_tipo
    AND o.entrada < m.fim_periodo AND o.saida > m.inicio_mes
GROUP BY m.inicio_mes, m.fim_periodo, t.id_tipo, t.nome, i.n_quartos
ORDER BY m.inicio_mes, t.nome;

-- Q07. Duração média real das estadias concluídas por tipo de quarto.
-- Cada quarto ocupado é uma estadia; excluem-se canceladas e estadias em curso.
SELECT t.nome AS tipo, COUNT(rq.id_reserva) AS n_estadias,
       ROUND(AVG(rq.data_checkout_real::date - rq.data_checkin_real::date), 2) AS media_noites
FROM tipo_quarto t
LEFT JOIN quarto q ON q.id_tipo = t.id_tipo
LEFT JOIN (
    SELECT rq.* FROM reserva_quarto rq
    JOIN reserva r ON r.id_reserva = rq.id_reserva
    WHERE r.estado = 'concluida' AND rq.data_checkin_real IS NOT NULL
      AND rq.data_checkout_real IS NOT NULL
) rq ON rq.numero_quarto = q.numero
GROUP BY t.id_tipo, t.nome
ORDER BY t.nome;
