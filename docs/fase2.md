# Fase 2 — Projeto lógico e implementação

Revisão integrada de 14 de novembro de 2026, confrontada com as secções 3, 4 e 6 do enunciado `bdad_proj_2627 (1).pdf` (organização e documentação nas páginas 2–3; Fase 2 nas páginas 6–7), disponível localmente nos Downloads. Os artefactos técnicos estão implementados e validados; a revisão do grupo, o commit e a tag de entrega continuam pendentes. A Fase 1 e os seus modelos foram preservados.



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

Todas as PK também são chaves candidatas. O NIF anulável tem unicidade condicional aos valores preenchidos (`UNIQUE` permite vários `NULL`); não é chave candidata da relação completa.

| Tabela | Chave primária | Chaves candidatas | Chaves estrangeiras |
|---|---|---|---|
| `tipo_quarto` | `id_tipo` | `id_tipo`; `nome` | n/a |
| `quarto` | `numero` | `numero` | `id_tipo` |
| `cliente` | `id_cliente` | `id_cliente`; `n_documento` | n/a |
| `funcionario` | `id_funcionario` | `id_funcionario` | n/a |
| `reserva` | `id_reserva` | `id_reserva` | `id_cliente`, `id_funcionario` |
| `reserva_quarto` | `(id_reserva, numero_quarto)` | `(id_reserva, numero_quarto)` | `id_reserva`, `numero_quarto` |

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

- **`ON DELETE RESTRICT` em todas as FK.** Protege as referências do histórico, impedindo apagar pais referenciados. Não proíbe apagar uma reserva sem dependentes; a proibição global de apagar histórico (RD14) terá de ser completada na Fase 3.
- **`CHECK` em vez de `ENUM` para os estados.** É mais simples de alterar (basta substituir a restrição) e é declarativo, que o enunciado prefere.
- **NIF como `VARCHAR(20)` sem validação de formato.** A RN08 só exige unicidade; um cliente estrangeiro pode ter um identificador fiscal com outro formato. Validar 9 dígitos seria inventar uma regra.
- **`email`, `telefone` e `nacionalidade` aceitam `NULL`.** A RD03 lista-os, mas não os torna obrigatórios.
- **Sem índices adicionais nesta fase.** As PK e restrições `UNIQUE` já criam índices automaticamente. Outros índices serão estudados na Fase 3.

---

## 3. Normalização (tabelas desta parte)

**1NF.** Todos os atributos são atómicos: um único valor por coluna (um telefone, um email, um documento) e sem grupos repetidos. Os vários quartos de uma reserva estão em linhas de `reserva_quarto`, não numa lista.

**Dependências funcionais e formas normais, por tabela**

| Tabela | Dependências funcionais relevantes | Análise |
|---|---|---|
| `tipo_quarto` | `id_tipo → nome, descricao, capacidade_max, preco_base_noite`; `nome → id_tipo` | Todo o determinante é chave candidata: **BCNF** (logo 3NF). |
| `quarto` | `numero → andar, estado, id_tipo` | `capacidade_max` e `preco_base_noite` dependem de `id_tipo`, não de `numero`. Por isso vivem em `tipo_quarto`; se estivessem em `quarto`, haveria dependência transitiva (`numero → id_tipo → capacidade_max`) e violaria a 3NF. Está em **BCNF**. |
| `cliente` | `id_cliente → todos`; `n_documento → todos` | Os dois determinantes são chaves candidatas: **BCNF**, pelas DF identificadas. O NIF é opcional e apenas único quando preenchido; não constitui chave candidata clássica de toda a relação. |
| `funcionario` | `id_funcionario → nome, funcao` | Um nome não determina a função (dois funcionários podem ter o mesmo nome): **BCNF**. |
| `reserva` | `id_reserva → todos` | Nenhum atributo não-chave determina outro; o `total` (derivado) não é guardado: **BCNF**. |
| `reserva_quarto` | `(id_reserva, numero_quarto) → preco_noite, n_hospedes, data_checkin_real, data_checkout_real` | Todos os atributos dependem da chave **inteira**: não há dependências parciais (**2NF**) nem transitivas (**3NF**). Está em **BCNF**. |

**Pontos que merecem justificação**

