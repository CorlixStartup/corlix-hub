// =============================================================================
// Corlix Hub · Otimizar imagens (página 45)
// Cole em Page › JavaScript › Execute when Page Loads.
// Para cada imagem: baixa a original (OBTER_IMAGEM), redesenha num canvas de até
// 1280 x 720 px, gera um JPEG e envia (SALVAR_IMAGEM). O servidor só grava se o
// JPEG for válido e menor que a original; a original fica em IMAGEM_ORIGINAL.
// =============================================================================
(function () {
  const c_largura = 1280;
  const c_altura = 720;
  const c_qualidade = 0.82;

  function status(linha, texto, tipo) {
    const celula = linha && linha.querySelector("[data-cx-img-status]");
    if (celula) {
      celula.textContent = texto;
      celula.className = "cx-img-status" + (tipo ? " is-" + tipo : "");
    }
  }

  function base64ParaBlob(base64, tipo) {
    const binario = atob(base64);
    const bytes = new Uint8Array(binario.length);
    for (let i = 0; i < binario.length; i++) {
      bytes[i] = binario.charCodeAt(i);
    }
    return new Blob([bytes], { type: tipo });
  }

  function paraBase64(blob) {
    return new Promise(function (resolve, reject) {
      const leitor = new FileReader();
      leitor.onload = function () { resolve(String(leitor.result).split(",")[1]); };
      leitor.onerror = reject;
      leitor.readAsDataURL(blob);
    });
  }

  // Reduz para caber em 1280 x 720 sem cortar e sem aumentar. Fundo branco: o JPEG
  // não tem transparência, e um PNG transparente ficaria com fundo preto.
  function comprimir(original) {
    return new Promise(function (resolve, reject) {
      const endereco = URL.createObjectURL(original);
      const img = new Image();
      img.onload = function () {
        const escala = Math.min(1, c_largura / img.naturalWidth, c_altura / img.naturalHeight);
        const canvas = document.createElement("canvas");
        canvas.width = Math.max(1, Math.round(img.naturalWidth * escala));
        canvas.height = Math.max(1, Math.round(img.naturalHeight * escala));
        const ctx = canvas.getContext("2d");
        ctx.fillStyle = "#FFFFFF";
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.imageSmoothingQuality = "high";
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        URL.revokeObjectURL(endereco);
        canvas.toBlob(function (blob) {
          if (blob) { resolve(blob); } else { reject(new Error("conversao")); }
        }, "image/jpeg", c_qualidade);
      };
      img.onerror = function () {
        URL.revokeObjectURL(endereco);
        reject(new Error("leitura"));
      };
      img.src = endereco;
    });
  }

  function tamanho(bytes) {
    return bytes >= 1048576
      ? (bytes / 1048576).toFixed(1).replace(".", ",") + " MB"
      : Math.round(bytes / 1024) + " KB";
  }

  // Devolve true se gravou
  async function otimizar(botao) {
    const linha = botao.closest("[data-cx-img-linha]");
    const id = botao.getAttribute("data-id");
    botao.disabled = true;
    try {
      status(linha, "Baixando...");
      const atual = await apex.server.process("OBTER_IMAGEM", { x01: id }, { dataType: "json" });
      if (!atual.ok) {
        status(linha, atual.mensagem, "erro");
        botao.disabled = false;
        return false;
      }
      const original = base64ParaBlob(atual.imagem, atual.mime);

      status(linha, "Comprimindo...");
      const jpeg = await comprimir(original);
      if (jpeg.size >= original.size) {
        status(linha, "Já está leve (" + tamanho(original.size) + ")", "ok");
        return false;
      }

      status(linha, "Salvando " + tamanho(jpeg.size) + "...");
      const partes = apex.server.chunk(await paraBase64(jpeg));
      const resposta = await apex.server.process("SALVAR_IMAGEM",
        { x01: id, f01: Array.isArray(partes) ? partes : [partes] },
        { dataType: "json" });

      if (resposta.ok) {
        status(linha, "Otimizada: " + resposta.mensagem, "ok");
        botao.hidden = true;
        return true;
      }
      status(linha, resposta.mensagem, "erro");
      botao.disabled = false;
      return false;
    } catch (erro) {
      status(linha, erro && erro.message === "leitura"
        ? "Não foi possível ler essa imagem."
        : "Não foi possível falar com o servidor. Tente de novo.", "erro");
      botao.disabled = false;
      return false;
    }
  }

  $(document).on("click", "[data-cx-img-otimizar]", function () {
    otimizar(this);
  });

  // Uma por vez, para não pesar no servidor
  $(document).on("click", "[data-cx-img-todas]", async function () {
    const todas = this;
    todas.disabled = true;
    const botoes = Array.from(document.querySelectorAll("[data-cx-img-otimizar]"))
      .filter(function (b) { return !b.hidden && !b.disabled; });
    for (const botao of botoes) {
      await otimizar(botao);
    }
    todas.disabled = false;
  });
})();
