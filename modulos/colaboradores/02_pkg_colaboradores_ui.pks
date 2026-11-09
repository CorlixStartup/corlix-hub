-- Interface da página 12; instalar antes do corpo.
create or replace package pkg_colaboradores_ui authid definer as
  function render_cabecalho return clob;
end pkg_colaboradores_ui;
/