1. **Porque é que as datas do período não estão em `reserva_quarto`.** Dependem só de `id_reserva`. Se estivessem repetidas em cada linha de `reserva_quarto`, haveria dependência parcial da chave `(id_reserva, numero_quarto)`, o que violaria a **2NF**, e RN05 (todos os quartos partilham o período) ficaria dependente de manter as cópias iguais. Isto fundamenta a decisão de garantir a RN03 com um trigger e não com um `EXCLUDE`, que exigiria copiar as datas para esta tabela.
2. **`preco_noite` em `reserva_quarto` não é redundância de `tipo_quarto.preco_base_noite`.** O preço é fixado no momento da reserva e pode diferir do preço base (RN09), por isso é um facto diferente: o preço acordado para esse quarto nessa reserva.
3. **Não houve decomposições**, porque o modelo já resulta normalizado do mapeamento. Não foram feitas decomposições artificiais.

A normalização de `servico`, `consumo` e `pagamento`, e a revisão do modelo completo pelo João, encontram-se nas secções seguintes.

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
| RN09 | `CHECK (preco_noite > 0)`; preço acordado explícito no povoamento e independente do catálogo | Parcial: alterar o catálogo não altera o preço histórico. Não existe preenchimento automático pelo preço base; fica para a Fase 3. |
| RN10 | `CHECK` do check-out posterior ao check-in; o check-in só em reserva confirmada exige consultar `reserva` | Parte feita; resto na Fase 3 (trigger) |
| RN11 | Cancelada sem check-in: depende do `estado` de `reserva` | Fase 3 (trigger) |

As regras RN12 a RN16 (consumos, pagamentos e total) estão na parte do João.

---

# Fase 2: parte do João (serviços, consumos e pagamentos)

Tabelas desta parte: `servico`, `pagamento` e `consumo` (entidade fraca `CONSUMO` do modelo conceptual), mais a vista `v_reserva_total` (atributo derivado `total`).
Scripts: [`sql/servicos_pagamentos.sql`](../sql/servicos_pagamentos.sql), [`sql/vistas.sql`](../sql/vistas.sql), [`sql/run_all.sql`](../sql/run_all.sql) (corre tudo pela ordem certa) e [`sql/consultas_q08_q14.sql`](../sql/consultas_q08_q14.sql).
Dados: [`dados/povoamento_servicos.sql`](../dados/povoamento_servicos.sql).

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
| `servico` | `id_servico` | `id_servico`; `nome` | n/a |
| `pagamento` | `id_pagamento` | `id_pagamento` | `id_reserva` |
| `consumo` | `(id_reserva, n_seq)` | `(id_reserva, n_seq)` | `id_reserva`, `id_servico` |

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
| `n_seq` | `INTEGER` sem `IDENTITY` | Uma sequência global numeraria todos os consumos seguidos, e deixava de ser uma numeração por reserva. O valor é dado explicitamente na inserção. Qualquer atribuição automática futura terá de garantir a unicidade por reserva; não está implementada na Fase 2. |
| `REFERE_SE_A`, CONSUMO (1,1) | FK `consumo.id_servico NOT NULL` | Cada consumo é de exatamente um serviço. |
| `TEM_PAGAMENTO`, PAGAMENTO (1,1) | FK `pagamento.id_reserva NOT NULL` | Relacionamento 1:N; cada pagamento é de exatamente uma reserva. |
| `PAGAMENTO` como entidade forte | PK própria `id_pagamento` | Decidido na Fase 1 (§7.3): os pagamentos são consultados por si (Q12). |
| Atributo derivado `total` de `RESERVA` | Vista `v_reserva_total` | Não se guarda (RD12, RN16). A vista calcula alojamento, consumos, total, total pago e saldo a partir dos dados de base, por isso nunca fica desatualizada. Cada parcela é somada numa subconsulta à parte: um `JOIN` direto de `reserva_quarto`, `consumo` e `pagamento` multiplicava as linhas e inflacionava as somas. |

### Decisões de implementação

