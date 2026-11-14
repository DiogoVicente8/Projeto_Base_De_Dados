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

---
---

# Fase 2: parte do João (serviços, consumos e pagamentos)

Tabelas desta parte: `servico`, `pagamento` e `consumo` (entidade fraca `CONSUMO` do modelo conceptual), mais a vista `v_reserva_total` (atributo derivado `total`).
Scripts: [`sql/servicos_pagamentos.sql`](../sql/servicos_pagamentos.sql), [`sql/vistas.sql`](../sql/vistas.sql), [`sql/run_all.sql`](../sql/run_all.sql) (corre tudo pela ordem certa) e [`sql/consultas_q08_q14.sql`](../sql/consultas_q08_q14.sql).
Dados: [`dados/povoamento_servicos.sql`](../dados/povoamento_servicos.sql). Testes: [`testes/fase2_servicos_pagamentos.sql`](../testes/fase2_servicos_pagamentos.sql).

---

## 1. Modelo relacional

```
servico(id_servico, nome UK, descricao, preco_unitario, ativo)

pagamento(id_pagamento, data_hora, valor, metodo, id_reserva)
    id_reserva → reserva

consumo(id_reserva, n_seq, data_hora, quantidade, preco_unitario, id_servico)
    id_reserva → reserva
    id_servico → servico
```

| Tabela | Chave primária | Chaves candidatas | Chaves estrangeiras |
|---|---|---|---|
| `servico` | `id_servico` | `nome` | n/a |
| `pagamento` | `id_pagamento` | n/a | `id_reserva` |
| `consumo` | `(id_reserva, n_seq)` | n/a | `id_reserva`, `id_servico` |

| Atributo | Tipo SQL | Restrição |
|---|---|---|
| `servico.preco_unitario`, `consumo.preco_unitario` | `NUMERIC(10,2)` | maior que 0 |
| `servico.ativo` | `BOOLEAN` | `NOT NULL`, por omissão `TRUE` |
| `consumo.n_seq` | `INTEGER` | maior ou igual a 1 |
| `consumo.quantidade` | `INTEGER` | maior ou igual a 1 |
| `pagamento.valor` | `NUMERIC(10,2)` | maior que 0 |
| `pagamento.metodo` | `VARCHAR(20)` | `numerario`, `cartao`, `transferencia` ou `mbway` |
| `data_hora` (consumo e pagamento) | `TIMESTAMP` | `NOT NULL`, por omissão o instante atual |

---

## 2. Justificação do mapeamento ER → relacional

As regras gerais (PK artificial, FK no lado N, FK `NOT NULL` para participação total, `ON DELETE RESTRICT`) estão na parte do Diogo e aplicam-se igualmente. Aqui fica só o que é próprio desta parte.

| Elemento do modelo conceptual | Resultado relacional | Justificação |
|---|---|---|
| Entidade fraca `CONSUMO`, chave parcial `n_seq` | Tabela `consumo` com PK composta `(id_reserva, n_seq)`; `id_reserva` é parte da PK e FK | Regra do mapeamento de entidades fracas: a chave do dono entra na PK. Sozinho, `n_seq` não identifica um consumo (há um consumo 1 em cada reserva). |
| Relacionamento identificador `TEM_CONSUMO` | Não gera tabela nem coluna extra | Fica representado pela FK `id_reserva`, que está dentro da PK. |
| `n_seq` | `INTEGER` sem `IDENTITY` | Uma sequência global numeraria todos os consumos seguidos, e deixava de ser uma numeração por reserva. O valor é dado na inserção; na Fase 3, um trigger calcula `MAX(n_seq) + 1` dentro da reserva. |
| `REFERE_SE_A`, CONSUMO (1,1) | FK `consumo.id_servico NOT NULL` | Cada consumo é de exatamente um serviço. |
| `TEM_PAGAMENTO`, PAGAMENTO (1,1) | FK `pagamento.id_reserva NOT NULL` | Relacionamento 1:N; cada pagamento é de exatamente uma reserva. |
| `PAGAMENTO` como entidade forte | PK própria `id_pagamento` | Decidido na Fase 1 (§7.3): os pagamentos são consultados por si (Q12). |
| Atributo derivado `total` de `RESERVA` | Vista `v_reserva_total` | Não se guarda (RD12, RN16). A vista calcula alojamento, consumos, total, total pago e saldo a partir dos dados de base, por isso nunca fica desatualizada. Cada parcela é somada numa subconsulta à parte: um `JOIN` direto de `reserva_quarto`, `consumo` e `pagamento` multiplicava as linhas e inflacionava as somas. |

