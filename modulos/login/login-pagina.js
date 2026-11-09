// Corlix Hub · Login (página 9999). Colar em Page › JavaScript › Execute when Page Loads.
// "Esqueci minha senha": o botão leva data-cx-login-dialogo com o Static ID do
// diálogo inline (mesmo padrão do Ponto, p. 30).
$(document).on("click", "[data-cx-login-dialogo]", function (evento) {
  evento.preventDefault();
  apex.theme.openRegion(this.dataset.cxLoginDialogo);
});
