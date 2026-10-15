# Respostas — Monitoramento IoT (Cassandra)

## 1
Cada partição é armazenada inteira em um mesmo conjunto de nós. Com apenas `maquina_id`, todas as leituras de uma máquina ficariam em uma partição que cresce para sempre. A uma leitura por segundo, seriam cerca de 31,5 milhões de linhas por ano em uma única partição, o que deixa leituras lentas, compactação pesada e carga desigual entre os nós (*hot spot*). Incluir o `dia` na chave cria uma partição limitada (até 86.400 linhas) por máquina por dia. Essa técnica se chama ***bucketing***.

## 2
```sql
SELECT momento, rpm FROM leituras_por_maquina
WHERE maquina_id = 'TORNO-02' AND dia = '2026-03-15' AND rpm > 2500
ALLOW FILTERING;
```
Sem `ALLOW FILTERING` o Cassandra recusa, porque `rpm` não faz parte da chave primária. Aqui o custo é aceitável, porque a filtragem acontece **dentro de uma única partição**, já identificada. O antipadrão é usar `ALLOW FILTERING` sem informar a partição.

## 3
```sql
CREATE TABLE leituras_criticas_por_dia (
    dia         date,
    vibracao    decimal,
    momento     timestamp,
    maquina_id  text,
    temperatura decimal,
    PRIMARY KEY ((dia), vibracao, momento, maquina_id)
) WITH CLUSTERING ORDER BY (vibracao DESC, momento DESC, maquina_id ASC);

INSERT INTO leituras_criticas_por_dia (dia, vibracao, momento, maquina_id, temperatura)
VALUES ('2026-03-15', 7.4, '2026-03-15 11:00:00+0000', 'TORNO-01', 78.9);

SELECT * FROM leituras_criticas_por_dia WHERE dia = '2026-03-15' AND vibracao > 7;
```
A aplicação passa a gravar cada leitura nas duas tabelas (desnormalização). Para manter as partições pequenas, ela pode gravar nesta tabela apenas as leituras acima de um limiar.

## 4
```sql
INSERT INTO alertas_por_planta (planta, mes, nivel, momento, maquina_id, gravidade, mensagem)
VALUES ('PLANTA-SOROCABA', '2026-03', 1, '2026-03-20 15:42:00+0000', 'FRESA-01', 'CRITICO',
        'Temperatura do fuso acima de 90 °C');

UPDATE contagem_alertas SET total = total + 1 WHERE maquina_id = 'FRESA-01';
```
O contador não pode ficar no mesmo *batch* logged do `INSERT`: o Cassandra não mistura escritas de *counter* e de tabelas comuns em um mesmo *batch*.

## 5
Com fator de replicação 3, `ONE` responde assim que **uma** réplica confirma: é mais rápido e mais disponível, mas pode ler um dado desatualizado. `QUORUM` exige **duas** das três réplicas. Se a escrita e a leitura usarem `QUORUM`, sempre há uma réplica em comum, o que garante ler o dado mais recente (consistência forte), ao custo de maior latência. No `cqlsh`: `CONSISTENCY QUORUM;`.

## 6
| Ganha | Perde |
|---|---|
| Escrita massiva e linear com o número de nós | Junções e consultas *ad hoc* |
| Alta disponibilidade, sem ponto único de falha | Integridade referencial (não há chave estrangeira) |
| Leitura previsível: cada consulta lê uma partição | Os dados ficam duplicados, e manter a coerência é responsabilidade da aplicação |
| TTL nativo para dados temporários | Transações ACID entre várias linhas e tabelas (há só *lightweight transactions*) |
