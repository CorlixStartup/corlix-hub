const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, WidthType, ShadingType,
  AlignmentType, HeadingLevel, PageOrientation, LevelFormat, Header, Footer, PageNumber,
  TableOfContents, BorderStyle, PageBreak, VerticalAlign,
} = require('docx');
const { modulos, conhecidos, matriz, BASE } = require('./casos.js');

const SAIDA = process.argv[2];
const FONTE = 'Arial';
const AZUL = '1F4E79';
const AZUL_CLARO = 'DCE6F1';
const CINZA = 'F2F2F2';
const AMBAR = '9C5700';
const LARG = 15398; // A4 paisagem com margens de 720

// ---------- helpers ----------
function runs(texto, base = {}) {
  // **negrito** simples
  const partes = String(texto).split(/(\*\*[^*]+\*\*)/g).filter(Boolean);
  return partes.map(p => p.startsWith('**')
    ? new TextRun({ font: FONTE, ...base, text: p.slice(2, -2), bold: true })
    : new TextRun({ font: FONTE, ...base, text: p }));
}
const P = (texto, opt = {}) => new Paragraph({ children: runs(texto, opt.run || {}), spacing: { after: 80, ...(opt.spacing || {}) }, alignment: opt.alignment, ...(opt.extra || {}) });
const H1 = t => new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun({ font: FONTE, text: t })] });
const H2 = t => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun({ font: FONTE, text: t })] });
const bullet = (t, nivel = 0) => new Paragraph({ numbering: { reference: 'bullets', level: nivel }, children: runs(t), spacing: { after: 40 } });

// Numeração manual (1., 2. / a), b)) para reiniciar em cada célula em qualquer leitor.
const numerada = (itens, ref) => itens.map((t, i) => new Paragraph({
  indent: { left: 300, hanging: 300 }, spacing: { after: 30 },
  children: [new TextRun({ font: FONTE, size: 17, bold: true, color: AZUL, text: (ref === 'passos' ? `${i + 1}.` : `${String.fromCharCode(97 + i)})`) + ' ' }), ...runs(t, { size: 17 })],
}));

const borda = { style: BorderStyle.SINGLE, size: 4, color: 'BFBFBF' };
const bordas = { top: borda, bottom: borda, left: borda, right: borda };

function celula(conteudo, largura, opt = {}) {
  const filhos = Array.isArray(conteudo) ? conteudo : [P(conteudo, { run: { size: opt.size || 17, bold: opt.bold, color: opt.color } , spacing: { after: 20 } })];
  return new TableCell({
    children: filhos.length ? filhos : [new Paragraph('')],
    width: { size: largura, type: WidthType.DXA },
    borders: bordas,
    shading: opt.fill ? { fill: opt.fill, type: ShadingType.CLEAR, color: 'auto' } : undefined,
    margins: { top: 60, bottom: 60, left: 90, right: 90 },
    verticalAlign: opt.vAlign || VerticalAlign.TOP,
    columnSpan: opt.span,
  });
}

function tabela(cabecalho, linhas, larguras) {
  const total = larguras.reduce((a, b) => a + b, 0);
  return new Table({
    width: { size: total, type: WidthType.DXA },
    columnWidths: larguras,
    rows: [
      new TableRow({ tableHeader: true, cantSplit: true, children: cabecalho.map((c, i) => celula(c, larguras[i], { bold: true, color: 'FFFFFF', fill: AZUL })) }),
      ...linhas.map((l, n) => new TableRow({ cantSplit: true, children: l.map((c, i) => celula(c, larguras[i], { fill: n % 2 ? CINZA : undefined })) })),
    ],
  });
}

