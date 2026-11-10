--------------------------------------------------------------------------------
-- Corlix Hub · Home · comunicados de demonstração (5, com imagem de capa)
--
-- Antes de rodar:
--   1. Envie as 5 imagens desta pasta (demo-comunicado-1.jpg a 5) para
--      Shared Components › Static Application Files, na pasta
--      modulos/home/comunicados-demo/ (Directory = modulos/home/comunicados-demo).
--   2. Troque c_login_autor (linha abaixo) pelo login ou pelo ID de um
--      colaborador da empresa que vai receber os comunicados (o autor).
--
-- Rodar em SQL Workshop › SQL Scripts (Upload e Run). Reexecutável: pula os
-- comunicados que já existem (mesmo NOME_ARQUIVO na empresa). As imagens são
-- copiadas para a coluna IMAGEM; depois, os arquivos estáticos podem ser apagados.
-- Datas relativas a hoje: os 2 primeiros saem com o selo "Novo" (até 7 dias).
-- Para remover: 02_remover_comunicados_demo.sql.
--------------------------------------------------------------------------------
set define off
set serveroutput on

declare
  c_login_autor constant varchar2(255) := 'TROQUE_PELO_LOGIN';  -- login (LOGIN_APEX) ou ID_COLABORADOR
  c_app         constant number        := 100;
  c_pasta       constant varchar2(100) := 'modulos/home/comunicados-demo/';

  l_id_empresa number;
  l_id_autor   number;
  l_id_ti      number;
  l_imagem     blob;
  l_mime       varchar2(100);
  l_qt         pls_integer := 0;

  procedure inserir (
    p_arquivo  in varchar2,
    p_dias     in number,        -- publicado há N dias
    p_hora     in varchar2,      -- HH24:MI
    p_id_depto in number,
    p_titulo   in varchar2,
    p_conteudo in clob
  ) is
    l_existe pls_integer;
  begin
    select count(*) into l_existe
      from comunicado
     where id_empresa = l_id_empresa
       and nome_arquivo = p_arquivo;
    if l_existe > 0 then
      dbms_output.put_line('Já existe, pulado: ' || p_titulo);
      return;
    end if;

    begin
      select file_content, mime_type
        into l_imagem, l_mime
        from apex_application_static_files
       where application_id = c_app
         and file_name = c_pasta || p_arquivo;
    exception
      when no_data_found then
        l_imagem := null;
        l_mime   := null;
        dbms_output.put_line('AVISO: imagem ' || c_pasta || p_arquivo
          || ' não encontrada em Static Application Files; comunicado criado sem capa.');
    end;

    insert into comunicado (id_empresa, id_autor, id_departamento, titulo, conteudo,
                            data_publicacao, imagem, mime_type, nome_arquivo)
    values (l_id_empresa, l_id_autor, p_id_depto, p_titulo, p_conteudo,
            trunc(sysdate) - p_dias + to_number(substr(p_hora, 1, 2)) / 24
                                    + to_number(substr(p_hora, 4, 2)) / 1440,
            l_imagem, l_mime, p_arquivo);
    l_qt := l_qt + 1;
    dbms_output.put_line('Criado: ' || p_titulo);
  end inserir;

begin
  begin
    -- Aceita o login (LOGIN_APEX) ou o ID_COLABORADOR
    select id_colaborador, id_empresa
      into l_id_autor, l_id_empresa
      from colaborador
     where upper(trim(login_apex)) = upper(trim(c_login_autor))
        or id_colaborador = to_number(c_login_autor default null on conversion error)
     order by case when id_colaborador = to_number(c_login_autor default null on conversion error)
                   then 0 else 1 end
     fetch first 1 rows only;
  exception
    when no_data_found then
      raise_application_error(-20000, '"' || c_login_autor
        || '" não é login nem ID de colaborador. Troque c_login_autor no início do script.');
  end;

  -- Departamento de TI da empresa, se houver; senão o comunicado vai para todos
  select max(id_departamento)
    into l_id_ti
    from departamento
   where id_empresa = l_id_empresa
     and upper(nome) like '%TECNOLOGIA%';

  inserir('demo-comunicado-1.jpg', 1, '09:30', null,
    'Novembro Azul: roda de conversa sobre saúde do homem',
    '<p>No dia 19 de novembro, às 15h, recebemos um médico urologista no auditório para uma conversa aberta sobre prevenção, check-ups e os cuidados que fazem diferença no dia a dia. Quem estiver remoto pode acompanhar pela transmissão on-line.</p>'
 || '<p>A participação é livre e as perguntas podem ser enviadas de forma anônima pelo formulário do evento. Aproveite para conversar com a família e os amigos: cuidar da saúde é um compromisso de todos.</p>'
 || '<ul><li><strong>Quando:</strong> 19/11, das 15h às 16h</li><li><strong>Onde:</strong> auditório da sede e on-line</li><li><strong>Para quem:</strong> todas as pessoas colaboradoras</li></ul>');

  inserir('demo-comunicado-2.jpg', 4, '10:00', null,
    'Trabalho híbrido: novas regras a partir de 1º de dezembro',
    '<p>A partir de 1º de dezembro, as equipes passam a ter dois dias presenciais fixos por semana, combinados com a gestão de cada área. Os demais dias seguem no formato remoto, com a mesma jornada e os mesmos canais de contato.</p>'
 || '<p>A reserva de mesas e salas passa a ser feita pela intranet, com até 7 dias de antecedência. O calendário de cada área e as dúvidas frequentes estão disponíveis com o RH.</p>'
 || '<ul><li>Dois dias presenciais fixos por equipe</li><li>Reserva de mesas pela intranet</li><li>Auxílio home office mantido</li></ul>');

  inserir('demo-comunicado-3.jpg', 9, '14:15', l_id_ti,
    'Treinamento obrigatório de segurança da informação',
    '<p>Todas as pessoas colaboradoras devem concluir até 30 de novembro o curso on-line de segurança da informação. São 40 minutos sobre como reconhecer phishing, criar senhas fortes e tratar dados de clientes com cuidado.</p>'
 || '<p>O curso pode ser feito em etapas e emite certificado ao final. Em caso de dúvida ou de e-mail suspeito, abra um chamado no Suporte TI antes de clicar em qualquer link.</p>');

  inserir('demo-comunicado-4.jpg', 13, '16:40', null,
    'Confraternização de fim de ano: reserve o dia 18 de dezembro',
    '<p>Vamos celebrar juntos as conquistas de 2026! A confraternização será no terraço da sede, a partir das 18h, com música, comida e o tradicional amigo secreto.</p>'
 || '<p>Confirme sua presença até 5 de dezembro e conte se você tem alguma restrição alimentar. Quem trabalha remoto em outras cidades recebe um kit de celebração em casa.</p>');

  inserir('demo-comunicado-5.jpg', 20, '11:00', null,
    'Resultados do 3º trimestre: crescemos 12% em relação ao ano passado',
    '<p>A receita do terceiro trimestre superou a meta em 4 pontos, puxada pelos novos clientes da região Sul e pela renovação de contratos. O resultado é fruto do trabalho de todas as áreas: obrigado!</p>'
 || '<p>Para o último trimestre, as prioridades são a satisfação dos clientes, a redução do tempo de atendimento e o lançamento dos novos planos. A apresentação completa está disponível com a Diretoria.</p>');

  commit;
  dbms_output.put_line(l_qt || ' comunicado(s) criado(s) na empresa ' || l_id_empresa || '.');
end;
/
