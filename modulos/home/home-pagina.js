// =============================================================================
// Corlix Hub · Home (página 28)
// Cole o BLOCO 1 em Page › JavaScript › Function and Global Variable Declaration
// e o BLOCO 2 em Page › JavaScript › Execute when Page Loads.
// =============================================================================

// ---- BLOCO 1 · Function and Global Variable Declaration ---------------------

// O pkg_home_ui manda as fotos como data-cx-foto="Fotos Colaboradores/x.jpg".
// Aqui o caminho vira URL da pasta de arquivos do app (#APP_FILES#).
function cxHomeCarregarFotos(raiz) {
  (raiz || document).querySelectorAll("img[data-cx-foto]").forEach(function (img) {
    const caminho = img.dataset.cxFoto.split("/").map(encodeURIComponent).join("/");
    img.removeAttribute("data-cx-foto");
    img.src = apex.env.APP_FILES + caminho;
  });
}

// ---- BLOCO 2 · Execute when Page Loads --------------------------------------

cxHomeCarregarFotos();

// "Ver todos" dos aniversariantes abre o diálogo com o mês inteiro
$(document).on("click", "[data-cx-acao='aniversariantes']", function () {
  apex.theme.openRegion("aniversariantes_todos");
});

// Links rápidos ainda sem destino (Holerite digital, Ponto eletrônico, Suporte TI)
$(document).on("click", ".cx-home-atalho[aria-disabled='true']", function (evento) {
  evento.preventDefault();
  apex.message.alert("Este atalho ainda não tem destino configurado.");
});
