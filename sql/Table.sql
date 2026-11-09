-- =====================================================================
-- Núcleo do alojamento: tipo_quarto, quarto, cliente, funcionario,
-- reserva e reserva_quarto (relacionamento INCLUI do modelo conceptual).
--
-- Convenções: snake_case; PK/FK/UQ/CK com nome explícito;
-- chaves artificiais com GENERATED ALWAYS AS IDENTITY;
-- FK com ON DELETE RESTRICT (RD14: o histórico mantém-se).
-- As referências RNxx e RDxx são as de docs/fase1.md.
-- =====================================================================


-- ---------------------------------------------------------------------
-- tipo_quarto (RD02)
-- ---------------------------------------------------------------------
CREATE TABLE tipo_quarto (
    id_tipo          INTEGER GENERATED ALWAYS AS IDENTITY,
    nome             VARCHAR(50)   NOT NULL,
    descricao        TEXT,
    capacidade_max   INTEGER       NOT NULL,
    preco_base_noite NUMERIC(10,2) NOT NULL,

    CONSTRAINT pk_tipo_quarto PRIMARY KEY (id_tipo),
    CONSTRAINT uq_tipo_quarto_nome UNIQUE (nome),
    CONSTRAINT ck_tipo_quarto_capacidade CHECK (capacidade_max >= 1),
    CONSTRAINT ck_tipo_quarto_preco CHECK (preco_base_noite > 0)
);


-- ---------------------------------------------------------------------
-- quarto (RD01, RN01)
-- O número do quarto é o identificador (RN01), por isso é a PK e não
-- é gerado automaticamente.
-- ---------------------------------------------------------------------
CREATE TABLE quarto (
    numero   INTEGER     NOT NULL,
    andar    INTEGER     NOT NULL,
    estado   VARCHAR(20) NOT NULL DEFAULT 'operacional',
    id_tipo  INTEGER     NOT NULL,                      -- RN01: exatamente um tipo

    CONSTRAINT pk_quarto PRIMARY KEY (numero),
    CONSTRAINT ck_quarto_numero CHECK (numero > 0),
    CONSTRAINT ck_quarto_estado CHECK (estado IN ('operacional', 'manutencao')),
    CONSTRAINT fk_quarto_tipo_quarto FOREIGN KEY (id_tipo)
        REFERENCES tipo_quarto (id_tipo) ON DELETE RESTRICT
);


-- ---------------------------------------------------------------------
-- cliente (RD03, RN08)
-- O NIF é opcional (pode ser NULL), mas, se existir, é único.
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente    INTEGER GENERATED ALWAYS AS IDENTITY,
    nome          VARCHAR(100) NOT NULL,
    n_documento   VARCHAR(30)  NOT NULL,
    nif           VARCHAR(20),
    email         VARCHAR(100),
    telefone      VARCHAR(20),
    nacionalidade VARCHAR(50),

    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_n_documento UNIQUE (n_documento),   -- RN08
    CONSTRAINT uq_cliente_nif UNIQUE (nif)                    -- RN08 (aceita vários NULL)
);


-- ---------------------------------------------------------------------
-- funcionario (RD04)
-- ---------------------------------------------------------------------
CREATE TABLE funcionario (
    id_funcionario INTEGER GENERATED ALWAYS AS IDENTITY,
    nome           VARCHAR(100) NOT NULL,
    funcao         VARCHAR(50)  NOT NULL,

    CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario)
);


-- ---------------------------------------------------------------------
-- reserva (RD05, RD06, RN02, RN07)
-- O total NÃO é guardado (RD12, RN16): calcula-se em consulta/vista.
-- ---------------------------------------------------------------------
CREATE TABLE reserva (
    id_reserva        INTEGER GENERATED ALWAYS AS IDENTITY,
    data_criacao      DATE        NOT NULL DEFAULT CURRENT_DATE,
    data_entrada_prev DATE        NOT NULL,
    data_saida_prev   DATE        NOT NULL,
    estado            VARCHAR(20) NOT NULL DEFAULT 'confirmada',
    observacoes       TEXT,
    id_cliente        INTEGER     NOT NULL,             -- RN07
    id_funcionario    INTEGER     NOT NULL,             -- RN07

    CONSTRAINT pk_reserva PRIMARY KEY (id_reserva),
    CONSTRAINT ck_reserva_datas CHECK (data_saida_prev > data_entrada_prev),   -- RN02
    CONSTRAINT ck_reserva_estado CHECK (
        estado IN ('confirmada', 'em_curso', 'concluida', 'cancelada')
    ),
    CONSTRAINT fk_reserva_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON DELETE RESTRICT,
    CONSTRAINT fk_reserva_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario) ON DELETE RESTRICT
);


-- ---------------------------------------------------------------------
-- reserva_quarto (relacionamento INCLUI; RD07, RD08, RN06, RN09, RN10)
-- Relação N:M entre reserva e quarto; os atributos do relacionamento
-- passam a colunas. O período da reserva fica só em reserva.
-- ---------------------------------------------------------------------
CREATE TABLE reserva_quarto (
    id_reserva         INTEGER       NOT NULL,
    numero_quarto      INTEGER       NOT NULL,
    preco_noite        NUMERIC(10,2) NOT NULL,
    n_hospedes         INTEGER       NOT NULL,
    data_checkin_real  TIMESTAMP,
    data_checkout_real TIMESTAMP,

    CONSTRAINT pk_reserva_quarto PRIMARY KEY (id_reserva, numero_quarto),
    CONSTRAINT fk_reserva_quarto_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva) ON DELETE RESTRICT,
    CONSTRAINT fk_reserva_quarto_quarto FOREIGN KEY (numero_quarto)
        REFERENCES quarto (numero) ON DELETE RESTRICT,
    CONSTRAINT ck_reserva_quarto_preco CHECK (preco_noite > 0),            -- RN09
    CONSTRAINT ck_reserva_quarto_hospedes CHECK (n_hospedes >= 1),         -- RN06 (parte)
    CONSTRAINT ck_reserva_quarto_checkout CHECK (                          -- RN10 (parte)
        data_checkout_real IS NULL
        OR (data_checkin_real IS NOT NULL
            AND data_checkout_real > data_checkin_real)
    )
);