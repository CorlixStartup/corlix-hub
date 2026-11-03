// =============================================================================
// Corlix Hub · Suporte TI (página 34)
// Cole em Page › JavaScript › Execute when Page Loads.
// Os eventos ficam no document porque as regiões são atualizadas (Refresh) e o
// HTML delas é trocado.
// =============================================================================

const cxSupRegioes = ["suporte_chamados"];
let cxSupAbaAtual = "cx_sup_abertos";

function cxSupAtualizar() {
  cxSupRegioes.forEach(function (id) {
    const regiao = apex.region(id);
    if (regiao) { regiao.refresh(); }
  });
}

function cxSupErro(mensagem) {
  apex.message.clearErrors();
  apex.message.showErrors([{ type: "error", location: "page", message: mensagem, unsafe: true }]);
}

// --- Abas de "Meus chamados" ---
function cxSupMostrarAba(painel, comFoco) {
  document.querySelectorAll("[data-cx-sup-aba]").forEach(function (aba) {
    const ativa = aba.dataset.cxSupAba === painel;
    aba.classList.toggle("is-ativa", ativa);
    aba.setAttribute("aria-selected", ativa ? "true" : "false");
    aba.tabIndex = ativa ? 0 : -1;
    const conteudo = document.getElementById(aba.dataset.cxSupAba);
    if (conteudo) { conteudo.hidden = !ativa; }
    if (ativa && comFoco) { aba.focus(); }
  });
  cxSupAbaAtual = painel;
}

$(document).on("click", "[data-cx-sup-aba]", function () {
  cxSupMostrarAba(this.dataset.cxSupAba, false);
});

$(document).on("keydown", "[data-cx-sup-aba]", function (evento) {
  if (evento.key === "ArrowRight" || evento.key === "ArrowLeft") {
    evento.preventDefault();
    cxSupMostrarAba(this.dataset.cxSupAba === "cx_sup_abertos" ? "cx_sup_resolvidos" : "cx_sup_abertos", true);
  }
});

// O Refresh recria as abas: volta para a que estava aberta
$(document).on("apexafterrefresh", "#suporte_chamados", function () {
  cxSupMostrarAba(cxSupAbaAtual, false);
});

// --- Busca na base de conhecimento ---
(function () {
  let espera = null;
  let ultima = 0;

  function mostrar(html) {
    const caixa = document.getElementById("cx_sup_resultados");
    if (caixa) { caixa.innerHTML = html; }
  }

  $(document).on("input", "[data-cx-sup-busca]", function () {
    const termo = this.value.trim();
    clearTimeout(espera);
    if (termo.length < 3) {
      ultima += 1; // descarta uma resposta que ainda esteja a caminho
      mostrar("");
      return;
    }
    espera = setTimeout(function () {
      ultima += 1;
      const pedido = ultima;
      apex.server.process("BUSCAR_ARTIGOS", { x01: termo }, { dataType: "json" }).done(function (resposta) {
        if (pedido !== ultima) { return; } // chegou fora de ordem
        if (resposta.ok) {
          mostrar(resposta.html); // HTML montado e escapado pelo pkg_suporte_ui
        } else {
          cxSupErro(resposta.mensagem);
        }
      }).fail(function () {
        cxSupErro("Não foi possível falar com o servidor. Confira sua conexão e tente de novo.");
      });
    }, 300);
  });

  // Enter não envia o formulário da página
  $(document).on("keydown", "[data-cx-sup-busca]", function (evento) {
    if (evento.key === "Enter") { evento.preventDefault(); }
  });
})();

// --- "Sim, encerrar" ---
$(document).on("click", "[data-cx-sup-confirmar]", function () {
  const botao = this;
  botao.disabled = true;
  apex.server.process("CONFIRMAR_SOLUCAO", { x01: botao.dataset.cxSupConfirmar }, { dataType: "json" }).done(function (resposta) {
    if (resposta.ok) {
      apex.message.clearErrors();
      apex.message.showPageSuccess(resposta.mensagem);
      cxSupAtualizar();
    } else {
      cxSupErro(resposta.mensagem);
      botao.disabled = false;
    }
  }).fail(function () {
    cxSupErro("Não foi possível falar com o servidor. Confira sua conexão e tente de novo.");
    botao.disabled = false;
  });
});

// --- Aviso de instabilidade: o "x" vale até o aviso mudar ---
function cxSupAvisosFechados() {
  try {
    return JSON.parse(sessionStorage.getItem("cxSupAvisosFechados")) || [];
  } catch (erro) {
    return [];
  }
}

function cxSupEsconderAvisos() {
  const fechados = cxSupAvisosFechados();
  document.querySelectorAll("[data-cx-sup-aviso]").forEach(function (aviso) {
    if (fechados.indexOf(aviso.dataset.cxSupAviso) >= 0) { aviso.hidden = true; }
  });
}

$(document).on("click", "[data-cx-sup-fechar-aviso]", function () {
  const aviso = this.closest("[data-cx-sup-aviso]");
  aviso.hidden = true;
  try {
    const fechados = cxSupAvisosFechados();
    fechados.push(aviso.dataset.cxSupAviso);
    sessionStorage.setItem("cxSupAvisosFechados", JSON.stringify(fechados));
  } catch (erro) {
    // Sem sessionStorage, o aviso só volta a aparecer ao recarregar
  }
});

cxSupEsconderAvisos();

// Chamado aberto, respondido ou reaberto: o modal fechou
$(document).on("apexafterclosedialog", function (evento, dados) {
  if (dados && dados.successMessage && dados.successMessage.text) {
    apex.message.showPageSuccess(dados.successMessage.text);
  }
  cxSupAtualizar();
});
