--------------------------------------------------------------------------------
-- Corlix Hub · Suporte TI · 02 · dados iniciais
-- Reexecutável: só insere o que falta e não altera o que já existe.
-- Rode de novo quando uma empresa nova for cadastrada.
--
-- CONTEÚDO DE EXEMPLO: o ramal, o telefone, o horário e os artigos vêm do
-- protótipo ou são genéricos. A TI precisa revisá-los antes de liberar a página
-- (guia, §1.3). Os acessos iniciais só definem a ordem de "Artigos mais acessados".
--------------------------------------------------------------------------------
set define off

declare
  procedure assunto (p_empresa in number, p_nome in varchar2, p_icone in varchar2, p_ordem in number) is
  begin
    insert into suporte_assunto (id_empresa, nm_assunto, cd_icone, nr_ordem)
    select p_empresa, p_nome, p_icone, p_ordem
      from dual
     where not exists (select 1 from suporte_assunto a
                        where a.id_empresa = p_empresa and a.nm_assunto = p_nome);
  end assunto;

  procedure sistema (p_empresa in number, p_nome in varchar2, p_ordem in number) is
  begin
    insert into suporte_sistema (id_empresa, nm_sistema, nr_ordem)
    select p_empresa, p_nome, p_ordem
      from dual
     where not exists (select 1 from suporte_sistema s
                        where s.id_empresa = p_empresa and s.nm_sistema = p_nome);
  end sistema;

  procedure artigo (
    p_empresa in number, p_assunto in varchar2, p_titulo in varchar2, p_resumo in varchar2,
    p_corpo in varchar2, p_palavras in varchar2, p_min in number, p_acessos in number
  ) is
  begin
    insert into suporte_artigo (id_empresa, id_assunto, ds_titulo, ds_resumo, ds_corpo, ds_palavras, nr_min_leitura, nr_acessos)
    select p_empresa, a.id_assunto, p_titulo, p_resumo, p_corpo, p_palavras, p_min, p_acessos
      from suporte_assunto a
     where a.id_empresa = p_empresa
       and a.nm_assunto = p_assunto
       and not exists (select 1 from suporte_artigo x
                        where x.id_empresa = p_empresa and x.ds_titulo = p_titulo);
  end artigo;
