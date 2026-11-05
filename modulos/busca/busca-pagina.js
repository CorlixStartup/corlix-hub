// =============================================================================
// Corlix Hub · Busca na intranet (página 29)
// Cole o BLOCO 1 em Page › JavaScript › Function and Global Variable Declaration
// e o BLOCO 2 em Page › JavaScript › Execute when Page Loads.
// =============================================================================

// ---- BLOCO 1 · Function and Global Variable Declaration ---------------------

// O pkg_busca_ui manda as fotos como data-cx-foto="Fotos Colaboradores/x.jpg".
// Aqui o nome vira URL da página 44, que entrega a foto do bucket privado.
function cxBuscaCarregarFotos(raiz) {
  (raiz || document).querySelectorAll("img[data-cx-foto]").forEach(function (img) {
    const nome = img.dataset.cxFoto.split("/").pop();
    img.removeAttribute("data-cx-foto");
    img.src = location.pathname.replace(/[^/]*$/, "") + "foto?session=" + apex.env.APP_SESSION + "&x01=" + encodeURIComponent(nome);
  });
}

// ---- BLOCO 2 · Execute when Page Loads --------------------------------------

cxBuscaCarregarFotos();
