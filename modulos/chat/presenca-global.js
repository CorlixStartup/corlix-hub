// Presença (modulos/chat/Etapas-chat.md §2): avisa o servidor que a pessoa está usando a app.
// Roda em todas as páginas pela DA "Presença" da Global Page (página 0), só para quem está logado.
// Regras:
//   - no máximo 1 ping por minuto por aba, mesmo navegando entre páginas;
//   - só com a aba visível e com atividade (mouse, teclado, toque) nos últimos 3 min.
//     Parado ou em outra aba, a pessoa deixa de pingar e vira "ausente" depois de 5 min;
//   - dentro de um modal (iframe), quem pinga é a página de baixo.
// Sem (function(){...})() em volta: o APEX já coloca o código da DA dentro de uma função,
// então o "return" do começo funciona e não há parêntese para perder ao copiar.
if (window.cxPresenca || window.self !== window.top) {
    return;
}

const PROCESSO     = "CX_PRESENCA_PING";
const INTERVALO_MS = 60000;   // 1 ping por minuto, no máximo
const ATIVIDADE_MS = 180000;  // sem atividade há 3 min: para de pingar
const CICLO_MS     = 15000;   // de quanto em quanto tempo confere se é hora de pingar
const CHAVE        = "cxPresencaUltimoPing"; // sessionStorage da aba

let ultimaAtividade = Date.now();
let enviando        = false;

function lerUltimoPing() {
    try {
        return Number(sessionStorage.getItem(CHAVE)) || 0;
    } catch (e) {
        return 0;
    }
}

function gravarUltimoPing(momento) {
    try {
        sessionStorage.setItem(CHAVE, String(momento));
    } catch (e) {
        // sem storage: só pinga a cada carregamento de página
    }
}

function ping() {
    const agora = Date.now();
    if (enviando ||
        document.hidden ||
        agora - ultimaAtividade > ATIVIDADE_MS ||
        agora - lerUltimoPing() < INTERVALO_MS) {
        return;
    }

    enviando = true;
    apex.server.process(PROCESSO, {}, { dataType: "json", loadingIndicator: null })
        .done(function () {
            // conta sem colaborador responde {"ok":false}: grava assim mesmo, para não insistir
            gravarUltimoPing(Date.now());
        })
        .always(function () {
            enviando = false;
        });
}

function marcarAtividade() {
    const estavaParado = Date.now() - ultimaAtividade > ATIVIDADE_MS;
    ultimaAtividade = Date.now();
    if (estavaParado) {
        ping(); // voltou depois de um tempo parado: fica online na hora
    }
}

["pointerdown", "pointermove", "keydown", "wheel", "touchstart"].forEach(function (evento) {
    document.addEventListener(evento, marcarAtividade, { passive: true, capture: true });
});

document.addEventListener("visibilitychange", function () {
    if (!document.hidden) {
        marcarAtividade();
        ping();
    }
});

setInterval(ping, CICLO_MS);
ping();

window.cxPresenca = { ping: ping };
