# Aplicação MVC do laboratório

Requer SDK .NET 8 para execução local, ou Docker Engine e Compose na VM Linux.

Local: `dotnet run --urls http://localhost:5080`. Abra http://localhost:5080.

Na VM, siga o guia HTML da aula: crie a rede externa `aula-net`, descubra o gateway e defina `TRUSTED_PROXY` no arquivo `.env` antes de executar `sudo docker compose up -d --build`.

O contêiner publica somente 127.0.0.1:8080 na VM. O Nginx instalado no host recebe o acesso público e controla HTTPS. A aplicação confia no gateway configurado para interpretar os cabeçalhos encaminhados pelo Nginx. Não configure proxies arbitrários.

`ALUNO` personaliza a mensagem. `/health` responde JSON com status ok. Não há banco de dados nem autenticação neste exemplo.
