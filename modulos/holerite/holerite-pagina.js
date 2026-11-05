// =============================================================================
// Corlix Hub · Holerite digital (página 9)
// Cole em Page › JavaScript › Execute when Page Loads.
// "Ocultar valores" troca o texto de verdade, para que os valores também saiam do
// leitor de tela. A escolha fica no navegador e sobrevive à troca de mês.
// =============================================================================

(function () {
  const CHAVE = "cx-holerite-ocultar";
  const MASCARA = "••••••";
  let oculto = false;

  function lerPreferencia() {
    try { return window.localStorage.getItem(CHAVE) === "S"; } catch (erro) { return false; }
  }

  function gravarPreferencia(valor) {
    try { window.localStorage.setItem(CHAVE, valor ? "S" : "N"); } catch (erro) { /* só não lembra */ }
  }

  function aplicarValores(esconder) {
    document.querySelectorAll("[data-cx-hol-valor]").forEach(function (el) {
      if (el.dataset.cxHolOriginal === undefined) { el.dataset.cxHolOriginal = el.textContent; }
      el.textContent = esconder ? MASCARA : el.dataset.cxHolOriginal;
    });
    document.querySelectorAll("[data-cx-hol-barra]").forEach(function (el) {
      el.classList.toggle("is-oculta", esconder);
    });
  }

  function aplicarBotao(esconder) {
    const botao = document.querySelector("[data-cx-hol-ocultar]");
    if (!botao) { return; }
    botao.setAttribute("aria-pressed", esconder ? "true" : "false");
    botao.querySelector("[data-cx-hol-ocultar-texto]").textContent = esconder ? "Mostrar valores" : "Ocultar valores";
    botao.querySelector("[data-cx-hol-icone-ocultar]").hidden = esconder;
    botao.querySelector("[data-cx-hol-icone-mostrar]").hidden = !esconder;
  }

  function definirOculto(valor) {
    oculto = valor;
    aplicarValores(valor);
    aplicarBotao(valor);
  }

  definirOculto(lerPreferencia());

  $(document).on("click", "[data-cx-hol-ocultar]", function () {
    definirOculto(!oculto);
    gravarPreferencia(oculto);
  });

  // O PDF sai sempre com os valores, mesmo com a tela oculta. Os eventos também
  // cobrem quem imprime pelo menu do navegador.
  window.addEventListener("beforeprint", function () { aplicarValores(false); });
  window.addEventListener("afterprint", function () { aplicarValores(oculto); });

  $(document).on("click", "[data-cx-hol-imprimir]", function () {
    window.print();
  });

  // Seletor de ano: cada opção traz o link com checksum do mês mais recente daquele ano
  $(document).on("change", "[data-cx-hol-ano]", function () {
    apex.navigation.redirect(this.value);
  });

  // Pedido enviado: o modal da página 22 fechou
  $(document).on("apexafterclosedialog", function (evento, dados) {
    if (dados && dados.successMessage && dados.successMessage.text) {
      apex.message.showPageSuccess(dados.successMessage.text);
    }
  });
})();
