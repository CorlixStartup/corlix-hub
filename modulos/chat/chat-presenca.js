// Presença na lista de contatos e no cabeçalho da conversa (modulos/chat/Etapas-chat.md §2).
// A cada 30 s, com a aba visível, pergunta ao CH_PRESENCAS a situação de cada colega e só troca a
// classe do ponto (ch-dot--online / --ausente / --offline). Não recarrega a região "Contatos",
// então os grupos de departamento abertos continuam abertos.
(function () {
    const INTERVALO_MS = 30000;
    let enviando = false;

    function aplicar(presencas) {
        document.querySelectorAll(".ch-contact[data-id]").forEach(function (contato) {
            const ponto = contato.querySelector(".ch-dot");
            if (!ponto) {
                return;
            }
            ponto.className = "ch-dot ch-dot--" + (presencas[contato.dataset.id] || "offline");

            // o cabeçalho da conversa copia o ponto do contato aberto
            if (contato.classList.contains("is-active")) {
                const cabecalho = document.querySelector(".ch-head .ch-dot");
                if (cabecalho) {
                    cabecalho.className = ponto.className;
                }
            }
        });
    }

    function atualizar() {
        if (enviando || document.hidden) {
            return;
        }
        enviando = true;
        apex.server.process("CH_PRESENCAS", {}, { dataType: "json", loadingIndicator: null })
            .done(function (resp) {
                if (resp && resp.presencas) {
                    aplicar(resp.presencas);
                }
            })
            .always(function () {
                enviando = false;
            });
    }

    setInterval(atualizar, INTERVALO_MS);
    document.addEventListener("visibilitychange", function () {
        if (!document.hidden) {
            atualizar();
        }
    });
})();