// ---------- tabela de casos ----------
const COLS = [950, 2700, 4300, 4100, 800, 1450, 1098]; // soma 15398
function tabelaCasos(casos) {
  const cab = ['ID', 'Cenário e pré-condição', 'Passos', 'Resultado esperado', 'Prior.', 'Resultado', 'Obs. / nº do defeito'];
  const linhas = casos.map(c => {
    const cenario = [
      P(c.titulo, { run: { bold: true, size: 17 }, spacing: { after: 40 } }),
      P('Pré-condição: ' + c.pre, { run: { size: 16, color: '404040' }, spacing: { after: 40 } }),
    ];
    if (c.grava) cenario.push(P('Grava dados (ver seção 5)', { run: { size: 16, bold: true, color: 'C00000' }, spacing: { after: 40 } }));
    if (c.nota) cenario.push(P('Atenção: ' + c.nota, { run: { size: 16, italics: true, color: AMBAR }, spacing: { after: 20 } }));
    const status = ['☐ OK', '☐ Falha', '☐ Bloqueado', '☐ N/A'].map(s => P(s, { run: { size: 16 }, spacing: { after: 10 } }));
    const prioCor = { Alta: 'C00000', 'Média': AMBAR, Baixa: '375623' }[c.prio];
    return new TableRow({ cantSplit: false, children: [
      celula([P(c.id, { run: { bold: true, size: 17 } })], COLS[0]),
      celula(cenario, COLS[1]),
      celula(numerada(c.passos, 'passos'), COLS[2]),
      celula(numerada(c.esperado, 'esperado'), COLS[3]),
      celula([P(c.prio, { run: { bold: true, size: 16, color: prioCor } })], COLS[4]),
      celula(status, COLS[5]),
      celula([new Paragraph('')], COLS[6]),
    ] });
  });
  return new Table({
    width: { size: LARG, type: WidthType.DXA }, columnWidths: COLS,
    rows: [new TableRow({ tableHeader: true, cantSplit: true, children: cab.map((c, i) => celula(c, COLS[i], { bold: true, color: 'FFFFFF', fill: AZUL })) }), ...linhas],
  });
}

// ---------- conteúdo ----------
const totalCasos = modulos.reduce((a, m) => a + m.casos.length, 0);
const contaPrio = p => modulos.reduce((a, m) => a + m.casos.filter(c => c.prio === p).length, 0);
const contaGrava = modulos.reduce((a, m) => a + m.casos.filter(c => c.grava).length, 0);

const filhos = [];
const SO = process.env.SO_CASOS;

// Capa
filhos.push(
  new Paragraph({ spacing: { before: 2200, after: 200 }, alignment: AlignmentType.LEFT, children: [new TextRun({ font: FONTE, text: 'Corlix Hub', size: 28, color: '595959', font: FONTE })] }),
  new Paragraph({ heading: HeadingLevel.TITLE, children: [new TextRun({ font: FONTE, text: 'Mapa de testes · Visão do colaborador' })] }),
  P('Roteiro de QA manual para o perfil Colaborador da app Oracle APEX 100 (CORLIXHUB)', { run: { size: 26, color: '404040' }, spacing: { after: 600 } }),
  tabela(['Item', 'Valor'], [
    ['Versão do documento', '1.0 · 17/11/2026'],
    ['Base conferida', 'Fichas das páginas e guias dos módulos (backup de DEV 84f8625, estado de 13/11/2026; branch DEV em 3c6fe39)'],
    ['Ambiente', 'DEV · ' + BASE],
    ['Perfil testado', 'Colaborador comum (papel Colaborador, sem RH, gestão, TI ou publicação)'],
    ['Total de casos', `${totalCasos} casos em ${modulos.length} grupos · ${contaPrio('Alta')} de prioridade alta · ${contaGrava} gravam dados`],
    ['Responsável pela execução', ''],
    ['Período de execução', ''],
  ], [3600, 11798]),
  new Paragraph({ children: [new PageBreak()] }),
);

// Sumário
filhos.push(
  P('Sumário', { run: { size: 32, bold: true, color: AZUL }, spacing: { after: 160 } }),
  new TableOfContents('Sumário', { hyperlink: true, headingStyleRange: '1-2' }),
  P('Se o sumário aparecer vazio, clique com o botão direito sobre ele e escolha "Atualizar campo".', { run: { size: 16, italics: true, color: '595959' } }),
  new Paragraph({ children: [new PageBreak()] }),
);

