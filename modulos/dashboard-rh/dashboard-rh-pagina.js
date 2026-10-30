// =============================================================================
// Corlix Hub · Dashboard RH (página 20)
// Cole em Page › JavaScript › Execute when Page Loads.
// Os eventos ficam no document porque as regiões são atualizadas (Refresh) ao
// mudar o período ou fechar a página 23, e o HTML delas é trocado.
// =============================================================================

// "Ver em tabela" / "Ver gráfico" no card de turnover
$(document).on("click", "[data-cx-dash-alternar]", function () {
  const card = this.closest(".cx-dash-turnover");
  const verTabela = this.getAttribute("aria-pressed") !== "true";

  card.querySelectorAll("[data-cx-dash-grafico]").forEach(function (el) {
    el.hidden = verTabela;
  });
  card.querySelector("[data-cx-dash-tabela]").hidden = !verTabela;
  this.setAttribute("aria-pressed", String(verTabela));
  this.textContent = verTabela ? "Ver gráfico" : "Ver em tabela";
});

// "Ver todas as solicitações" / "Ver todas as formações" abrem o diálogo
// (o valor do atributo é o HTML DOM ID da região Inline Dialog)
$(document).on("click", "[data-cx-dash-dialogo]", function () {
  apex.theme.openRegion(this.dataset.cxDashDialogo);
});