- **`ON DELETE RESTRICT` também em `fk_consumo_reserva`.** Numa entidade fraca, `CASCADE` seria a escolha habitual. A política de conservar reservas (RD14) fundamenta `RESTRICT`, que mantém a mesma opção em todo o modelo e impede apagar uma reserva enquanto tiver consumos. A restrição, por si só, não proíbe apagar reservas sem dependentes.
- **`metodo` com `CHECK`, não com tabela de domínio**, pela mesma razão dos estados na parte do Diogo: conjunto fixo e pequeno (RN14). Decisão mantida nesta Fase 2, conforme RN14.
- **`servico.ativo` em vez de apagar serviços.** Um serviço descontinuado mantém os consumos antigos e deixa de poder ser consumido (RN12, Fase 3).
- **A vista inclui as reservas canceladas** com o valor previsto de alojamento e consumos, mantendo o comportamento SQL existente. Esse total e o saldo calculado não representam necessariamente uma dívida exigível: o `estado` deve ser considerado na interpretação dos resultados. As consultas operacionais filtram pelo estado quando apropriado.

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
| RN13 | Preço histórico em `consumo.preco_unitario`, positivo; alterar o catálogo não o altera | Parcial: captura automática do preço do serviço no momento da inserção fica para a Fase 3. Não há bloqueio à alteração direta do preço histórico. |
| RN14 | `CHECK (valor > 0)` e `CHECK (metodo IN (...))`; a data não futura fica para trigger | Parte feita; data na Fase 3 |
| RN15 | Total pago ≤ total da reserva: exige somar várias tabelas | Fase 3 (trigger em `pagamento`) |
| RN16 | Vista `v_reserva_total` | Feito |

**Data não futura (RN14).** A Fase 2 garante data obrigatória, valor positivo e método válido. A validação temporal do instante de inserção está explicitamente adiada para a Fase 3; `DEFAULT CURRENT_TIMESTAMP` não impede uma data futura fornecida manualmente. Não se apresenta esta parte como já garantida.

**Dados históricos e Fase 3.** O povoamento representa uma fotografia com reservas já concluídas e serviços entretanto desativados. O estado atual não demonstra o estado no instante de cada consumo. A futura validação de transições e de carregamentos históricos terá de distinguir estes casos. Nesta fase não foram criados triggers.

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

# Revisão integrada e evidência de execução (14/11/2026)

## Povoamento do núcleo e compatibilidade com vendas

Os dados são fictícios e têm como referência operacional 14/11/2026. Os IDs
são atribuídos pela ordem dos INSERT após recriação das tabelas. Não há
`OVERRIDING SYSTEM VALUE` nem alterações manuais das sequências.
As reservas 1–9 correspondem às referências dos dados do João; a reserva 10
acrescenta a estadia adjacente à reserva 1. As datas fixas mantêm os resultados
reproduzíveis; os estados representam esta fotografia, não avançam com o relógio.

| Caso | Evidência nos dados |
|---|---|
| Quarto em manutenção | 105, sem reservas |
| NIF opcional | Clientes 4 e 8 com `NULL` |
| Cliente sem reservas | Cliente 9 |
| Funcionário sem reservas | Funcionário 4 |
| Reserva com vários quartos | Reserva 2, quartos 201 e 301, cinco noites |
| Canceladas sem check-in/consumos/pagamentos | Reservas 6 e 8 |
| Cancelada não bloqueia disponibilidade | Reserva 6 coincide com a reserva 1 |
| Períodos adjacentes sem sobreposição | Reserva 1 sai a 08/06 e reserva 10 entra nesse dia, quarto 101 |
| Estadia entre meses | Reserva 3, 31/07 a 03/08; uma noite em julho e duas em agosto |
| Estadia em curso | Reserva 4, check-in real e sem check-out |
| Reserva confirmada futura | Reserva 5, sinal de 273 €, 30% de 910 € |
| Preços históricos | Reserva 9; alojamento a 82,50 €, consumos a preços antigos |

| Reserva | Alojamento | Consumos | Total | Pago | Saldo observado |
|---|---:|---:|---:|---:|---:|
| 1 | 150,00 | 47,00 | 197,00 | 197,00 | 0,00 |
| 2 | 700,00 | 215,00 | 915,00 | 915,00 | 0,00 |
| 3 | 240,00 | 0,00 | 240,00 | 240,00 | 0,00 |
| 4 | 325,00 | 58,50 | 383,50 | 100,00 | 283,50 |
| 5 | 910,00 | 0,00 | 910,00 | 273,00 | 637,00 |
| 6 (cancelada) | 150,00 | 0,00 | 150,00 | 0,00 | 150,00 previsto |
| 7 | 110,00 | 20,00 | 130,00 | 50,00 | 80,00 |
| 8 (cancelada) | 160,00 | 0,00 | 160,00 | 0,00 | 160,00 previsto |
| 9 | 330,00 | 40,50 | 370,50 | 370,50 | 0,00 |
| 10 | 50,00 | 0,00 | 50,00 | 0,00 | 50,00 |

A reserva 2 demonstra a prevenção de multiplicação de somas na vista: dois
quartos, seis consumos e dois pagamentos resultam em 915 €, sem duplicações.

