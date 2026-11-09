# Fase 2: parte do Diogo (núcleo de alojamento)

Tabelas desta parte: `tipo_quarto`, `quarto`, `cliente`, `funcionario`, `reserva` e `reserva_quarto` (relacionamento `INCLUI` do modelo conceptual).
Scripts: [`sql/drop.sql`](../sql/drop.sql) e [`sql/Table.sql`](../sql/Table.sql).
Diagrama: [`modelos/modelo_relacional.md`](../modelos/modelo_relacional.md).

---

## 1. Modelo relacional

```
tipo_quarto(id_tipo, nome UK, descricao, capacidade_max, preco_base_noite)

quarto(numero, andar, estado, id_tipo)
    id_tipo → tipo_quarto

cliente(id_cliente, nome, n_documento UK, nif UK (nulo permitido), email, telefone, nacionalidade)

funcionario(id_funcionario, nome, funcao)

reserva(id_reserva, data_criacao, data_entrada_prev, data_saida_prev, estado, observacoes, id_cliente, id_funcionario)
    id_cliente → cliente
    id_funcionario → funcionario

reserva_quarto(id_reserva, numero_quarto, preco_noite, n_hospedes, data_checkin_real, data_checkout_real)
    id_reserva → reserva
    numero_quarto → quarto
```

### Chaves

| Tabela | Chave primária | Chaves candidatas | Chaves estrangeiras |
|---|---|---|---|
| `tipo_quarto` | `id_tipo` | `nome` | n/a |
| `quarto` | `numero` | n/a | `id_tipo` |
| `cliente` | `id_cliente` | `n_documento`, `nif` | n/a |
| `funcionario` | `id_funcionario` | n/a | n/a |
| `reserva` | `id_reserva` | n/a | `id_cliente`, `id_funcionario` |
| `reserva_quarto` | `(id_reserva, numero_quarto)` | n/a | `id_reserva`, `numero_quarto` |

### Domínios

| Atributo | Tipo SQL | Restrição |
|---|---|---|
| `quarto.estado` | `VARCHAR(20)` | `operacional` ou `manutencao` |
| `reserva.estado` | `VARCHAR(20)` | `confirmada`, `em_curso`, `concluida` ou `cancelada` |
| `capacidade_max`, `n_hospedes` | `INTEGER` | maior ou igual a 1 |
| `preco_base_noite`, `preco_noite` | `NUMERIC(10,2)` | maior que 0 |
| datas da reserva | `DATE` | saída posterior à entrada |
| check-in e check-out reais | `TIMESTAMP` | check-out posterior ao check-in |

---

## 2. Justificação do mapeamento ER → relacional

| Elemento do modelo conceptual | Resultado relacional | Justificação |
|---|---|---|
| Entidade com identificador | Tabela com PK | Regra geral do mapeamento. |
| `QUARTO` (identificador `numero`) | PK `numero`, sem chave artificial | O número identifica o quarto no mundo real (RN01); criar um `id` extra seria redundante. |
| `TIPO_QUARTO`, `CLIENTE`, `FUNCIONARIO`, `RESERVA` | PK artificial `id_*` (`GENERATED ALWAYS AS IDENTITY`) | Os identificadores naturais (nome, documento) podem mudar ou ser nulos; a chave artificial é estável e curta para as FK. |
| `n_documento` e `nif` em `CLIENTE` | `UNIQUE` (o NIF aceita `NULL`) | RN08: ambos únicos, e o NIF é opcional. Em PostgreSQL, vários `NULL` não violam `UNIQUE`. |
| Relacionamentos 1:N (`CLASSIFICA`, `FAZ`, `REGISTA`) | FK na tabela do lado N (`quarto.id_tipo`, `reserva.id_cliente`, `reserva.id_funcionario`) | Regra geral para 1:N; não é preciso tabela própria. |
| Participação total do lado N, (1,1) | FK `NOT NULL` | RN01 e RN07: cada quarto tem um tipo e cada reserva tem um cliente e um funcionário. |
| Relacionamento N:M `INCLUI` com atributos | Tabela `reserva_quarto`, PK composta `(id_reserva, numero_quarto)`, com as duas FK | Um N:M não se representa com uma só FK. A PK composta impede o mesmo quarto duas vezes na mesma reserva. Os atributos do relacionamento (`preco_noite`, `n_hospedes`, check-in e check-out reais) dependem do par e passam a colunas. |
| Atributo derivado `total` em `RESERVA` | Não é guardado | RD12 e RN16: guardá-lo criaria dados redundantes que poderiam ficar inconsistentes. Calcula-se numa consulta ou vista. |
| Disponibilidade e ocupação | Não são colunas | RD13: resultam das reservas e dos check-ins. |
| Período da reserva (`data_entrada_prev`, `data_saida_prev`) | Fica só em `reserva` | Depende só de `id_reserva`; pô-lo em `reserva_quarto` violaria a 2NF (secção 3). |

### Decisões de implementação

- **`ON DELETE RESTRICT` em todas as FK.** A RD14 pede que reservas concluídas e canceladas se mantenham registadas; não se apaga um cliente, um quarto ou um tipo que tenha histórico.
- **`CHECK` em vez de `ENUM` para os estados.** É mais simples de alterar (basta substituir a restrição) e é declarativo, que o enunciado prefere.
- **NIF como `VARCHAR(20)` sem validação de formato.** A RN08 só exige unicidade; um cliente estrangeiro pode ter um identificador fiscal com outro formato. Validar 9 dígitos seria inventar uma regra.
- **`email`, `telefone` e `nacionalidade` aceitam `NULL`.** A RD03 lista-os, mas não os torna obrigatórios.
- **Sem índices nesta fase.** Serão estudados na Fase 3, com base em consultas reais e `EXPLAIN ANALYZE`.