// 1. Objetivo e escopo
filhos.push(
  H1('1. Objetivo e escopo'),
  P('Este mapa guia o teste manual de tudo o que um colaborador comum vê e faz no Corlix Hub. Cada caso traz a pré-condição, os passos numerados, o resultado esperado e o espaço para marcar o resultado.'),
  H2('Dentro do escopo'),
  bullet('Login, header (busca, sino, menu do usuário) e menu lateral.'),
  bullet('Início, Meu perfil, Organograma, Chat, Busca e Comunicados.'),
  bullet('Holerite Digital e Histórico de carreira, com o pedido de correção ao RH.'),
  bullet('Ponto eletrônico, com o pedido de ajuste e a assinatura do espelho.'),
  bullet('Suporte TI na visão de quem abre chamado (abrir, responder, reabrir, confirmar e consultar a base de conhecimento).'),
  bullet('Controle de acesso: o colaborador não abre páginas de RH, gestão, TI e da equipe do Corlix Hub, nem pelo endereço.'),
  bullet('Responsividade, teclado e outros navegadores.'),
  H2('Fora do escopo'),
  bullet('Telas e ações de RH, gestor, aprovador de ponto, Suporte TI e equipe do Corlix Hub. Essas contas só aparecem como apoio, quando um caso do colaborador depende de uma resposta delas.'),
  bullet('Geração da folha (job mensal), cargas de dados e testes direto no banco.'),
  bullet('Telas do protótipo que ainda não existem na app (PDI, Feedbacks, Avaliações, Minha equipe, Minhas aprovações).'),
);

// 2. Ambiente e contas
filhos.push(
  H1('2. Ambiente e contas'),
  P('**Endereço base (DEV):** ' + BASE),
  P('Para abrir uma página pelo endereço, acrescente o alias ao endereço base. Exemplo: ' + BASE + 'holerite-digital'),
  P('**Navegador principal:** Google Chrome atualizado. Antes de cada rodada, limpe o cache com Ctrl+Shift+R (Cmd+Shift+R no Mac).'),
  H2('Contas necessárias'),
  P('As senhas são fornecidas pelo time e não devem ser anotadas neste documento.'),
  tabela(['Sigla', 'Conta', 'Para que serve', 'Login usado (preencher)'], [
    ['CA', 'Colaborador A: só o papel Colaborador, com colaborador vinculado, gestor cadastrado, holerites, jornada de ponto e foto', 'Conta principal de quase todos os casos', ''],
    ['CB', 'Colaborador B: colega da mesma empresa, de outra equipe, sem relação de gestão com CA', 'Privacidade, chat entre duas pessoas e comparação de dados', ''],
    ['CS', 'Conta APEX sem colaborador vinculado e sem o papel Admin RH', 'Casos de conta sem vínculo (ACE-08 e ACE-09)', ''],
    ['CE', 'Colaborador de outra empresa (opcional)', 'Isolamento entre empresas (ACE-10)', ''],
    ['Apoio', 'Gestor de CA (ou RH, ex.: TESTE.RH) e uma conta com o papel Suporte TI (CT)', 'Responder pedidos de correção e de ajuste e atender chamados', ''],
  ], [900, 6000, 5000, 3498]),
  P('Depois de mudar o papel de uma conta, saia e entre de novo: as permissões são lidas no login.', { run: { italics: true }, spacing: { before: 120 } }),
);

// 3. Preparação
filhos.push(
  H1('3. Preparação antes de cada rodada'),
  bullet('Confirme com o time qual versão está em DEV e anote na seção 10.'),
  bullet('Confirme que CA tem: gestor, holerites de pelo menos 2 meses (de preferência em 2 anos), jornada de ponto, uma marcação ausente e um espelho a assinar.'),
  bullet('Confirme que a empresa tem comunicados (um fixado e um não lido por CA), assuntos e artigos do Suporte TI e uma pesquisa de clima ativa.'),
  bullet('Combine com o time o dia e a conta para os casos que registram ponto (as marcações não podem ser apagadas).'),
  bullet('Tenha uma imagem pequena (PNG ou JPG, menos de 5 MB) e um arquivo .exe qualquer para os testes de anexo.'),
  bullet('Use uma janela normal para CA e uma anônima para a segunda conta, para não misturar sessões.'),
);