### Decisões de implementação

- **`ON DELETE RESTRICT` também em `fk_consumo_reserva`.** Numa entidade fraca, `CASCADE` seria a escolha habitual. Como as reservas nunca se apagam (RD14), `RESTRICT` mantém a mesma política em todo o modelo e evita que um `DELETE` por engano leve consumos consigo.
- **`metodo` com `CHECK`, não com tabela de domínio**, pela mesma razão dos estados na parte do Diogo: conjunto fixo e pequeno (RN14). *Decisão em conjunto ainda por fechar.*
- **`servico.ativo` em vez de apagar serviços.** Um serviço descontinuado mantém os consumos antigos e deixa de poder ser consumido (RN12, Fase 3).
- **A vista inclui as reservas canceladas** com o total que teriam; quem consulta filtra pelo `estado`. *A rever em conjunto*: em alternativa, a vista pode pôr o total das canceladas a 0.

---

## 3. Normalização

### 3.1 Tabelas desta parte

| Tabela | Dependências funcionais relevantes | Análise |
|---|---|---|
| `servico` | `id_servico → nome, descricao, preco_unitario, ativo`; `nome → id_servico` | Os dois determinantes são chaves candidatas: **BCNF**. |
| `pagamento` | `id_pagamento → data_hora, valor, metodo, id_reserva` | Nenhum atributo não-chave determina outro: **BCNF**. |
| `consumo` | `(id_reserva, n_seq) → data_hora, quantidade, preco_unitario, id_servico` | Nada depende só de parte da chave (**2NF**); `id_servico ↛ preco_unitario` (ponto 1), logo sem dependências transitivas (**3NF**). O único determinante é a chave: **BCNF**. |

**Pontos que merecem justificação**

1. **`consumo.preco_unitario` não cria dependência transitiva.** Se fosse sempre o preço atual do serviço, haveria `id_servico → preco_unitario` e a coluna violaria a 3NF. Mas a RN13 fixa o preço no momento do consumo: nos dados, o mesmo serviço aparece a 7.50 € (2025) e a 8.50 € (2026). Logo `id_servico ↛ preco_unitario`. É o mesmo raciocínio do `preco_noite` na parte do Diogo.
2. **`data_hora`, `quantidade` e `id_servico` dependem do consumo concreto** (chave inteira), não só de `id_reserva`.
3. **O `total` não é guardado.** Dependeria de linhas de outras tabelas, por isso fica numa vista.

### 3.2 Modelo completo

As nove tabelas das duas partes estão em **BCNF**:

- **1NF.** Atributos atómicos e sem grupos repetidos: os quartos, consumos e pagamentos de uma reserva estão em linhas próprias, não em listas.
- **2NF.** Só `reserva_quarto` e `consumo` têm chave composta, e em ambas os atributos dependem da chave inteira.
- **3NF/BCNF.** Os atributos que dependem de outra entidade vivem na tabela dessa entidade. Os preços copiados (`preco_noite`, `consumo.preco_unitario`) são factos próprios (RN09, RN13), não dependências transitivas.
- **Sem decomposições.** O mapeamento do modelo conceptual já deu tabelas normalizadas.

---

## 4. Regras de negócio desta parte → mecanismo

| Regra | Como é garantida | Estado |
|---|---|---|
| RN11 | Cancelada sem consumos: depende do `estado` de `reserva` | Fase 3 (trigger em `consumo`) |
| RN12 | `CHECK (quantidade >= 1)`; reserva em curso e serviço ativo exigem consultar outras tabelas | Parte feita; resto na Fase 3 (trigger) |
| RN13 | Preço copiado para `consumo.preco_unitario`, com `CHECK (preco_unitario > 0)`; testado em T09 | Feito |
| RN14 | `CHECK (valor > 0)` e `CHECK (metodo IN (...))`; a data não futura fica para trigger | Parte feita; data na Fase 3 |
| RN15 | Total pago ≤ total da reserva: exige somar várias tabelas | Fase 3 (trigger em `pagamento`) |
| RN16 | Vista `v_reserva_total` | Feito |

**Porque é que a data não futura (RN14) não fica num `CHECK`.** Um `CHECK (data_hora <= CURRENT_TIMESTAMP)` usa uma função que muda com o tempo; a documentação do PostgreSQL desaconselha `CHECK` com funções não imutáveis, porque um *restore* feito mais tarde pode dar resultados diferentes. Um trigger faz a mesma verificação sem esse problema.