---

## 3. Normalização (tabelas desta parte)

**1NF.** Todos os atributos são atómicos: um único valor por coluna (um telefone, um email, um documento) e sem grupos repetidos. Os vários quartos de uma reserva estão em linhas de `reserva_quarto`, não numa lista.

**Dependências funcionais e formas normais, por tabela**

| Tabela | Dependências funcionais relevantes | Análise |
|---|---|---|
| `tipo_quarto` | `id_tipo → nome, descricao, capacidade_max, preco_base_noite`; `nome → id_tipo` | Todo o determinante é chave candidata: **BCNF** (logo 3NF). |
| `quarto` | `numero → andar, estado, id_tipo` | `capacidade_max` e `preco_base_noite` dependem de `id_tipo`, não de `numero`. Por isso vivem em `tipo_quarto`; se estivessem em `quarto`, haveria dependência transitiva (`numero → id_tipo → capacidade_max`) e violaria a 3NF. Está em **BCNF**. |
| `cliente` | `id_cliente → todos`; `n_documento → todos`; `nif → todos` | Os três determinantes são chaves candidatas: **BCNF**. Nenhum atributo não-chave determina outro. |
| `funcionario` | `id_funcionario → nome, funcao` | Um nome não determina a função (dois funcionários podem ter o mesmo nome): **BCNF**. |
| `reserva` | `id_reserva → todos` | Nenhum atributo não-chave determina outro; o `total` (derivado) não é guardado: **BCNF**. |
| `reserva_quarto` | `(id_reserva, numero_quarto) → preco_noite, n_hospedes, data_checkin_real, data_checkout_real` | Todos os atributos dependem da chave **inteira**: não há dependências parciais (**2NF**) nem transitivas (**3NF**). Está em **BCNF**. |

**Pontos que merecem justificação**

1. **Porque é que as datas do período não estão em `reserva_quarto`.** Dependem só de `id_reserva`. Se estivessem repetidas em cada linha de `reserva_quarto`, haveria dependência parcial da chave `(id_reserva, numero_quarto)`, o que violaria a **2NF**, e RN05 (todos os quartos partilham o período) ficaria dependente de manter as cópias iguais. Isto fundamenta a decisão de garantir a RN03 com um trigger e não com um `EXCLUDE`, que exigiria copiar as datas para esta tabela.
2. **`preco_noite` em `reserva_quarto` não é redundância de `tipo_quarto.preco_base_noite`.** O preço é fixado no momento da reserva e pode diferir do preço base (RN09), por isso é um facto diferente: o preço acordado para esse quarto nessa reserva.
3. **Não houve decomposições**, porque o modelo já resulta normalizado do mapeamento. Não foram feitas decomposições artificiais.

A normalização de `servico`, `consumo` e `pagamento` fica na parte do João.

---

## 4. Regras de negócio desta parte → mecanismo

| Regra | Como é garantida | Estado |
|---|---|---|
| RN01 | PK em `quarto.numero`; FK `id_tipo` `NOT NULL` | Feito (Fase 2) |
| RN02 | `CHECK (data_saida_prev > data_entrada_prev)` | Feito |
| RN03 | Trigger em `reserva_quarto` (período vem de `reserva`) | Fase 3 |
| RN04 | Trigger (estado do quarto noutra tabela) | Fase 3 |
| RN05 | Reserva com pelo menos um quarto: não é expressável só com restrições declarativas | Fase 3 (trigger ou verificação em transação) |
| RN06 | `CHECK (n_hospedes >= 1)`; o limite pela capacidade do tipo exige consulta a outra tabela | Parte feita; resto na Fase 3 (trigger) |
| RN07 | FK `id_cliente` e `id_funcionario` `NOT NULL` | Feito |
| RN08 | `UNIQUE` em `n_documento` e `nif` | Feito |
| RN09 | `CHECK (preco_noite > 0)`; o valor por omissão (preço base) é preenchido na inserção | Parte feita; "não muda depois" é garantido por o preço ser copiado, não referenciado |
| RN10 | `CHECK` do check-out posterior ao check-in; o check-in só em reserva confirmada exige consultar `reserva` | Parte feita; resto na Fase 3 (trigger) |
| RN11 | Cancelada sem check-in: depende do `estado` de `reserva` | Fase 3 (trigger) |

As regras RN12 a RN16 (consumos, pagamentos e total) estão na parte do João.

---

## 5. Validação

Os scripts foram executados num PostgreSQL limpo (`drop.sql` seguido de `Table.sql`) sem erros. Testes feitos:

| Teste | Resultado esperado | Resultado observado |
|---|---|---|
| Inserção válida em todas as tabelas | Aceite | Aceite |
| Reserva com saída igual à entrada | Recusada (`ck_reserva_datas`) | Recusada |
| Cliente com `n_documento` repetido | Recusado (`uq_cliente_n_documento`) | Recusado |
| `reserva_quarto` com quarto inexistente | Recusada (FK) | Recusada |
| Check-out sem check-in | Recusado (`ck_reserva_quarto_checkout`) | Recusado |
| Apagar cliente com reservas | Recusado (`ON DELETE RESTRICT`) | Recusado |
| Dois clientes com NIF nulo | Aceites | Aceites |

Estes testes devem passar a ficar em `testes/` quando se fizerem os testes formais da Fase 3.