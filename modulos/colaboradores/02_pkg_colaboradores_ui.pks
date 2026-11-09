-- Interface das páginas 12 e 14; instalar antes do corpo.
create or replace package pkg_colaboradores_ui authid definer as
  function render_cabecalho return clob;
  function render_cabecalho_cadastro (p_id_colaborador in number) return clob;
end pkg_colaboradores_ui;
/