**Nota para os triggers da Fase 3.** Os dados de povoamento inserem as reservas já no estado final (por exemplo, consumos em reservas `concluida`). Um trigger que exija `estado = 'em_curso'` para inserir consumos tem de ser criado depois do povoamento.

---

## 5. Dados de povoamento

[`dados/povoamento_servicos.sql`](../dados/povoamento_servicos.sql) tem 7 serviços, 13 consumos e 8 pagamentos, e assume as reservas 1 a 9 do núcleo.

| Caso limite | Onde |
|---|---|
| Serviço inativo com consumos antigos | `Late check-out` |
| Serviço nunca consumido | `Aluguer de bicicleta` (aparece em Q08 com 0) |
| Consumo com preço diferente do atual (RN13) | Pequeno-almoço a 7.50 € na reserva de 2025 |
| Reserva paga exatamente pelo total (saldo 0) | Reserva 1 |
| Pagamento em prestações (sinal + restante) | Reserva 2 |
| Concluída com saldo por pagar | Reserva 7 (saldo 80 €) |
| Confirmada só com sinal, sem consumos | Reserva 5 |
| Canceladas sem consumos nem pagamentos (RN11) | Reservas 6 e 8 |
| Os quatro métodos de pagamento, em meses diferentes | Q12 |

---

## 6. Consultas Q08 a Q14

Ficheiro: [`sql/consultas_q08_q14.sql`](../sql/consultas_q08_q14.sql).

| Id | Interpretação e técnica |
|---|---|
| Q08 | Unidades e receita por serviço, com o preço de cada consumo (RN13). `LEFT JOIN` para mostrar serviços nunca consumidos. |
| Q09 | Total (alojamento + serviços) das reservas em curso ou concluídas; canceladas e futuras não contam. Usa `v_reserva_total` e `RANK()`. |
| Q10 | Clientes sem nenhum consumo em nenhuma reserva (`NOT EXISTS`). Inclui clientes sem reservas; `n_reservas` distingue-os. |
| Q11 | Quartos sem reserva não cancelada nos últimos 12 meses. Depende de `CURRENT_DATE`. |
| Q12 | Pagamentos por mês, uma coluna por método (`FILTER`) e o total do mês. |
| Q13 | O modelo não guarda a data do cancelamento, por isso agrupa-se pelo mês de criação da reserva. `NULLIF` evita divisão por zero. |
| Q14 | Reservas por funcionário, com `LEFT JOIN` para incluir quem não registou nenhuma. |

---

## 7. Validação

Executado em PostgreSQL 18. Os testes estão em [`testes/fase2_servicos_pagamentos.sql`](../testes/fase2_servicos_pagamentos.sql) e correm-se com `psql -U postgres -d hotel -f testes/fase2_servicos_pagamentos.sql`. Cada teste corre numa transação desfeita no fim.

| Teste | Resultado esperado | Resultado observado |
|---|---|---|
| T01 Consumo válido | Aceite | Aceite |
| T02 `n_seq` repetido na mesma reserva | Recusado (`pk_consumo`) | Recusado |
| T03 Mesmo `n_seq` noutra reserva | Aceite (chave parcial) | Aceite |
| T04 Quantidade 0 | Recusado (`ck_consumo_quantidade`) | Recusado |
| T05 Consumo de reserva inexistente | Recusado (`fk_consumo_reserva`) | Recusado |
| T06 Consumo de serviço inexistente | Recusado (`fk_consumo_servico`) | Recusado |
| T07 Serviço com nome repetido | Recusado (`uq_servico_nome`) | Recusado |
| T08 Serviço com preço 0 | Recusado (`ck_servico_preco`) | Recusado |
| T09 Mudar o preço de um serviço | Consumos antigos mantêm o preço | Mantêm |
| T10 Apagar serviço com consumos | Recusado (`fk_consumo_servico`) | Recusado |
| T11 Pagamento negativo | Recusado (`ck_pagamento_valor`) | Recusado |
| T12 Método `paypal` | Recusado (`ck_pagamento_metodo`) | Recusado |
| T13 Pagamento sem reserva | Recusado (`NOT NULL`) | Recusado |
| T14 Apagar reserva com pagamentos | Recusado (`fk_pagamento_reserva`) | Recusado |
| T15 Total da reserva 2 na vista | 915.00 € (calculado à mão) | 915.00 € |