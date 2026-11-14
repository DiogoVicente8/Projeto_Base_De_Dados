-- Consultas Q08 a Q14 (necessidades de informação, docs/fase1.md §6).
-- Usam as tabelas e a vista v_reserva_total.

-- Q08. Que serviços são mais consumidos e que receita geram?
SELECT
    s.id_servico,
    s.nome,
    s.ativo,
    COUNT(c.n_seq)                                    AS n_consumos,
    COALESCE(SUM(c.quantidade), 0)                    AS unidades,
    COALESCE(SUM(c.quantidade * c.preco_unitario), 0) AS receita
FROM servico s
LEFT JOIN consumo c ON c.id_servico = s.id_servico
GROUP BY s.id_servico, s.nome, s.ativo
ORDER BY unidades DESC, receita DESC, s.nome;

-- Q09. Que clientes gastaram mais no total (alojamento + serviços)?
-- Só contam reservas em curso ou concluídas.
SELECT
    RANK() OVER (ORDER BY SUM(v.total) DESC) AS posicao,
    cl.id_cliente,
    cl.nome,
    COUNT(*)                AS n_reservas,
    SUM(v.total_alojamento) AS alojamento,
    SUM(v.total_consumos)   AS servicos,
    SUM(v.total)            AS total_gasto
FROM cliente cl
JOIN v_reserva_total v ON v.id_cliente = cl.id_cliente
WHERE v.estado IN ('em_curso', 'concluida')
GROUP BY cl.id_cliente, cl.nome
ORDER BY total_gasto DESC, cl.nome;

-- Q10. Que clientes nunca consumiram nenhum serviço?
SELECT
    cl.id_cliente,
    cl.nome,
    (SELECT COUNT(*) FROM reserva r WHERE r.id_cliente = cl.id_cliente) AS n_reservas
FROM cliente cl
WHERE NOT EXISTS (
    SELECT 1
    FROM reserva r
    JOIN consumo c ON c.id_reserva = r.id_reserva
    WHERE r.id_cliente = cl.id_cliente
)
ORDER BY cl.nome;

-- Q11. Que quartos nunca foram reservados no último ano (últimos 12 meses)?
-- Reservas canceladas não contam.
SELECT q.numero, q.andar, q.estado, t.nome AS tipo
FROM quarto q
JOIN tipo_quarto t ON t.id_tipo = q.id_tipo
WHERE NOT EXISTS (
    SELECT 1
    FROM reserva_quarto rq
    JOIN reserva r ON r.id_reserva = rq.id_reserva
    WHERE rq.numero_quarto = q.numero
      AND r.estado <> 'cancelada'
      AND r.data_entrada_prev <= CURRENT_DATE
      AND r.data_saida_prev   >  CURRENT_DATE - INTERVAL '1 year'
)
ORDER BY q.numero;

-- Q12. Qual a receita mensal por método de pagamento?
SELECT
    TO_CHAR(DATE_TRUNC('month', p.data_hora), 'YYYY-MM')               AS mes,
    COALESCE(SUM(p.valor) FILTER (WHERE p.metodo = 'numerario'), 0)     AS numerario,
    COALESCE(SUM(p.valor) FILTER (WHERE p.metodo = 'cartao'), 0)        AS cartao,
    COALESCE(SUM(p.valor) FILTER (WHERE p.metodo = 'transferencia'), 0) AS transferencia,
    COALESCE(SUM(p.valor) FILTER (WHERE p.metodo = 'mbway'), 0)         AS mbway,
    SUM(p.valor)                                                        AS total_mes
FROM pagamento p
GROUP BY DATE_TRUNC('month', p.data_hora)
ORDER BY DATE_TRUNC('month', p.data_hora);

-- Q13. Quantas reservas foram canceladas por mês e qual a taxa de cancelamento?
-- O modelo não guarda a data do cancelamento: agrupa-se pelo mês de criação.
SELECT
    TO_CHAR(DATE_TRUNC('month', r.data_criacao), 'YYYY-MM') AS mes_criacao,
    COUNT(*)                                                AS n_reservas,
    COUNT(*) FILTER (WHERE r.estado = 'cancelada')          AS n_canceladas,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.estado = 'cancelada')
          / NULLIF(COUNT(*), 0), 1)                         AS taxa_cancelamento_pct
FROM reserva r
GROUP BY DATE_TRUNC('month', r.data_criacao)
ORDER BY DATE_TRUNC('month', r.data_criacao);

-- Q14. Que funcionários registaram mais reservas?
SELECT
    RANK() OVER (ORDER BY COUNT(r.id_reserva) DESC)            AS posicao,
    f.id_funcionario,
    f.nome,
    f.funcao,
    COUNT(r.id_reserva)                                        AS n_reservas,
    COUNT(r.id_reserva) FILTER (WHERE r.estado <> 'cancelada') AS n_nao_canceladas
FROM funcionario f
LEFT JOIN reserva r ON r.id_funcionario = f.id_funcionario
GROUP BY f.id_funcionario, f.nome, f.funcao
ORDER BY n_reservas DESC, f.nome;