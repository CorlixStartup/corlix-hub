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
    img.src = location.pathname.replace(/[^/]*$/, "") + "foto?session=" + apex.env.APP_SESSION + "&x01=" + encodeURIComponent(nome);
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

  // "Não lido" vem no corpo do card (HTML Expression) e vai para o lado do botão
  slides.forEach(function (slide) {
    const marca = slide.querySelector("[data-cx-nao-lido]");
    const acoes = slide.querySelector(".a-CardView-actions");
    if (marca && acoes) { acoes.appendChild(marca); }
  });

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

// "Ponto de hoje" (guia §7): relógio e horas trabalhadas. A hora vem do servidor
// (data-segundos) e aqui só avança; o refresh do hero troca o painel e recomeça.
// Mesma conta do relógio da página 30 (ponto-pagina.js).
let cxHomePontoBase = null;

function cxHomePontoRelogio() {
  const painel = document.querySelector("[data-cx-home-ponto]");
  if (!painel) { return; }

  function dois(n) { return String(n).padStart(2, "0"); }
  function horas(min) { return Math.floor(min / 60) + "h" + dois(min % 60); }

  if (!cxHomePontoBase || cxHomePontoBase.painel !== painel) {
    cxHomePontoBase = { painel: painel, inicio: Date.now(), segundos: Number(painel.dataset.segundos) };
  }
  const passados = Math.floor((Date.now() - cxHomePontoBase.inicio) / 1000);
  const agora = (cxHomePontoBase.segundos + passados) % 86400;
  const hora = painel.querySelector("[data-cx-home-ponto-hora]");
  const texto = dois(Math.floor(agora / 3600)) + ":" + dois(Math.floor(agora / 60) % 60);
  if (hora.textContent !== texto) { hora.textContent = texto; }

  if (painel.dataset.correndo === "S") {
    const minutos = Math.floor(((cxHomePontoBase.segundos % 60) + passados) / 60);
    const trabalhados = Number(painel.dataset.trabalhados) + minutos;
    const meta = Number(painel.dataset.meta);
    painel.querySelector("[data-cx-home-ponto-resumo]").textContent = horas(trabalhados) + " trabalhadas · "
      + (trabalhados >= meta ? "jornada completa" : "faltam " + horas(meta - trabalhados));
  }
}

