# Aula: do MVC à aplicação publicada

Site: https://devflexa.github.io/aula-mvc-deploy-azure/

Abra `index.html` no navegador ou com o Live Server do VS Code. Não é necessário instalar dependências. A página funciona offline.

- `index.html`: aula, conceitos, atividade e revisão.
- `aula.css`: estilos complementares e impressão.
- `aula.js`: progresso do checklist e expansão das respostas na impressão.
- O fluxograma é construído em HTML/CSS, com ícones SVG incorporados e cartões que levam à atividade correspondente.

As marcações do checklist duram apenas enquanto a página está aberta. O botão de impressão permite salvar a aula em PDF pelo navegador.

## Guia completo

A seção 7 explica a criação de uma VM Ubuntu 24.04 x64, NSG, SSH, UFW, Git, instalação do Docker, execução da aplicação, proxy Nginx, DNS, HTTPS com Certbot, logs, atualização e encerramento do laboratório. Os blocos distinguem PowerShell local de Bash na VM e incluem botões de cópia.

`exemplo-mvc/` contém a aplicação ASP.NET Core MVC .NET 8 usada no guia. `downloads/exemplo-mvc.zip` é o pacote distribuído aos alunos, sem bin/obj ou credenciais. O SDK local é opcional; o Docker compila na VM. Para testar localmente: `dotnet run --project exemplo-mvc --urls http://localhost:5080`.

Para reproduzir HTTPS, o aluno precisa controlar o DNS de um domínio e apontá-lo para a VM. Sem domínio, o roteiro permite testar HTTP com curl --resolve. As referências oficiais estão junto das respectivas etapas.

O roteiro orienta o laboratório; não provisiona recursos Azure nem executa o deploy.

## Validação e publicação

O workflow `.github/workflows/pages.yml` testa o guia em Ubuntu 24.04 antes de publicar no GitHub Pages. Ele valida links internos, paridade dos arquivos do ZIP, sintaxe Bash, construção da imagem Docker, inicialização com Compose, endpoint de saúde, View MVC, vínculo da porta com localhost, proxy Nginx, redirecionamento e reconhecimento de HTTPS com um certificado de teste. Somente index.html, CSS, JavaScript e o ZIP vão para o Pages.

Executar os testes de integração em uma máquina Ubuntu de laboratório com Docker: `bash scripts/verify-linux.sh`. Esse script instala Nginx e configura um site temporário; use uma máquina dedicada, pois altera a configuração dos serviços. Para as verificações estáticas apenas, execute `python3 scripts/validate.py`.

Limites: a automação não cria recursos Azure, não testa NSG/UFW de uma VM real nem emite um certificado público pelo Let's Encrypt. Essas etapas são revisadas com documentação oficial e possuem verificações manuais no guia. O teste TLS usa um certificado próprio de curta duração e valida sua cadeia explicitamente.
