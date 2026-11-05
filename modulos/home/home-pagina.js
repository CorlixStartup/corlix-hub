// =============================================================================
// Corlix Hub · Home (página 1, "Início")
// Cole o BLOCO 1 em Page › JavaScript › Function and Global Variable Declaration
// e o BLOCO 2 em Page › JavaScript › Execute when Page Loads.
// =============================================================================

// ---- BLOCO 1 · Function and Global Variable Declaration ---------------------

// O pkg_home_ui manda as fotos como data-cx-foto="Fotos Colaboradores/x.jpg".
// Aqui o nome vira URL da página 44, que entrega a foto do bucket privado.
function cxHomeCarregarFotos(raiz) {
  (raiz || document).querySelectorAll("img[data-cx-foto]").forEach(function (img) {
    const nome = img.dataset.cxFoto.split("/").pop();
    img.removeAttribute("data-cx-foto");
    img.src = "foto?session=" + apex.env.APP_SESSION + "&x01=" + encodeURIComponent(nome);
  });
}

// Comunicados em carrossel: a Cards vira uma faixa com rolagem horizontal
// (CSS em home.css) e aqui ganham as setas e os pontos. Refeito a cada refresh.
function cxHomeCarrossel(regiao) {
  const corpo = regiao.querySelector(".t-Region-body");
  const trilho = regiao.querySelector(".a-CardView-items");
  if (!corpo) return;
  corpo.querySelectorAll(".cx-carrossel__nav").forEach(function (el) { el.remove(); });
  if (!trilho) return;

  const slides = trilho.querySelectorAll(".a-CardView-item");
  if (slides.length < 2) return;

  const nav = document.createElement("div");
  nav.className = "cx-carrossel__nav";
  nav.innerHTML =
    '<button type="button" class="cx-carrossel__seta cx-carrossel__seta--anterior" aria-label="Comunicado anterior">' +
    '<span class="fa fa-chevron-left" aria-hidden="true"></span></button>' +
    '<button type="button" class="cx-carrossel__seta cx-carrossel__seta--proxima" aria-label="Próximo comunicado">' +
    '<span class="fa fa-chevron-right" aria-hidden="true"></span></button>' +
    '<div class="cx-carrossel__pontos"></div>';
  const pontos = nav.querySelector(".cx-carrossel__pontos");
  slides.forEach(function (_, i) {
    const ponto = document.createElement("button");
    ponto.type = "button";
    ponto.className = "cx-carrossel__ponto";
    ponto.setAttribute("aria-label", "Comunicado " + (i + 1) + " de " + slides.length);
    ponto.addEventListener("click", function () { irPara(i); });
    pontos.appendChild(ponto);
  });
  corpo.appendChild(nav);

  function atual() {
    return Math.round(trilho.scrollLeft / trilho.clientWidth);
  }
  function irPara(i) {
    const total = slides.length;
    trilho.scrollTo({ left: ((i + total) % total) * trilho.clientWidth });
  }
  function marcar() {
    const i = atual();
    pontos.querySelectorAll(".cx-carrossel__ponto").forEach(function (ponto, j) {
      ponto.setAttribute("aria-current", j === i ? "true" : "false");
    });
  }

  nav.querySelector(".cx-carrossel__seta--anterior").addEventListener("click", function () { irPara(atual() - 1); });
  nav.querySelector(".cx-carrossel__seta--proxima").addEventListener("click", function () { irPara(atual() + 1); });
  trilho.addEventListener("scroll", function () { window.requestAnimationFrame(marcar); }, { passive: true });
  marcar();
}

// ---- BLOCO 2 · Execute when Page Loads --------------------------------------

cxHomeCarregarFotos();

document.querySelectorAll(".cx-home-carrossel").forEach(cxHomeCarrossel);

// Depois do "Novo comunicado" a DA dá refresh na Cards: monta as setas de novo
$(document).on("apexafterrefresh", ".cx-home-carrossel", function () {
  cxHomeCarrossel(this);
});

// "Ver todos" das celebrações abre o diálogo com o mês inteiro
$(document).on("click", "[data-cx-acao='aniversariantes']", function () {
  apex.theme.openRegion("aniversariantes_todos");
});

// Links rápidos ainda sem destino (Suporte TI)
$(document).on("click", ".cx-home-atalho[aria-disabled='true']", function (evento) {
  evento.preventDefault();
  apex.message.alert("Este atalho ainda não tem destino configurado.");
});
