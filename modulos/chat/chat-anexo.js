// Anexos do chat (modulos/chat/Etapas-chat.md §4).
// Três jeitos de anexar: botão de clipe, arrastar e soltar sobre a conversa, ou Ctrl+V de uma imagem.
// O arquivo fica "pendente" acima do campo até a pessoa clicar em Enviar (ou apertar Enter).
// Com anexo pendente, este código assume o envio no lugar da DA "Enviar Mensagem":
// manda arquivo + texto ao CH_ENVIAR_ANEXO e recarrega a conversa.
(function () {
    const MAX_BYTES  = 10 * 1024 * 1024; // 10 MB, o mesmo limite do pkg_chat_ui
    const EXTENSOES  = ["xlsx", "xls", "xlsm", "xlsb", "xltx", "csv",
                        "docx", "doc", "docm", "dotx", "rtf",
                        "pptx", "ppt", "pptm", "ppsx", "pps", "potx",
                        "jpg", "jpeg", "png", "gif", "webp", "bmp"];
    const IMAGENS    = ["jpg", "jpeg", "png", "gif", "webp", "bmp"];

    const chat    = document.querySelector(".ch-chat");
    const campo   = document.getElementById("ch-texto");
    const entrada = document.getElementById("ch-arquivo");
    const previa  = document.querySelector(".ch-anexo-previa");
    if (!chat || !campo || !entrada || !previa) {
        console.warn("chAnexo: falta o HTML do passo 4.4 (clipe, ch-arquivo ou ch-anexo-previa)");
        return;
    }

    let pendente = null;  // File escolhido e ainda não enviado
    let urlPrevia = null; // miniatura local da imagem pendente
    let enviando = false;

    function extensao(nome) {
        const m = /\.([^.\\/]+)$/.exec(nome || "");
        return m ? m[1].toLowerCase() : "";
    }

    function tamanhoTexto(bytes) {
        return bytes < 1024 * 1024
            ? Math.max(1, Math.round(bytes / 1024)) + " KB"
            : (bytes / 1024 / 1024).toFixed(1).replace(".", ",") + " MB";
    }

    function erro(mensagem) {
        apex.message.clearErrors();
        apex.message.showErrors([{ type: "error", location: "page", message: mensagem, unsafe: false }]);
    }

    function conversaAberta() {
        return chat.classList.contains("is-aberto") && !!apex.item("P4_CANAL_ID").getValue();
    }

    // ---- arquivo pendente (prévia acima do campo) ----
    function limpar() {
        pendente = null;
        if (urlPrevia) {
            URL.revokeObjectURL(urlPrevia);
            urlPrevia = null;
        }
        previa.replaceChildren();
        previa.hidden = true;
        entrada.value = "";
    }

    function selecionar(arquivo) {
        if (!arquivo) {
            return;
        }
        if (!conversaAberta()) {
            erro("Abra uma conversa antes de anexar um arquivo.");
            return;
        }
        const ext = extensao(arquivo.name);
        if (EXTENSOES.indexOf(ext) < 0) {
            erro("Tipo de arquivo não aceito. Envie Excel, Word, PowerPoint ou imagem (JPG, PNG, GIF, WEBP ou BMP).");
            return;
        }
        if (arquivo.size > MAX_BYTES) {
            erro("O arquivo pode ter até 10 MB.");
            return;
        }
        if (arquivo.size === 0) {
            erro("O arquivo está vazio.");
            return;
        }

        limpar();
        apex.message.clearErrors();
        pendente = arquivo;

        // monta a prévia com elementos (textContent), nunca com o nome do arquivo em HTML
        const cartao = document.createElement("div");
        cartao.className = "ch-anexo-previa-item";

        if (IMAGENS.indexOf(ext) >= 0) {
            urlPrevia = URL.createObjectURL(arquivo);
            const img = document.createElement("img");
            img.src = urlPrevia;
            img.alt = "";
            cartao.appendChild(img);
        } else {
            const selo = document.createElement("span");
            selo.className = "ch-anexo-ext";
            selo.textContent = ext.toUpperCase();
            cartao.appendChild(selo);
        }

        const info = document.createElement("span");
        info.className = "ch-anexo-info";
        const nome = document.createElement("b");
        nome.textContent = arquivo.name;
        const tam = document.createElement("small");
        tam.textContent = tamanhoTexto(arquivo.size);
        info.append(nome, tam);
        cartao.appendChild(info);

        const remover = document.createElement("button");
        remover.type = "button";
        remover.className = "ch-anexo-remover";
        remover.setAttribute("aria-label", "Remover anexo");
        remover.title = "Remover anexo";
        remover.textContent = "×";
        remover.addEventListener("click", function () {
            limpar();
            campo.focus();
        });
        cartao.appendChild(remover);

        previa.appendChild(cartao);
        previa.hidden = false;
        campo.focus();
    }

    // ---- 1) botão de clipe ----
    document.querySelector(".ch-clip").addEventListener("click", function () {
        if (!conversaAberta()) {
            erro("Abra uma conversa antes de anexar um arquivo.");
            return;
        }
        entrada.click();
    });
    entrada.addEventListener("change", function () {
        selecionar(entrada.files[0]);
    });

    // ---- 2) arrastar e soltar sobre a conversa ----
    function temArquivo(evento) {
        const tipos = evento.dataTransfer && evento.dataTransfer.types;
        return !!tipos && Array.prototype.indexOf.call(tipos, "Files") >= 0;
    }

    let profundidade = 0; // dragenter/dragleave disparam também nos filhos
    chat.addEventListener("dragenter", function (e) {
        if (!temArquivo(e) || !conversaAberta()) {
            return;
        }
        e.preventDefault();
        profundidade++;
        chat.classList.add("is-arrastando");
    });
    chat.addEventListener("dragover", function (e) {
        if (!temArquivo(e) || !conversaAberta()) {
            return;
        }
        e.preventDefault();
        e.dataTransfer.dropEffect = "copy";
    });
    chat.addEventListener("dragleave", function () {
        profundidade = Math.max(0, profundidade - 1);
        if (profundidade === 0) {
            chat.classList.remove("is-arrastando");
        }
    });
    chat.addEventListener("drop", function (e) {
        if (!temArquivo(e)) {
            return;
        }
        e.preventDefault();
        profundidade = 0;
        chat.classList.remove("is-arrastando");
        if (e.dataTransfer.files.length > 1) {
            erro("Envie um arquivo por vez. O primeiro foi anexado.");
        }
        selecionar(e.dataTransfer.files[0]);
    });

    // soltar fora da conversa não pode abrir o arquivo no navegador (e sair do chat)
    ["dragover", "drop"].forEach(function (tipo) {
        document.addEventListener(tipo, function (e) {
            if (temArquivo(e) && !chat.contains(e.target)) {
                e.preventDefault();
            }
        });
    });

    // ---- 3) Ctrl+V de imagem no campo de mensagem ----
    campo.addEventListener("paste", function (e) {
        const arquivos = e.clipboardData && e.clipboardData.files;
        if (arquivos && arquivos.length) {
            e.preventDefault();
            selecionar(arquivos[0]);
        }
    });

    // ---- envio ----
    function regiaoMensagens() {
        const porId = document.getElementById("msgs");
        if (porId) {
            return porId;
        }
        const relatorio = document.querySelector(".ch-chat [id^='report_'][id$='_catch']");
        return relatorio ? relatorio.closest("[id^='R']") : null;
    }

    function lerBase64(arquivo) {
        return new Promise(function (resolve, reject) {
            const leitor = new FileReader();
            leitor.onload = function () {
                // "data:<tipo>;base64,AAAA..." -> só a parte depois da vírgula
                resolve(String(leitor.result).split(",")[1] || "");
            };
            leitor.onerror = function () {
                reject(leitor.error);
            };
            leitor.readAsDataURL(arquivo);
        });
    }

    function enviar() {
        if (enviando) {
            return;
        }
        if (!conversaAberta()) {
            erro("Abra uma conversa antes de enviar.");
            return;
        }

        const botao = document.querySelector(".ch-enviar");
        const arquivo = pendente;
        enviando = true;
        botao.disabled = true;
        chat.classList.add("is-enviando-anexo");

        lerBase64(arquivo)
            .then(function (base64) {
                return apex.server.process("CH_ENVIAR_ANEXO", {
                    x01: apex.item("P4_CANAL_ID").getValue(),
                    x02: arquivo.name,
                    x03: campo.value.trim(),
                    p_clob_01: base64
                }, { dataType: "json", loadingIndicator: ".ch-composer" });
            })
            .then(function (resp) {
                if (resp && resp.ok) {
                    limpar();
                    campo.value = "";
                    if (window.chChat) {
                        chChat.irParaFim();
                    }
                    const regiao = regiaoMensagens();
                    if (regiao) {
                        apex.region(regiao.id).refresh();
                    }
                } else {
                    erro((resp && resp.mensagem) || "Não foi possível enviar o arquivo. Tente de novo.");
                }
            })
            .catch(function () {
                erro("Não foi possível enviar o arquivo. Confira a conexão e tente de novo.");
            })
            .then(function () {
                enviando = false;
                botao.disabled = false;
                chat.classList.remove("is-enviando-anexo");
                campo.focus();
            });
    }

    // Com anexo pendente, o clique em Enviar (e o Enter, que clica no botão) vem para cá.
    // Fase de captura: roda antes da DA "Enviar Mensagem" e impede que ela grave só o texto.
    document.addEventListener("click", function (e) {
        if (pendente && e.target.closest && e.target.closest(".ch-enviar")) {
            e.preventDefault();
            e.stopPropagation();
            enviar();
        }
    }, true);

    // trocar de contato descarta o anexo pendente (como o rascunho do texto)
    document.addEventListener("click", function (e) {
        if (e.target.closest && e.target.closest(".ch-contact")) {
            limpar();
        }
    }, true);
})();
