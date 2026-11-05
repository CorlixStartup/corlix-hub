--------------------------------------------------------------------------------
-- Corlix Hub · Holerite digital (página 9) · 00 · cálculo da folha · corpo
-- Substitui a versão do banco (database/ddl/09-plsql-corpos.sql). As contas não
-- mudaram. Saiu o corte de admissão em 01/06/2026, e o cálculo de cada pessoa virou
-- gerar_holerite. render continua igual.
--------------------------------------------------------------------------------
create or replace package body pkg_holerite as

    PROCEDURE gerar_holerite(p_id_colaborador IN NUMBER, p_mes IN NUMBER, p_ano IN NUMBER) IS
        v_salario_base NUMBER(10,2);
        v_inss         NUMBER(10,2);
        v_irrf         NUMBER(10,2);
        v_vt           NUMBER(10,2);
        v_tot_desc     NUMBER(10,2);
        v_liquido      NUMBER(10,2);
        v_id_holerite  NUMBER;
        v_base_irrf    NUMBER;
    BEGIN
        SELECT NVL(car.salario_base, 0)
          INTO v_salario_base
          FROM colaborador col
          JOIN cargo car ON col.id_cargo = car.id_cargo
         WHERE col.id_colaborador = p_id_colaborador;

        IF v_salario_base <= 0 THEN
            RETURN;
        END IF;

        IF v_salario_base <= 1412 THEN v_inss := v_salario_base * 0.075;
        ELSIF v_salario_base <= 2666.68 THEN v_inss := (1412 * 0.075) + ((v_salario_base - 1412) * 0.09);
        ELSIF v_salario_base <= 4000.03 THEN v_inss := (1412 * 0.075) + ((2666.68 - 1412) * 0.09) + ((v_salario_base - 2666.68) * 0.12);
        ELSE v_inss := 908.85;
        END IF;

        v_vt := v_salario_base * 0.06;

        v_base_irrf := v_salario_base - v_inss;
        IF v_base_irrf <= 2259.20 THEN v_irrf := 0;
        ELSIF v_base_irrf <= 2826.65 THEN v_irrf := (v_base_irrf * 0.075) - 169.44;
        ELSIF v_base_irrf <= 3751.05 THEN v_irrf := (v_base_irrf * 0.15) - 381.44;
        ELSIF v_base_irrf <= 4664.68 THEN v_irrf := (v_base_irrf * 0.225) - 662.77;
        ELSE v_irrf := (v_base_irrf * 0.275) - 896.00;
        END IF;

        IF v_irrf < 0 THEN v_irrf := 0; END IF;

        v_tot_desc := ROUND(v_inss + v_irrf + v_vt, 2);
        v_liquido  := ROUND(v_salario_base - v_tot_desc, 2);

        DELETE FROM colaborador_holerite
         WHERE id_colaborador = p_id_colaborador
           AND mes_referencia = p_mes
           AND ano_referencia = p_ano;

        INSERT INTO colaborador_holerite (id_colaborador, mes_referencia, ano_referencia, data_pagamento, salario_base, total_proventos, total_descontos, valor_liquido)
        VALUES (p_id_colaborador, p_mes, p_ano, LAST_DAY(TO_DATE('01/' || p_mes || '/' || p_ano, 'DD/MM/YYYY')), v_salario_base, v_salario_base, v_tot_desc, v_liquido)
        RETURNING id_holerite INTO v_id_holerite;

        INSERT INTO holerite_itens (id_holerite, tipo, descricao, referencia, valor)
        VALUES (v_id_holerite, 'P', 'Salário Base', '30 dias', v_salario_base);

        INSERT INTO holerite_itens (id_holerite, tipo, descricao, referencia, valor)
        VALUES (v_id_holerite, 'D', 'INSS', 'Tabela Oficial', v_inss);

        IF v_irrf > 0 THEN
            INSERT INTO holerite_itens (id_holerite, tipo, descricao, referencia, valor)
            VALUES (v_id_holerite, 'D', 'IRRF', 'Tabela Oficial', v_irrf);
        END IF;

        INSERT INTO holerite_itens (id_holerite, tipo, descricao, referencia, valor)
        VALUES (v_id_holerite, 'D', 'Vale Transporte', '6,00%', v_vt);
    END gerar_holerite;

    PROCEDURE gerar_folha_mensal(p_mes IN NUMBER, p_ano IN NUMBER) IS
        v_fim_mes CONSTANT DATE := ADD_MONTHS(TO_DATE('01/' || p_mes || '/' || p_ano, 'DD/MM/YYYY'), 1);
    BEGIN
        FOR c IN (
            SELECT col.id_colaborador
              FROM colaborador col
             WHERE col.data_admissao < v_fim_mes
        ) LOOP
            gerar_holerite(c.id_colaborador, p_mes, p_ano);
        END LOOP;
        COMMIT;
    END gerar_folha_mensal;

    FUNCTION render(p_mes IN NUMBER, p_ano IN NUMBER) RETURN CLOB IS
        v_html  CLOB;
        v_chunk VARCHAR2(32767);
        v_count NUMBER := 0;
    BEGIN
        DBMS_LOB.CREATETEMPORARY(v_html, TRUE);

        DECLARE
            v_m NUMBER := NVL(p_mes, 10);
            v_a NUMBER := NVL(p_ano, 2026);
        BEGIN
            SELECT COUNT(*) INTO v_count
              FROM colaborador_holerite
             WHERE mes_referencia = v_m AND ano_referencia = v_a;

            IF v_count = 0 THEN
                gerar_folha_mensal(v_m, v_a);
            END IF;

            -- FILTRAGEM ATUALIZADA USANDO LOGIN_APEX E EMAIL
            FOR h IN (
                SELECT ch.id_holerite, col.nome_completo, car.nome, ch.total_proventos, ch.total_descontos, ch.valor_liquido
                  FROM colaborador_holerite ch
                  JOIN colaborador col ON ch.id_colaborador = col.id_colaborador
                  JOIN cargo car ON col.id_cargo = car.id_cargo
                 WHERE ch.mes_referencia = v_m
                   AND ch.ano_referencia = v_a
                   AND (
                        UPPER(col.login_apex) = UPPER(V('APP_USER'))
                        OR UPPER(col.email) = UPPER(V('APP_USER'))
                   )
                 ORDER BY col.nome_completo
            ) LOOP
                v_chunk := '
                <div class="holerite-card">
                    <div class="holerite-header">
                        <div>
                            <h2>CORLIXHUB - TECNOLOGIA E SERVICOS</h2>
                            <p><strong>Demonstrativo de Pagamento de Salário</strong></p>
                        </div>
                        <div style="text-align: right;">
                            <p><strong>Referência:</strong> ' || LPAD(v_m, 2, '0') || '/' || v_a || '</p>
                        </div>
                    </div>
                    <table class="holerite-info">
                        <tr>
                            <td><strong>Colaborador:</strong> ' || h.nome_completo || '</td>
                            <td><strong>Cargo:</strong> ' || h.nome || '</td>
                        </tr>
                    </table>
                    <table class="holerite-table">
                        <thead>
                            <tr>
                                <th>Descrição</th>
                                <th>Referência</th>
                                <th style="text-align: right;">Proventos (R$)</th>
                                <th style="text-align: right;">Descontos (R$)</th>
                            </tr>
                        </thead>
                        <tbody>';

                DBMS_LOB.APPEND(v_html, TO_CLOB(v_chunk));

                FOR i IN (
                    SELECT tipo, descricao, referencia, valor
                      FROM holerite_itens
                     WHERE id_holerite = h.id_holerite
                     ORDER BY tipo DESC, id_item ASC
                ) LOOP
                    v_chunk := '
                    <tr>
                        <td>' || i.descricao || '</td>
                        <td>' || NVL(i.referencia, '-') || '</td>
                        <td style="text-align: right;">' || CASE WHEN i.tipo = 'P' THEN TO_CHAR(i.valor, 'FM999G990D00') ELSE '' END || '</td>
                        <td style="text-align: right;">' || CASE WHEN i.tipo = 'D' THEN TO_CHAR(i.valor, 'FM999G990D00') ELSE '' END || '</td>
                    </tr>';
                    DBMS_LOB.APPEND(v_html, TO_CLOB(v_chunk));
                END LOOP;

                v_chunk := '
                        </tbody>
                    </table>
                    <div class="holerite-totals">
                        <div><span>Total Bruto:</span> R$ ' || TO_CHAR(h.total_proventos, 'FM999G990D00') || '</div>
                        <div><span>Total Descontos:</span> R$ ' || TO_CHAR(h.total_descontos, 'FM999G990D00') || '</div>
                        <div class="net-salary"><span>LÍQUIDO A RECEBER:</span> R$ ' || TO_CHAR(h.valor_liquido, 'FM999G990D00') || '</div>
                    </div>
                </div><br/>';
                DBMS_LOB.APPEND(v_html, TO_CLOB(v_chunk));
            END LOOP;
        END;

        RETURN v_html;
    END render;

end pkg_holerite;
/