begin
  for e in (select id_empresa from empresa) loop
    insert into suporte_config (id_empresa, ds_ramal, ds_telefone, ds_horario)
    select e.id_empresa, '4000', '(11) 3000-4000', 'Seg a sex, das 8h às 19h'
      from dual
     where not exists (select 1 from suporte_config c where c.id_empresa = e.id_empresa);

    assunto(e.id_empresa, 'Acesso e senhas',        'key',     10);
    assunto(e.id_empresa, 'E-mail e agenda',        'mail',    20);
    assunto(e.id_empresa, 'Notebook e periféricos', 'laptop',  30);
    assunto(e.id_empresa, 'Rede e VPN',             'wifi',    40);
    assunto(e.id_empresa, 'Sistemas e permissões',  'janela',  50);
    assunto(e.id_empresa, 'Impressoras',            'printer', 60);

    sistema(e.id_empresa, 'E-mail e agenda', 10);
    sistema(e.id_empresa, 'VPN',             20);
    sistema(e.id_empresa, 'CorlixHub',       30);
    sistema(e.id_empresa, 'ERP',             40);
    sistema(e.id_empresa, 'Impressoras',     50);

    artigo(e.id_empresa, 'Acesso e senhas', 'Redefinir a senha de rede',
      'Como trocar a senha quando ela expirou ou você a esqueceu.',
      'Se você ainda consegue entrar no computador, pressione Ctrl+Alt+Del e escolha Alterar uma senha.' || chr(10) || chr(10)
      || 'Se você esqueceu a senha, ligue para o ramal da TI: por segurança, a redefinição só é feita depois de confirmar a sua identidade.' || chr(10) || chr(10)
      || 'Use pelo menos 12 caracteres e não repita senhas antigas. Depois da troca, entre de novo no e-mail e na VPN com a senha nova.',
      'senha esqueci expirou bloqueada bloqueio login acesso trocar redefinir', 2, 50);

    artigo(e.id_empresa, 'Rede e VPN', 'Configurar a VPN no notebook',
      'Como instalar e conectar a VPN para trabalhar fora da empresa.',
      '1. Instale o cliente de VPN indicado pela TI.' || chr(10)
      || '2. Informe o endereço do servidor que a TI enviou para você.' || chr(10)
      || '3. Entre com o seu usuário e a sua senha de rede.' || chr(10) || chr(10)
      || 'Se a VPN não conectar, confira primeiro se a internet está funcionando e veja se há aviso em Status dos sistemas. Se o problema continuar, abra um chamado e informe a mensagem de erro.',
      'vpn conectar conecta conexao remoto casa internet rede home office', 4, 40);

    artigo(e.id_empresa, 'E-mail e agenda', 'Acessar o e-mail pelo celular',
      'Como configurar o e-mail e a agenda da empresa no celular.',
      '1. Instale o aplicativo de e-mail indicado pela TI.' || chr(10)
      || '2. Informe o seu e-mail da empresa e a sua senha de rede.' || chr(10)
      || '3. Permita a sincronização do e-mail e da agenda.' || chr(10) || chr(10)
      || 'Se o celular for perdido ou roubado, avise a TI na hora para que o acesso seja bloqueado.',
      'email e-mail celular telefone agenda calendario sincronizar mobile', 3, 30);

    artigo(e.id_empresa, 'Impressoras', 'Adicionar uma impressora da rede',
      'Como instalar no computador uma impressora da empresa.',
      '1. Conecte-se à rede da empresa ou à VPN.' || chr(10)
      || '2. Abra as configurações de impressoras do computador e escolha Adicionar impressora.' || chr(10)
      || '3. Selecione a impressora do seu andar na lista.' || chr(10) || chr(10)
      || 'Se ela não aparecer, anote o nome que está na etiqueta do equipamento e abra um chamado.',
      'impressora imprimir impressao adicionar instalar rede papel', 3, 20);

    artigo(e.id_empresa, 'Sistemas e permissões', 'Instalar um novo programa',
      'Como pedir a instalação de um programa no seu computador.',
      'Programas são instalados pela TI, para garantir a licença e a segurança do computador.' || chr(10) || chr(10)
      || 'Abra uma solicitação com o nome do programa, para que você precisa dele e, se houver, o link do fabricante. Se o programa for pago, informe também quem aprovou a compra.',
      'programa software instalar instalacao licenca aplicativo', 2, 10);

    artigo(e.id_empresa, 'Sistemas e permissões', 'Pedir acesso a um sistema',
      'O que informar para receber acesso a um sistema ou painel.',
      'Abra uma solicitação informando o sistema, o perfil de acesso de que você precisa e o motivo.' || chr(10) || chr(10)
      || 'Quando o acesso depender de aprovação, a TI confirma com o seu gestor antes de liberar.',
      'acesso permissao permissoes sistema painel perfil liberar erp', 2, 5);

    artigo(e.id_empresa, 'Notebook e periféricos', 'Monitor externo não é reconhecido',
      'O que conferir quando o notebook não detecta o monitor.',
      '1. Confira se o cabo está bem encaixado nas duas pontas e se o monitor está ligado.' || chr(10)
      || '2. No Windows, pressione Windows+P e escolha Estender.' || chr(10)
      || '3. Teste outro cabo ou outra entrada do monitor.' || chr(10) || chr(10)
      || 'Se não resolver, abra um chamado e envie uma foto das conexões. Assim a TI vê se o problema é o adaptador.',
      'monitor tela externo hdmi displayport adaptador cabo notebook periferico', 3, 4);
  end loop;
  commit;
end;
/
