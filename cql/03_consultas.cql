-- =============================================================
-- Monitoramento IoT Industrial — Consultas (CQL)
-- Toda consulta eficiente informa a CHAVE DE PARTIÇÃO completa.
-- =============================================================
USE industria;

-- 1. C1: máquinas de uma planta (repare na cidade STATIC repetida)
SELECT planta, cidade, maquina_id, tipo, ano
FROM maquinas_por_planta
WHERE planta = 'PLANTA-LIMEIRA';

-- 2. C2: as 3 leituras mais recentes do TORNO-01 no dia
--    (a ordem DESC já está gravada em disco pela CLUSTERING ORDER)
SELECT momento, temperatura, vibracao, rpm
FROM leituras_por_maquina
WHERE maquina_id = 'TORNO-01' AND dia = '2026-03-15'
LIMIT 3;

-- 3. Intervalo na coluna de clustering: manhã de 15/03
SELECT momento, temperatura
FROM leituras_por_maquina
WHERE maquina_id = 'TORNO-01' AND dia = '2026-03-15'
  AND momento >= '2026-03-15 09:00:00+0000'
  AND momento <  '2026-03-15 12:00:00+0000';

-- 4. Agregações DENTRO de uma partição
SELECT COUNT(*) AS leituras,
       MAX(temperatura) AS temp_max,
       AVG(temperatura) AS temp_media,
       MAX(vibracao)    AS vib_max
FROM leituras_por_maquina
WHERE maquina_id = 'TORNO-01' AND dia = '2026-03-15';

-- 5. Vários dias da mesma máquina: IN na chave de partição
SELECT dia, momento, temperatura, vibracao
FROM leituras_por_maquina
WHERE maquina_id = 'PRENSA-01' AND dia IN ('2026-03-15', '2026-03-16');

-- 6. C3: painel com a última leitura de cada máquina
SELECT * FROM ultima_leitura;

-- 7. C4: alertas da planta no mês, já ordenados por gravidade
SELECT gravidade, momento, maquina_id, mensagem
FROM alertas_por_planta
WHERE planta = 'PLANTA-LIMEIRA' AND mes = '2026-03';

--    Somente os críticos (igualdade na 1ª coluna de clustering)
SELECT momento, maquina_id, mensagem
FROM alertas_por_planta
WHERE planta = 'PLANTA-LIMEIRA' AND mes = '2026-03' AND nivel = 1;

-- 8. PER PARTITION LIMIT: a leitura mais recente de cada dia da PRENSA-01
--    (cada dia é uma partição; como a ordem é DESC, a 1ª linha é a mais nova)
SELECT dia, momento, temperatura, vibracao
FROM leituras_por_maquina
WHERE maquina_id = 'PRENSA-01' AND dia IN ('2026-03-15', '2026-03-16')
PER PARTITION LIMIT 1;

-- 9. C5: contadores
SELECT * FROM contagem_alertas;

-- 10. Metadados de cada célula: tempo restante de vida e hora da escrita
SELECT momento, TTL(temperatura) AS segundos_para_expirar, WRITETIME(temperatura) AS gravado_em_us
FROM leituras_por_maquina
WHERE maquina_id = 'TORNO-02' AND dia = '2026-03-15';

-- 11. TTL específico em uma escrita (sobrepõe o padrão da tabela): 1 hora
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm)
VALUES ('TORNO-02', '2026-03-15', '2026-03-15 13:00:00+0000', 49.0, 1.7, 2600)
USING TTL 3600;

-- 12. Lightweight transaction (Paxos): só cadastra se ainda não existir
INSERT INTO ultima_leitura (maquina_id, momento, temperatura, vibracao, rpm)
VALUES ('FRESA-01', '2026-03-15 08:00:00+0000', 35.0, 1.2, 8000)
IF NOT EXISTS;
-- Executando de novo, a coluna [applied] retorna False.

-- 13. O que NÃO fazer: consulta sem a chave de partição.
--     O Cassandra recusa, pois teria de varrer todos os nós do cluster:
-- SELECT * FROM leituras_por_maquina WHERE temperatura > 70;
--     "ALLOW FILTERING" força a execução, mas é um antipadrão em produção:
-- SELECT * FROM leituras_por_maquina WHERE temperatura > 70 ALLOW FILTERING;
