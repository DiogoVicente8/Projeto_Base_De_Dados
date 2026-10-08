# Modelo conceptual ER (Mermaid)

Versão em Mermaid do modelo conceptual do Contexto A (Alojamento local). A versão principal, em notação de Chen, está em [`modelo_conceptual.drawio`](modelo_conceptual.drawio).

```mermaid
erDiagram
    TIPO_QUARTO ||..o{ QUARTO : classifica
    CLIENTE ||..o{ RESERVA : faz
    FUNCIONARIO ||..o{ RESERVA : regista
    RESERVA ||--|{ INCLUI : tem
    QUARTO ||--o{ INCLUI : "e reservado em"
    RESERVA ||..o{ PAGAMENTO : tem
    RESERVA ||--o{ CONSUMO : "tem (identificador)"
    SERVICO ||..o{ CONSUMO : "refere-se a"

    TIPO_QUARTO {
        identificador id_tipo PK
        texto nome
        texto descricao
        numero capacidade_max
        valor preco_base_noite
    }

    QUARTO {
        identificador numero PK
        numero andar
        texto estado
    }

    CLIENTE {
        identificador id_cliente PK
        texto nome
        texto n_documento
        texto nif
        texto email
        texto telefone
        texto nacionalidade
    }

    FUNCIONARIO {
        identificador id_funcionario PK
        texto nome
        texto funcao
    }

    RESERVA {
        identificador id_reserva PK
        data data_criacao
        data data_entrada_prev
        data data_saida_prev
        texto estado
        texto observacoes
        valor total "derivado"
    }

    INCLUI {
        valor preco_noite
        numero n_hospedes
        datahora data_checkin_real
        datahora data_checkout_real
    }

    SERVICO {
        identificador id_servico PK
        texto nome
        texto descricao
        valor preco_unitario
        sim_nao ativo
    }

    PAGAMENTO {
        identificador id_pagamento PK
        datahora data_hora
        valor valor
        texto metodo
    }

    CONSUMO {
        numero n_seq PK "chave parcial"
        datahora data_hora
        numero quantidade
        valor preco_unitario
    }
```

## Como ler

- **Cardinalidades** (pé de galinha): `||` exatamente um, `o{` zero ou mais, `|{` um ou mais.
- **Linha contínua** (`--`): relacionamento identificador. **Linha tracejada** (`..`): não identificador.
- Os "tipos" (`texto`, `data`, `valor`...) são **domínios conceptuais**, não tipos SQL. O Mermaid obriga a indicar um tipo em cada atributo.

## Diferenças em relação à notação de Chen

| Chen (`.drawio`) | Neste Mermaid |
|---|---|
| `INCLUI` é um **relacionamento N:M** com atributos | Aparece como **entidade associativa** `INCLUI`, porque o Mermaid não permite atributos em relacionamentos. Este é o ponto onde o diagrama já se aproxima do modelo relacional. |
| `CONSUMO` é **entidade fraca** | Marcada só pela linha contínua e pelo comentário "chave parcial". Não há símbolo de entidade fraca. |
| Participação total (linha dupla) | Só se vê pela cardinalidade mínima (`||` e `|{` = total; `o{` = parcial). |
| Atributo derivado (elipse tracejada) | Comentário "derivado" no atributo. |
