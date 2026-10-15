# Banco de Dados com Apache Cassandra — Monitoramento IoT Industrial

Estudo de caso de **monitoramento de máquinas industriais por sensores** (temperatura, vibração e rotação) no **Apache Cassandra**, banco NoSQL de colunas largas projetado para **escrita massiva**, **séries temporais** e **alta disponibilidade** em clusters distribuídos.

> Material das disciplinas de Banco de Dados e de Engenharia (Indústria 4.0) — Prof. Eduardo Furlanetti.

## A virada de chave: modelar pelas consultas

No modelo relacional, primeiro se normalizam as entidades e depois se escrevem as consultas. No Cassandra, o caminho é o inverso: **cada tabela nasce de uma consulta**, e os dados são duplicados quando necessário.

| Consulta da aplicação | Tabela | Chave primária |
|---|---|---|
| C1 — Máquinas de uma planta | `maquinas_por_planta` | `((planta), maquina_id)` + coluna `STATIC` |
| C2 — Leituras de uma máquina em um dia | `leituras_por_maquina` | `((maquina_id, dia), momento DESC)` + TTL de 90 dias |
| C3 — Última leitura de cada máquina | `ultima_leitura` | `(maquina_id)` |
| C4 — Alertas de uma planta no mês, por gravidade | `alertas_por_planta` | `((planta, mes), nivel, momento DESC, maquina_id)` |
| C5 — Total de alertas por máquina | `contagem_alertas` | `(maquina_id)` + `counter` |

Conceitos trabalhados: **chave de partição** e **colunas de clustering**, *bucketing* por dia, `CLUSTERING ORDER BY`, `TTL` e `WRITETIME`, `BATCH`, contadores, *lightweight transactions* (`IF NOT EXISTS`), `PER PARTITION LIMIT` e o antipadrão `ALLOW FILTERING`.

## Como executar

```bash
docker compose up -d
docker compose ps        # aguarde o status "healthy" (cerca de 1 minuto)

docker exec -it iot-cassandra cqlsh -f /cql/01_schema.cql
docker exec -it iot-cassandra cqlsh -f /cql/02_dados.cql
docker exec -it iot-cassandra cqlsh -f /cql/03_consultas.cql
```

Modo interativo: `docker exec -it iot-cassandra cqlsh`, depois `USE industria;`.

## Estrutura

```
cql/
├── 01_schema.cql      # keyspace e tabelas, cada uma orientada a uma consulta
├── 02_dados.cql       # máquinas, leituras e alertas de exemplo
└── 03_consultas.cql   # consultas comentadas e antipadrões
exercicios/
├── lista.md
└── respostas.md
```

## Licença

[MIT](LICENSE)
