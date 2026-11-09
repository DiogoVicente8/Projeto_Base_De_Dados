# Modelo relacional (Fase 2)

Resultado do mapeamento do modelo conceptual ([`modelo_conceptual.drawio`](modelo_conceptual.drawio)) para o modelo relacional. Os tipos são os usados na implementação em PostgreSQL.

```mermaid
erDiagram
    tipo_quarto ||..o{ quarto : classifica
    cliente ||..o{ reserva : faz
    funcionario ||..o{ reserva : regista
    reserva ||--|{ reserva_quarto : inclui
    quarto ||--o{ reserva_quarto : "e reservado em"
    reserva ||..o{ pagamento : tem
    reserva ||--o{ consumo : "tem (identificador)"
    servico ||..o{ consumo : "refere-se a"

    tipo_quarto {
        INTEGER id_tipo PK
        VARCHAR nome
        TEXT descricao
        INTEGER capacidade_max
        NUMERIC preco_base_noite
    }

    quarto {
        INTEGER numero PK
        INTEGER andar
        VARCHAR estado
        INTEGER id_tipo FK
    }

    cliente {
        INTEGER id_cliente PK
        VARCHAR nome
        VARCHAR n_documento UK
        VARCHAR nif UK
        VARCHAR email
        VARCHAR telefone
        VARCHAR nacionalidade
    }

    funcionario {
        INTEGER id_funcionario PK
        VARCHAR nome
        VARCHAR funcao
    }

    reserva {
        INTEGER id_reserva PK
        DATE data_criacao
        DATE data_entrada_prev
        DATE data_saida_prev
        VARCHAR estado
        TEXT observacoes
        INTEGER id_cliente FK
        INTEGER id_funcionario FK
    }

    reserva_quarto {
        INTEGER id_reserva PK, FK
        INTEGER numero_quarto PK, FK
        NUMERIC preco_noite
        INTEGER n_hospedes
        TIMESTAMP data_checkin_real
        TIMESTAMP data_checkout_real
    }

    servico {
        INTEGER id_servico PK
        VARCHAR nome
        TEXT descricao
        NUMERIC preco_unitario
        BOOLEAN ativo
    }

    pagamento {
        INTEGER id_pagamento PK
        TIMESTAMP data_hora
        NUMERIC valor
        VARCHAR metodo
        INTEGER id_reserva FK
    }

    consumo {
        INTEGER id_reserva PK, FK
        INTEGER n_seq PK
        TIMESTAMP data_hora
        INTEGER quantidade
        NUMERIC preco_unitario
        INTEGER id_servico FK
    }
```

## Como ler

- **Cardinalidades** (pé de galinha): `||` exatamente um, `o{` zero ou mais, `|{` um ou mais.
- **Linha contínua** (`--`): a chave estrangeira faz parte da chave primária da tabela filha. **Linha tracejada** (`..`): a chave estrangeira é um atributo normal.
- `PK` chave primária, `FK` chave estrangeira, `UK` valor único (o `nif` pode ser `NULL`).

## Alterações em relação ao modelo conceptual

| Conceptual (Fase 1) | Relacional (Fase 2) |
|---|---|
| Relacionamento N:M `INCLUI` com atributos | Tabela `reserva_quarto`, com PK composta `(id_reserva, numero_quarto)` |
| Entidade fraca `CONSUMO` | Tabela `consumo`, com PK composta `(id_reserva, n_seq)` |
| Atributo derivado `total` em `RESERVA` | **Não é guardado** (RN16); calcula-se numa consulta ou vista |
| Relacionamentos 1:N | Chave estrangeira na tabela do lado N |
| Domínios conceptuais (`texto`, `valor`…) | Tipos SQL do PostgreSQL |