# Lista de exercícios — Monitoramento IoT (Cassandra)

1. Por que a tabela `leituras_por_maquina` usa `(maquina_id, dia)` como chave de partição, e não apenas `maquina_id`? O que aconteceria após um ano de leituras a cada segundo?
2. Escreva a consulta que retorna as leituras do TORNO-02 em 15/03/2026 com rotação acima de 2.500 rpm. Ela funciona sem `ALLOW FILTERING`? Explique.
3. A manutenção precisa da consulta: *"todas as leituras com vibração acima de 7 mm/s em um dia, de qualquer máquina"*. Proponha uma **nova tabela** que atenda a essa consulta de forma eficiente e escreva o `CREATE TABLE`, um `INSERT` e o `SELECT`.
4. Escreva os comandos para registrar um novo alerta crítico da FRESA-01 na planta de Sorocaba, incluindo o incremento do contador.
5. Explique a diferença entre a consistência `ONE` e `QUORUM` em um cluster com fator de replicação 3. Como alterar a consistência no `cqlsh`?
6. Compare o modelo deste repositório com um modelo relacional normalizado para o mesmo problema: o que se ganha e o que se perde?

As respostas estão em [`respostas.md`](respostas.md).
