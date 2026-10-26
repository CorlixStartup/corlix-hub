// =============================================================================
// Corlix Hub · Busca na intranet (página 29)
// Cole o BLOCO 1 em Page › JavaScript › Function and Global Variable Declaration
// e o BLOCO 2 em Page › JavaScript › Execute when Page Loads.
// =============================================================================

// ---- BLOCO 1 · Function and Global Variable Declaration ---------------------

// O pkg_busca_ui manda as fotos como data-cx-foto="Fotos Colaboradores/x.jpg".
// Aqui o caminho vira URL da pasta de arquivos do app (#APP_FILES#).
function cxBuscaCarregarFotos(raiz) {
  (raiz || document).querySelectorAll("img[data-cx-foto]").forEach(function (img) {
    const caminho = img.dataset.cxFoto.split("/").map(encodeURIComponent).join("/");
    img.removeAttribute("data-cx-foto");
    img.src = apex.env.APP_FILES + caminho;
  });
}

// ---- BLOCO 2 · Execute when Page Loads --------------------------------------

cxBuscaCarregarFotos();
