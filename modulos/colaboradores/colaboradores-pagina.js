// Página 12: singular ou plural depois do total das facetas.
// Colar em Page > JavaScript > Execute when Page Loads.
(function () {
    var total = document.getElementById("cx-colab-total");
    if (!total) {
        return;
    }
    function atualizar() {
        total.dataset.sufixo = total.textContent.trim() === "1" ? " colaborador" : " colaboradores";
    }
    new MutationObserver(atualizar).observe(total, { childList: true, characterData: true, subtree: true });
    atualizar();
})();