## Interpretação e resultados das consultas

Q01–Q03 usam CTE `parametros`, que pode ser alterada sem mudar a consulta.
Q06 usa início no primeiro dia de um mês e fim exclusivo, com referência
fixa em 14/11/2026. Mede noites reais decorridas por quarto, pela diferença
entre as datas de check-in/out; não mede horas nem ocupação prevista. Uma
estadia sem checkout é cortada na referência. O denominador é o número total
de quartos do tipo vezes as noites decorridas do mês (no mês corrente,
até à referência exclusiva). O inventário inclui manutenção: não há histórico
que permita reconstruir noites indisponíveis. Tipos com quartos mas sem
ocupação aparecem com 0%; tipos sem quartos não têm denominador e não são
listados. Q07 mede a duração real em noites por quarto de estadias concluídas;
se não existirem, devolve contagem zero e média `NULL`.

Q13 conserva a interpretação existente: taxa das reservas criadas em cada mês
que estão canceladas. Não mede a data do evento de cancelamento, que o modelo
não guarda. Esta distinção evita atribuir ao SQL informação inexistente.

| Consulta | Resultado observado com os parâmetros de exemplo |
|---|---|
| Q01 | 13 quartos livres em 08–09/06/2026; exclui 101 ocupado pela reserva 10 e 105 em manutenção |
| Q02 | Cliente 1: reservas 1 e 10, com quarto 101 |
| Q03 | 08/06/2026: check-out da reserva 1 e check-in da reserva 10 |
| Q04 | Dez linhas, com os totais da tabela anterior |
| Q05 | Reservas concluídas 7 e 10, com saldos 80 € e 50 € |
| Q06 | 44 linhas (janeiro–novembro, quatro tipos); duplos: julho 6/248 = 2,42%, agosto 2/248 = 0,81%; suites julho 5/62 = 8,06%; duplos novembro 4/104 = 3,85% |
| Q07 | Duplo: seis estadias, média 3,00 noites; suite: uma, média 5,00; individual e familiar sem estadias concluídas |
| Q08 | Pequeno-almoço lidera com 14 unidades e 116 €; bicicleta aparece com zero |
| Q09 | Bruno Costa em primeiro, 915 €; seis clientes com estadias em curso/concluídas |
| Q10 | Clientes 3, 5, 6 e 9 sem consumos; o último sem reservas |
| Q11 | Dez quartos, incluindo 203 (só estadia de 2025), 204 (só cancelada) e 302 (só futura), à data de 14/11/2026 |
| Q12 | Sete meses com pagamentos; junho de 2026 totaliza 397 € |
| Q13 | Maio de 2026: uma cancelada em três reservas (33,3%); novembro: uma em duas (50,0%) |
| Q14 | Marta Almeida lidera com cinco reservas; Tiago Melo aparece com zero |

Q08–Q14 foram preservadas sem alterações. Todas as catorze consultas foram
executadas e os resultados acima comparados com valores de referência.

## Recriação e ordem das dependências

`run_all.sql` executa drop → núcleo → vendas → vista → povoamento do núcleo →
povoamento de vendas. O script usa `BEGIN`/`COMMIT` e `ON_ERROR_STOP`; os
`\ir` são relativos ao próprio script, independentemente da pasta de execução.
O utilizador cria primeiro a base com `createdb`, conforme o README.

Foram realizadas duas recriações completas consecutivas, ambas sem erros e
com as mesmas contagens: 4 tipos, 15 quartos, 9 clientes, 4 funcionários,
10 reservas, 11 associações, 7 serviços, 13 consumos e 8 pagamentos (81 registos).
O drop deixou zero objetos de relação no schema `public`, incluindo tabelas,
sequências e vista. Os `NOTICE` de objetos inexistentes e de remoção em cascata
da vista são esperados. A BD foi novamente criada e validada no fim.

## Rastreabilidade dos requisitos de dados

