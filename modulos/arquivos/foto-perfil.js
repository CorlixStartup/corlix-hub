// =============================================================================
// Corlix Hub · Envio da foto de perfil (página 2)
// Cole no fim de Page › JavaScript › Execute when Page Loads.
// O recorte e a conversão acontecem aqui: o JPEG novo sai quadrado e sem
// metadados, como a localização gravada pelo celular. O servidor confere de novo.
// =============================================================================
(function () {
  const c_tamanho = 512;
  const c_max_bytes = 5 * 1024 * 1024;
  let imagemPronta = null;

  function aviso(texto, ehErro) {
    const caixa = document.getElementById("perfil-foto-status");
    if (caixa) {
      caixa.textContent = texto;
      caixa.classList.toggle("is-erro", !!ehErro);
    }
  }

  function botaoSalvar() {
    return document.querySelector("[data-acao='salvar-foto']");
  }

  function converter(arquivo) {
    return new Promise(function (resolve, reject) {
      const endereco = URL.createObjectURL(arquivo);
      const img = new Image();
      img.onload = function () {
        const lado = Math.min(img.naturalWidth, img.naturalHeight);
        const canvas = document.createElement("canvas");
        canvas.width = c_tamanho;
        canvas.height = c_tamanho;
        canvas.getContext("2d").drawImage(
          img,
          (img.naturalWidth - lado) / 2, (img.naturalHeight - lado) / 2, lado, lado,
          0, 0, c_tamanho, c_tamanho
        );
        URL.revokeObjectURL(endereco);
        canvas.toBlob(function (blob) {
          if (blob) { resolve(blob); } else { reject(new Error("conversao")); }
        }, "image/jpeg", 0.85);
      };
      img.onerror = function () {
        URL.revokeObjectURL(endereco);
        reject(new Error("leitura"));
      };
      img.src = endereco;
    });
  }

  function paraBase64(blob) {
    return new Promise(function (resolve, reject) {
      const leitor = new FileReader();
      leitor.onload = function () { resolve(String(leitor.result).split(",")[1]); };
      leitor.onerror = reject;
      leitor.readAsDataURL(blob);
    });
  }

  function mostrarPrevia(blob) {
    const caixa = document.querySelector(".perfil-modal-avatar .perfil-avatar");
    if (!caixa) { return; }
    let img = caixa.querySelector("img");
    if (!img) {
      img = document.createElement("img");
      img.alt = "";
      caixa.appendChild(img);
    }
    img.src = URL.createObjectURL(blob);
  }

  $(document).on("change", "#input-foto-upload", function () {
    const arquivo = this.files && this.files[0];
    const salvar = botaoSalvar();
    imagemPronta = null;
    if (salvar) { salvar.disabled = true; }
    if (!arquivo) { return; }

    if (["image/jpeg", "image/png"].indexOf(arquivo.type) < 0) {
      aviso("Escolha uma imagem em JPG ou PNG.", true);
      return;
    }
    if (arquivo.size > c_max_bytes) {
      aviso("A imagem precisa ter até 5 MB.", true);
      return;
    }

    aviso("Preparando a imagem...");
    converter(arquivo).then(function (blob) {
      imagemPronta = blob;
      mostrarPrevia(blob);
      if (botaoSalvar()) { botaoSalvar().disabled = false; }
      aviso("Confira a prévia e clique em Salvar foto.");
    }).catch(function () {
      aviso("Não foi possível ler essa imagem. Tente outra, em JPG ou PNG.", true);
    });
  });

  $(document).on("click", "[data-acao='salvar-foto']", function () {
    const salvar = this;
    if (!imagemPronta) { return; }
    salvar.disabled = true;
    aviso("Salvando...");

    paraBase64(imagemPronta).then(function (base64) {
      const partes = apex.server.chunk(base64);
      return apex.server.process("SALVAR_FOTO",
        { f01: Array.isArray(partes) ? partes : [partes] },
        { dataType: "json" });
    }).then(function (resposta) {
      if (resposta.ok) {
        aviso(resposta.mensagem);
        location.reload();
      } else {
        aviso(resposta.mensagem, true);
        salvar.disabled = false;
      }
    }, function () {
      aviso("Não foi possível falar com o servidor. Confira sua conexão e tente de novo.", true);
      salvar.disabled = false;
    });
  });
})();