// Ajax Callbacks da página 1: respondem {ok, mensagem}
function cxHomeChamar(processo, dados, aoConcluir, botao) {
  if (botao) { botao.disabled = true; }
  return apex.server.process(processo, dados, { dataType: "json" })
    .done(function (resposta) {
      if (resposta.ok) {
        apex.message.clearErrors();
        if (aoConcluir) { aoConcluir(resposta); }
      } else {
        apex.message.clearErrors();
        apex.message.showErrors([{ type: "error", location: "page", message: resposta.mensagem, unsafe: true }]);
      }
    })
    .fail(function () {
      apex.message.showErrors([{ type: "error", location: "page",
        message: "Não foi possível falar com o servidor. Confira sua conexão e tente de novo.", unsafe: false }]);
    })
    .always(function () { if (botao) { botao.disabled = false; } });
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

// "Registrar saída" (e entrada, intervalo, retorno): Ajax Callback REGISTRAR_MARCACAO,
// o mesmo da página 30, que responde {ok, mensagem}. Depois, refaz o hero.
$(document).on("click", "[data-cx-home-registrar]", function () {
  const botao = this;
  botao.disabled = true;
  apex.server.process("REGISTRAR_MARCACAO", { x01: botao.dataset.cxHomeRegistrar }, { dataType: "json" })
    .done(function (resposta) {
      apex.message.clearErrors();
      if (resposta.ok) {
        apex.message.showPageSuccess(resposta.mensagem);
        apex.region("home_hero").refresh();
      } else {
        apex.message.showErrors([{ type: "error", location: "page", message: resposta.mensagem, unsafe: true }]);
      }
    })
    .fail(function () {
      apex.message.showErrors([{ type: "error", location: "page",
        message: "Não foi possível falar com o servidor. Confira sua conexão e tente de novo.", unsafe: false }]);
    })
    .always(function () { botao.disabled = false; });
});

// Pedido de ajuste enviado pela página 31 ("Justificar"): a lista de pendências muda
$(document).on("apexafterclosedialog", function () {
  const pendencias = apex.region("home_pendencias");
  if (pendencias) { pendencias.refresh(); }
});

cxHomePontoRelogio();
setInterval(cxHomePontoRelogio, 1000);

// "Ler comunicado": marca como lido e só depois abre o comunicado
$(document).on("click", ".cx-home-carrossel .a-CardView-button", function (evento) {
  const item = this.closest(".a-CardView-item");
  const destino = this.href;
  if (!item || !item.dataset.id || !destino) { return; }
  evento.preventDefault();
  apex.server.process("MARCAR_LIDO", { x01: item.dataset.id }, { dataType: "json" })
    .always(function () { apex.navigation.redirect(destino); });
});

// "Mostrar valor" do pagamento: a página sempre abre com o valor oculto (como a p9)
$(document).on("click", "[data-cx-home-mostrar]", function () {
  const mostrar = this.getAttribute("aria-pressed") !== "true";
  this.setAttribute("aria-pressed", mostrar ? "true" : "false");
  this.setAttribute("aria-label", mostrar ? "Ocultar valor" : "Mostrar valor");
  this.title = this.getAttribute("aria-label");
  this.closest(".cx-home-indicador").querySelectorAll("[data-cx-home-valor]").forEach(function (el) {
    el.textContent = mostrar ? el.dataset.cxHomeOriginal : "••••••";
  });
});

// "Responder pesquisa": o link abre o formulário em outra aba; aqui só registra
// a participação e tira o card da Home
$(document).on("click", "[data-cx-home-pesquisa]", function () {
  cxHomeChamar("RESPONDER_PESQUISA", { x01: this.dataset.cxHomePesquisa }, function () {
    const regiao = apex.region("home_pesquisa");
    if (regiao) { regiao.refresh(); }
  });
});

// "Dar feedback" (Meu gestor) e "Parabenizar" (Celebrações): preenchem e abrem o diálogo
$(document).on("click", "[data-cx-home-feedback]", function () {
  apex.item("P1_FB_DESTINATARIO").setValue(this.dataset.cxHomeFeedback);
  apex.item("P1_FB_TIPO").setValue(this.dataset.cxHomeFeedbackTipo || "RECONHECIMENTO");
  apex.item("P1_FB_TEXTO").setValue(this.dataset.cxHomeFeedbackTexto || "");
  document.querySelectorAll("[data-cx-home-fb-nome]").forEach(function (el) {
    el.textContent = this.dataset.cxHomeFeedbackNome;
  }, this);
  // O APEX desenha os itens antes do HTML da região: o "Para <nome>" sobe para o topo
  const corpo = document.querySelector("#home_dlg_feedback .t-DialogRegion-body");
  const para = corpo && corpo.querySelector(".cx-home-fb-para");
  if (para && corpo.firstElementChild !== para) { corpo.prepend(para); }
  apex.theme.openRegion("home_dlg_feedback");
});

$(document).on("click", ".cx-home-fb-cancelar", function () {
  apex.theme.closeRegion("home_dlg_feedback");
});

$(document).on("click", ".cx-home-fb-enviar", function () {
  cxHomeChamar("SALVAR_FEEDBACK", {
    x01: apex.item("P1_FB_DESTINATARIO").getValue(),
    x02: apex.item("P1_FB_TIPO").getValue(),
    x03: apex.item("P1_FB_TEXTO").getValue()
  }, function (resposta) {
    apex.theme.closeRegion("home_dlg_feedback");
    apex.message.showPageSuccess(resposta.mensagem);
  }, this);
});