| Requisito | Implementação e exploração |
|---|---|
| RD01 | `quarto`, incluindo manutenção; Q01/Q11 |
| RD02 | `tipo_quarto` e FK em `quarto`; Q01/Q06/Q07 |
| RD03 | `cliente`, documento único e NIF opcional; Q02/Q09/Q10 |
| RD04 | `funcionario`; Q14 |
| RD05 | `reserva`, datas e estado; Q02/Q03/Q13 |
| RD06 | FK obrigatórias para cliente e funcionário; Q02/Q14 |
| RD07 | `reserva_quarto`, preço e hóspedes; reserva 2 com dois quartos; mínimo global adiado |
| RD08 | Check-in/out em `reserva_quarto`; Q06/Q07 |
| RD09 | `servico`, preço atual e ativo; Q08 |
| RD10 | `consumo`, chave composta e preço histórico; Q08/Q10 |
| RD11 | `pagamento`, valor e método; Q12 |
| RD12 | `v_reserva_total`, sem total guardado; Q04/Q05/Q09 |
| RD13 | Disponibilidade por período e ocupação real; Q01/Q06 |
| RD14 | Histórico preservado no povoamento e referências protegidas por RESTRICT; proibição global de apagar histórico adiada |

## Limites de integridade e trabalho reservado para a Fase 3

As tabelas anteriores cobrem RN01–RN16. Estão garantidas declarativamente
RN01, RN02, RN07 e RN08; RN16 é calculada pela vista. São parciais RN05
(período único feito), RN06 (mínimo feito), RN09 (preço positivo e independente
do catálogo), RN10 (ordem dos timestamps), RN12 (quantidade), RN13 (preço
histórico independente) e RN14 (valor/método/data obrigatória).
RN03, RN04, o mínimo de um quarto de RN05, os restantes limites e transições
de RN06/RN10/RN11/RN12, a captura de preços de RN09/RN13, a data não futura
de RN14 e RN15 requerem trabalho adicional na Fase 3. Guardar o preço não
impede a sua alteração direta nem valida automaticamente a origem do valor.

A futura implementação terá de considerar inserções e alterações nas tabelas
relacionadas, não apenas na tabela filha. Por exemplo, alterar o período ou
cancelar uma reserva não pode contornar RN03/RN11; reduzir o total de uma
reserva já paga não pode contornar RN15. Estas observações documentam os
limites atuais; não foram implementados mecanismos da Fase 3.

## Auditoria final ao enunciado, secções 6.1–6.5

O requisito 6.5 exige iniciar a implementação das necessidades de informação,
não concluir todas as consultas Q01–Q14. As consultas já presentes são
suficientes e foram preservadas. Os testes formais ficam para a Fase 3. Na revisão anterior do âmbito, executou-se apenas
a criação e o povoamento pelo `run_all.sql`, duas vezes consecutivas em
PostgreSQL 18.6, sem erros. As nove tabelas ficaram com 4 tipos, 15 quartos,
9 clientes, 4 funcionários, 10 reservas, 11 associações, 7 serviços, 13 consumos
e 8 pagamentos: 81 registos no total.

O utilizador confirmou também a execução local na base `Alojamento`: criação
das nove tabelas, povoamento completo, criação de `v_reserva_total`, Q08–Q14
sem erros e totais/saldos corretos nas dez reservas. Estes resultados locais
são informação fornecida pelo utilizador. Nesta revisão exclusivamente
documental não se executaram scripts SQL. Os comandos
PowerShell para reproduzir a base local estão no README.

| Requisito | Estado técnico | Evidência |
|---|---|---|
| 6.1 Modelo relacional | Cumprido | Nove relações, atributos, domínios completos, chaves candidatas corrigidas, PK/FK/restrições e justificação ER → relacional |
| 6.2 Normalização | Cumprido | DF das nove tabelas, análise de 1NF/2NF/3NF e BCNF pelas DF identificadas; sem decomposições artificiais; ressalva do NIF anulável |
| 6.3 PostgreSQL | Cumprido | Nove tabelas e vista; PK/FK/UQ/CK nomeadas, identidades, NUMERIC e reprodução completa documentada |
| 6.4 Dados | Cumprido | Dois scripts compatíveis, 81 registos, casos normais e limite e totais/saldos coerentes |
| 6.5 Início das consultas | Cumprido | Início cumprido pelas consultas existentes; Q08–Q14 validadas e Q01–Q07 preservadas; interpretações documentadas |

A estrutura, as ligações e os comandos do README foram atualizados. O modelo
conceptual e `docs/fase1.md` não foram modificados. Os nomes existentes dos
scripts foram mantidos para preservar referências. A tag local da Fase 1
continua `v1.0-e1`; não existem as tags exatas `v1.0` e `v2.0`. A revisão pelo
grupo, os commits, o push e a criação das tags são tarefas manuais pendentes,
conforme pedido. Esta validação técnica não constitui uma entrega Git publicada.
