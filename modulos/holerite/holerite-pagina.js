// =============================================================================
// Corlix Hub · Holerite digital (página 9)
// Cole em Page › JavaScript › Execute when Page Loads.
// Os valores chegam ocultos do package e a página sempre abre assim. "Mostrar valores"
// troca o texto de verdade, para que os valores também saiam do leitor de tela, e só
// vale enquanto a pessoa troca de mês ou de ano dentro da própria página.
// =============================================================================

(function () {
  const CHAVE = "cx-holerite-mostrar";
  const MASCARA = "••••••";
  let oculto = true;

  // Lê e apaga: o "mostrar" vale só para a próxima carga, a da troca de mês
  function veioDaTrocaDeMesComValores() {
    try {
      const valor = window.sessionStorage.getItem(CHAVE) === "S";
      window.sessionStorage.removeItem(CHAVE);
      return valor;
    } catch (erro) { return false; }
  }

  function lembrarParaATrocaDeMes() {
    try {
      if (oculto) { window.sessionStorage.removeItem(CHAVE); }
      else { window.sessionStorage.setItem(CHAVE, "S"); }
    } catch (erro) { /* só não lembra */ }
  }

  // A versão anterior guardava a escolha para sempre neste navegador
  try { window.localStorage.removeItem("cx-holerite-ocultar"); } catch (erro) { /* nada a limpar */ }

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

  definirOculto(!veioDaTrocaDeMesComValores());

  $(document).on("click", "[data-cx-hol-ocultar]", function () {
    definirOculto(!oculto);
  });

  // Clique num mês da lista lateral
  $(document).on("click", ".cx-hol-lista__item", lembrarParaATrocaDeMes);

  // O PDF sai sempre com os valores, mesmo com a tela oculta. Os eventos também
  // cobrem quem imprime pelo menu do navegador.
  window.addEventListener("beforeprint", function () { aplicarValores(false); });
  window.addEventListener("afterprint", function () { aplicarValores(oculto); });

  $(document).on("click", "[data-cx-hol-imprimir]", function () {
    window.print();
  });

  // Seletor de ano: cada opção traz o link com checksum do mês mais recente daquele ano
  $(document).on("change", "[data-cx-hol-ano]", function () {
    lembrarParaATrocaDeMes();
    apex.navigation.redirect(this.value);
  });

  // Pedido enviado: o modal da página 22 fechou
  $(document).on("apexafterclosedialog", function (evento, dados) {
    if (dados && dados.successMessage && dados.successMessage.text) {
      apex.message.showPageSuccess(dados.successMessage.text);
    }
  });
})();