// 4. Como executar e registrar
filhos.push(
  H1('4. Como executar e registrar'),
  bullet('Execute os casos na ordem do grupo; alguns dependem do anterior (indicado na pré-condição).'),
  bullet('Marque um resultado por caso: **OK** (tudo como esperado), **Falha** (algum item do resultado esperado não aconteceu), **Bloqueado** (não deu para executar, ex.: falta dado ou conta) ou **N/A** (não se aplica nesta rodada).'),
  bullet('Em toda Falha, tire print da tela inteira (com a barra de endereço) e abra um defeito na seção 9. Anote o número do defeito na coluna "Obs.".'),
  bullet('Se o caso tem a observação "Atenção", o comportamento já é conhecido. Marque o resultado real; se bater com a observação, escreva "conhecido" em Obs. e não abra defeito novo.'),
  bullet('Nunca digite dados reais de pessoas. Em textos livres, use "Teste QA · ignorar".'),
  H2('Prioridade'),
  tabela(['Prioridade', 'Significado'], [
    ['Alta', 'Segurança, privacidade, dinheiro ou funções principais. Falha aqui bloqueia a entrega.'],
    ['Média', 'Função importante com contorno possível.'],
    ['Baixa', 'Visual, texto ou conveniência.'],
  ], [2400, 12998]),
  H2('Severidade do defeito'),
  tabela(['Severidade', 'Quando usar'], [
    ['Crítica', 'Dado de outra pessoa ou empresa exposto, acesso indevido, perda de dado ou valor errado.'],
    ['Alta', 'Função principal não funciona e não há contorno.'],
    ['Média', 'Função não funciona, mas há contorno; mensagem errada.'],
    ['Baixa', 'Layout, texto, idioma ou alinhamento.'],
  ], [2400, 12998]),
);

// 5. Dados gravados
filhos.push(
  H1('5. Dados gravados durante os testes'),
  P(`${contaGrava} casos gravam dados no banco de DEV. Eles estão marcados com "Grava dados" na coluna Cenário. A limpeza é feita pelo time no SQL Commands, seguindo o fluxo docs/agentes/fluxos/testar-na-app.md §3. Ao fim da rodada, entregue ao time a lista do que foi gravado (conta, data e hora, caso).`),
  tabela(['O que grava', 'Casos', 'Pode ser desfeito?'], [
    ['Marcações de ponto', 'INI-04, PON-02, PON-04, PON-05', 'Não. Marcações são imutáveis; use dia e conta combinados'],
    ['Assinatura do espelho', 'PON-15', 'Só pelo time, no banco'],
    ['Pedidos de ajuste de ponto', 'PON-11, PON-14', 'Sim, pelo time'],
    ['Leitura de comunicado e resposta da pesquisa', 'INI-09, INI-17', 'Sim, pelo time'],
    ['Feedback', 'INI-16', 'Sim, pelo time'],
    ['Mensagens do chat', 'CHT-04 a CHT-07', 'Sim, pelo time'],
    ['Pedidos de correção ao RH', 'HOL-10, HC-10, HC-11', 'Sim, pelo time'],
    ['Chamados, mensagens e anexos do Suporte TI', 'SUP-06, SUP-08 a SUP-10, SUP-13', 'Sim, pelo time'],
  ], [5000, 4600, 5798]),
);

// 6. Resumo
filhos.push(
  H1('6. Resumo dos casos'),
  tabela(['Grupo', 'Páginas', 'Casos', 'Alta', 'Média', 'Baixa'],
    [...modulos.map(m => [`${m.cod} · ${m.nome}`, m.paginas, String(m.casos.length),
      String(m.casos.filter(c => c.prio === 'Alta').length), String(m.casos.filter(c => c.prio === 'Média').length), String(m.casos.filter(c => c.prio === 'Baixa').length)]),
     ['Total', '', String(totalCasos), String(contaPrio('Alta')), String(contaPrio('Média')), String(contaPrio('Baixa'))]],
    [4400, 6198, 1200, 1200, 1200, 1200]),
);

// 7. Casos
const MARCA = H1('7. Casos de teste'); filhos.push(new Paragraph({ children: [new PageBreak()] }), MARCA);
modulos.forEach((m, i) => {
  if (i > 0) filhos.push(new Paragraph({ children: [new PageBreak()] }));
  filhos.push(H2(`7.${i + 1} ${m.cod} · ${m.nome}`));
  filhos.push(P(`**Páginas:** ${m.paginas}. ${m.intro}`));
  filhos.push(tabelaCasos(m.casos));
});

