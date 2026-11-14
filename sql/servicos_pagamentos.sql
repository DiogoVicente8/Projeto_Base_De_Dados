-- servico, pagamento e consumo (entidade fraca de RESERVA).
-- Depende de sql/Table.sql. Mesmas convenções do resto do projeto.

CREATE TABLE servico (
    id_servico     INTEGER GENERATED ALWAYS AS IDENTITY,
    nome           VARCHAR(50)   NOT NULL,
    descricao      TEXT,
    preco_unitario NUMERIC(10,2) NOT NULL,
    ativo          BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_servico PRIMARY KEY (id_servico),
    CONSTRAINT uq_servico_nome UNIQUE (nome),
    CONSTRAINT ck_servico_preco CHECK (preco_unitario > 0)
);

CREATE TABLE pagamento (
    id_pagamento INTEGER GENERATED ALWAYS AS IDENTITY,
    data_hora    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor        NUMERIC(10,2) NOT NULL,
    metodo       VARCHAR(20)   NOT NULL,
    id_reserva   INTEGER       NOT NULL,

    CONSTRAINT pk_pagamento PRIMARY KEY (id_pagamento),
    CONSTRAINT ck_pagamento_valor CHECK (valor > 0),                       -- RN14
    CONSTRAINT ck_pagamento_metodo CHECK (
        metodo IN ('numerario', 'cartao', 'transferencia', 'mbway')        -- RN14
    ),
    CONSTRAINT fk_pagamento_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva) ON DELETE RESTRICT
);

-- Entidade fraca: a PK do dono (id_reserva) entra na PK, com a chave parcial n_seq.
-- n_seq não é IDENTITY porque é numerado dentro de cada reserva (1, 2, 3...).
CREATE TABLE consumo (
    id_reserva     INTEGER       NOT NULL,
    n_seq          INTEGER       NOT NULL,
    data_hora      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    quantidade     INTEGER       NOT NULL,
    preco_unitario NUMERIC(10,2) NOT NULL,   -- preço copiado no momento (RN13)
    id_servico     INTEGER       NOT NULL,

    CONSTRAINT pk_consumo PRIMARY KEY (id_reserva, n_seq),
    CONSTRAINT ck_consumo_n_seq CHECK (n_seq >= 1),
    CONSTRAINT ck_consumo_quantidade CHECK (quantidade >= 1),              -- RN12
    CONSTRAINT ck_consumo_preco CHECK (preco_unitario > 0),
    CONSTRAINT fk_consumo_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva) ON DELETE RESTRICT,
    CONSTRAINT fk_consumo_servico FOREIGN KEY (id_servico)
        REFERENCES servico (id_servico) ON DELETE RESTRICT
);