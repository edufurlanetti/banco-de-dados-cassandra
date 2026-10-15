-- =============================================================
-- Monitoramento IoT Industrial — Dados de exemplo (fictícios)
-- =============================================================
USE industria;

-- Máquinas (a cidade é STATIC: gravada uma vez por planta)
INSERT INTO maquinas_por_planta (planta, cidade, maquina_id, tipo, fabricante, ano) VALUES ('PLANTA-LIMEIRA', 'Limeira', 'TORNO-01', 'Torno CNC', 'Romi', 2019);
INSERT INTO maquinas_por_planta (planta, maquina_id, tipo, fabricante, ano) VALUES ('PLANTA-LIMEIRA', 'TORNO-02', 'Torno CNC', 'Romi', 2021);
INSERT INTO maquinas_por_planta (planta, maquina_id, tipo, fabricante, ano) VALUES ('PLANTA-LIMEIRA', 'PRENSA-01', 'Prensa hidráulica', 'Schuler', 2015);
INSERT INTO maquinas_por_planta (planta, cidade, maquina_id, tipo, fabricante, ano) VALUES ('PLANTA-SOROCABA', 'Sorocaba', 'FRESA-01', 'Centro de usinagem', 'Haas', 2020);

-- Leituras do TORNO-01 em 15/03/2026
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm) VALUES ('TORNO-01', '2026-03-15', '2026-03-15 08:00:00+0000', 42.1, 1.8, 2400);
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm) VALUES ('TORNO-01', '2026-03-15', '2026-03-15 09:00:00+0000', 55.4, 2.1, 3200);
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm) VALUES ('TORNO-01', '2026-03-15', '2026-03-15 10:00:00+0000', 63.0, 2.6, 3500);
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm) VALUES ('TORNO-01', '2026-03-15', '2026-03-15 11:00:00+0000', 78.9, 7.4, 3500);
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm) VALUES ('TORNO-01', '2026-03-15', '2026-03-15 12:00:00+0000', 66.2, 2.9, 3000);

-- Leituras do TORNO-02 e da PRENSA-01
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm) VALUES ('TORNO-02', '2026-03-15', '2026-03-15 08:00:00+0000', 40.0, 1.5, 2000);
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm) VALUES ('TORNO-02', '2026-03-15', '2026-03-15 10:00:00+0000', 51.3, 1.9, 2800);
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm) VALUES ('PRENSA-01', '2026-03-15', '2026-03-15 09:30:00+0000', 58.7, 4.8, 0);
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm) VALUES ('PRENSA-01', '2026-03-15', '2026-03-15 14:00:00+0000', 61.5, 4.2, 0);
INSERT INTO leituras_por_maquina (maquina_id, dia, momento, temperatura, vibracao, rpm) VALUES ('PRENSA-01', '2026-03-16', '2026-03-16 09:30:00+0000', 60.2, 5.1, 0);

-- Painel: última leitura de cada máquina
INSERT INTO ultima_leitura (maquina_id, momento, temperatura, vibracao, rpm) VALUES ('TORNO-01',  '2026-03-15 12:00:00+0000', 66.2, 2.9, 3000);
INSERT INTO ultima_leitura (maquina_id, momento, temperatura, vibracao, rpm) VALUES ('TORNO-02',  '2026-03-15 10:00:00+0000', 51.3, 1.9, 2800);
INSERT INTO ultima_leitura (maquina_id, momento, temperatura, vibracao, rpm) VALUES ('PRENSA-01', '2026-03-16 09:30:00+0000', 60.2, 5.1, 0);

-- Alertas. A leitura das 11h gerou dois alertas de uma vez: gravá-los em um
-- BATCH garante que os dois entram juntos (atomicidade). Como estão na mesma
-- partição (planta + mês), o batch também é eficiente; batches que espalham
-- escritas por muitas partições sobrecarregam o coordenador e devem ser evitados.
BEGIN BATCH
  INSERT INTO alertas_por_planta (planta, mes, nivel, momento, maquina_id, gravidade, mensagem)
  VALUES ('PLANTA-LIMEIRA', '2026-03', 1, '2026-03-15 11:00:00+0000', 'TORNO-01', 'CRITICO',
          'Vibração 7,4 mm/s acima do limite de 7,1 mm/s');
  INSERT INTO alertas_por_planta (planta, mes, nivel, momento, maquina_id, gravidade, mensagem)
  VALUES ('PLANTA-LIMEIRA', '2026-03', 2, '2026-03-15 11:00:00+0000', 'TORNO-01', 'ALTO',
          'Temperatura 78,9 °C acima de 75 °C');
APPLY BATCH;

INSERT INTO alertas_por_planta (planta, mes, nivel, momento, maquina_id, gravidade, mensagem)
VALUES ('PLANTA-LIMEIRA', '2026-03', 3, '2026-03-15 09:30:00+0000', 'PRENSA-01', 'MEDIO', 'Vibração 4,8 mm/s em zona de atenção');
INSERT INTO alertas_por_planta (planta, mes, nivel, momento, maquina_id, gravidade, mensagem)
VALUES ('PLANTA-LIMEIRA', '2026-03', 3, '2026-03-16 09:30:00+0000', 'PRENSA-01', 'MEDIO', 'Vibração 5,1 mm/s em zona de atenção');

-- Contadores só aceitam UPDATE com incremento/decremento
UPDATE contagem_alertas SET total = total + 2 WHERE maquina_id = 'TORNO-01';
UPDATE contagem_alertas SET total = total + 2 WHERE maquina_id = 'PRENSA-01';