// 8. Conhecidos
filhos.push(
  new Paragraph({ children: [new PageBreak()] }),
  H1('8. Comportamentos já conhecidos'),
  P('Situação registrada nas fichas das páginas em 13/11/2026. Se o teste mostrar exatamente isso, marque o resultado real e escreva "conhecido" em Obs., sem abrir defeito novo. Se o comportamento mudou, registre.'),
  tabela(['Área', 'Comportamento'], conhecidos, [2800, 12598]),
  H2('Matriz de acesso esperada'),
  tabela(['Página', 'Nº', 'Como o colaborador chega', 'Colaborador comum', 'Conta sem colaborador'], matriz, [3900, 2200, 3700, 2900, 2698]),
);

// 9. Defeitos
filhos.push(
  new Paragraph({ children: [new PageBreak()] }),
  H1('9. Registro de defeitos'),
  P('Um defeito por linha. Em "Passos", descreva o mínimo para reproduzir; anexe o print com o mesmo número.'),
  tabela(['Nº', 'Caso', 'Severidade', 'Descrição (obtido x esperado)', 'Passos para reproduzir', 'Evidência', 'Situação'],
    Array.from({ length: 12 }, (_, i) => [`D-${String(i + 1).padStart(2, '0')}`, '', '', '', '', '', '']),
    [900, 1100, 1300, 4800, 4300, 1500, 1498]),
);

// 10. Execução
filhos.push(
  H1('10. Registro de execução'),
  tabela(['Rodada', 'Data', 'Testador', 'Versão em DEV', 'Navegador', 'OK', 'Falha', 'Bloq.', 'N/A', 'Observações'],
    Array.from({ length: 4 }, (_, i) => [String(i + 1), '', '', '', '', '', '', '', '', '']),
    [1000, 1300, 2200, 1900, 1700, 800, 800, 800, 800, 4098]),
  P('Critério de aceite sugerido: todos os casos de prioridade Alta com OK (ou "conhecido" aprovado pelo time) e nenhum defeito Crítico ou Alto aberto.', { spacing: { before: 200 } }),
  P('Aprovação do time: ______________________________   Data: ____/____/______', { spacing: { before: 400 } }),
);

if (SO) { const i = filhos.findIndex(f => f === MARCA); filhos.splice(0, i + Number(SO)); }
// ---------- documento ----------
const doc = new Document({
  creator: 'Corlix Hub', title: 'Mapa de testes · Visão do colaborador', description: 'Roteiro de QA manual do perfil Colaborador',
  styles: {
    default: { document: { run: { font: FONTE, size: 20 } } },
    paragraphStyles: [
      { id: 'Title', name: 'Title', basedOn: 'Normal', run: { font: FONTE, size: 52, bold: true, color: AZUL }, paragraph: { spacing: { before: 0, after: 200 }, keepNext: true } },
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { font: FONTE, size: 32, bold: true, color: AZUL }, paragraph: { spacing: { before: 360, after: 160 }, keepNext: true, outlineLevel: 0 } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { font: FONTE, size: 26, bold: true, color: AZUL }, paragraph: { spacing: { before: 240, after: 120 }, keepNext: true, outlineLevel: 1 } },
    ],
  },
  numbering: { config: [
    { reference: 'bullets', levels: [{ level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 270 } } } }] },
    { reference: 'passos', levels: [{ level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 300, hanging: 260 } } } }] },
    { reference: 'esperado', levels: [{ level: 0, format: LevelFormat.LOWER_LETTER, text: '%1)', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 300, hanging: 260 } } } }] },
  ] },
  sections: [{
    properties: { page: { size: { width: 11906, height: 16838, orientation: PageOrientation.LANDSCAPE }, margin: { top: 900, bottom: 900, left: 720, right: 720 } } },
    headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ font: FONTE, text: 'Corlix Hub · Mapa de testes · Visão do colaborador', size: 16, color: '808080' })] })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ font: FONTE, text: 'Página ', size: 16, color: '808080' }), new TextRun({ font: FONTE, children: [PageNumber.CURRENT], size: 16, color: '808080' }), new TextRun({ font: FONTE, text: ' de ', size: 16, color: '808080' }), new TextRun({ font: FONTE, children: [PageNumber.TOTAL_PAGES], size: 16, color: '808080' })] })] }) },
    children: filhos,
  }],
});

Packer.toBuffer(doc).then(b => { fs.writeFileSync(SAIDA, b); console.log('ok', SAIDA, totalCasos, 'casos', contaPrio('Alta'), 'alta', contaGrava, 'gravam'); });
