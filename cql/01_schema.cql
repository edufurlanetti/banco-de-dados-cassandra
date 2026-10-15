-- =============================================================
-- Monitoramento IoT Industrial — Modelo físico (Apache Cassandra 4.1 / 5.0)
-- Autor: Prof. Eduardo Furlanetti
--
-- Regra de ouro do Cassandra: modele a partir das CONSULTAS.
-- Cada tabela atende a uma consulta e os dados são DUPLICADOS
-- (desnormalizados) sem culpa: escrita é barata, junção não existe.
-- =============================================================

DROP KEYSPACE IF EXISTS industria;

-- SimpleStrategy com fator 1 serve para estudo em um só nó.
-- Em produção: NetworkTopologyStrategy com fator 3 por datacenter.
CREATE KEYSPACE industria
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE industria;

-- C1: "Quais máquinas existem em uma planta?"
--     Coluna STATIC: um único valor por partição (dados da planta).
CREATE TABLE maquinas_por_planta (
    planta        text,
    maquina_id    text,
    cidade        text STATIC,
    tipo          text,
    fabricante    text,
    ano           int,
    PRIMARY KEY ((planta), maquina_id)
);

-- C2: "Leituras de uma máquina em um dia, das mais recentes para as mais antigas"
--     Chave de partição composta (máquina + dia) evita partições gigantes:
--     cada partição guarda no máximo um dia de leituras de uma máquina.
--     Os dados expiram sozinhos após 90 dias (TTL padrão).
CREATE TABLE leituras_por_maquina (
    maquina_id   text,
    dia          date,
    momento      timestamp,
    temperatura  decimal,      -- °C
    vibracao     decimal,      -- mm/s RMS
    rpm          int,
    PRIMARY KEY ((maquina_id, dia), momento)
) WITH CLUSTERING ORDER BY (momento DESC)
  AND default_time_to_live = 7776000;

-- C3: "Última leitura de cada máquina" (painel em tempo real)
--     Cada nova leitura sobrescreve a anterior: no Cassandra INSERT = UPSERT.
CREATE TABLE ultima_leitura (
    maquina_id   text PRIMARY KEY,
    momento      timestamp,
    temperatura  decimal,
    vibracao     decimal,
    rpm          int
);

-- C4: "Alertas de uma planta em um mês, dos mais graves para os mais leves"
--     O nível é numérico para que a ordenação física siga a gravidade
--     (em texto, 'ALTO' viria antes de 'CRITICO').
CREATE TABLE alertas_por_planta (
    planta      text,
    mes         text,          -- '2026-03'
    nivel       int,           -- 1 = crítico, 2 = alto, 3 = médio
    momento     timestamp,
    maquina_id  text,
    gravidade   text,
    mensagem    text,
    PRIMARY KEY ((planta, mes), nivel, momento, maquina_id)
) WITH CLUSTERING ORDER BY (nivel ASC, momento DESC, maquina_id ASC);

-- C5: "Quantos alertas cada máquina já teve?"
--     Tabelas de contador só podem ter colunas counter fora da chave.
CREATE TABLE contagem_alertas (
    maquina_id  text PRIMARY KEY,
    total       counter
);
