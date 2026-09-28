#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 scripts/validate.py
node --check aula.js

sudo apt-get update
sudo apt-get install -y nginx openssl

# Extract the actual configuration shown to students, not a separate test copy.
python3 - <<'PY'
import sys
from pathlib import Path
sys.path.insert(0, 'scripts')
from validate import Guide
parser = Guide()
parser.feed(Path('index.html').read_text(encoding='utf-8'))
nginx = next(code for label, code in parser.blocks if label.endswith('/etc/nginx/sites-available/aula-mvc'))
Path('/tmp/aula-mvc-nginx').write_text(nginx, encoding='utf-8')
PY

docker network create aula-net
proxy=$(docker network inspect aula-net --format '{{(index .IPAM.Config 0).Gateway}}')
cd exemplo-mvc
printf 'ALUNO=Teste automatizado\nTRUSTED_PROXY=%s\n' "$proxy" > .env
chmod 600 .env
trap 'docker compose logs --tail=100; docker compose down; docker network rm aula-net' EXIT
docker compose config --quiet
docker compose up -d --build
for attempt in $(seq 1 60); do
  if curl -fsS http://127.0.0.1:8080/health > /tmp/aula-health.json; then break; fi
  sleep 2
done
python3 -c 'import json; assert json.load(open("/tmp/aula-health.json"))["status"] == "ok"'
docker compose port web 8080 | grep -Fx '127.0.0.1:8080'
curl -fsS http://127.0.0.1:8080/ | grep -F 'Teste automatizado'

sudo cp /tmp/aula-mvc-nginx /etc/nginx/sites-available/aula-mvc
sudo ln -s /etc/nginx/sites-available/aula-mvc /etc/nginx/sites-enabled/aula-mvc
sudo nginx -t
sudo systemctl restart nginx
curl -fsS -H 'Host: aula.seudominio.com' http://127.0.0.1/health | grep -F '"status":"ok"'
# Publicly supplied forwarding headers must be overwritten by Nginx.
curl -fsS -H 'Host: aula.seudominio.com' -H 'X-Forwarded-Proto: https' http://127.0.0.1/ | grep -F '<code>http</code>'

# Test real TLS termination without claiming to issue a public ACME certificate.
sudo openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
  -keyout /tmp/aula-key.pem -out /tmp/aula-cert.pem \
  -subj '/CN=aula.seudominio.com' -addext 'subjectAltName=DNS:aula.seudominio.com'
python3 - <<'PY'
from pathlib import Path
s = Path('/tmp/aula-mvc-nginx').read_text()
s = s.replace('listen 80;', 'listen 443 ssl;\n    ssl_certificate /tmp/aula-cert.pem;\n    ssl_certificate_key /tmp/aula-key.pem;')
s += '\nserver { listen 80; server_name aula.seudominio.com; return 301 https://$host$request_uri; }\n'
Path('/tmp/aula-mvc-tls').write_text(s)
PY
sudo cp /tmp/aula-mvc-tls /etc/nginx/sites-available/aula-mvc
sudo nginx -t
sudo systemctl reload nginx
curl -fsS --cacert /tmp/aula-cert.pem --resolve aula.seudominio.com:443:127.0.0.1 https://aula.seudominio.com/ | grep -F '<code>https</code>'
redirect_ready=false
for attempt in $(seq 1 15); do
  curl -sSI -H 'Host: aula.seudominio.com' http://127.0.0.1/ > /tmp/aula-redirect.headers
  if grep -q '^HTTP/1.1 301' /tmp/aula-redirect.headers && grep -qi '^Location: https://aula.seudominio.com/' /tmp/aula-redirect.headers; then
    redirect_ready=true
    break
  fi
  sleep 1
done
cat /tmp/aula-redirect.headers
test "$redirect_ready" = true
echo 'PASS: Docker build, Compose, MVC, health, loopback binding, Nginx proxy, TLS and HTTPS scheme.'
