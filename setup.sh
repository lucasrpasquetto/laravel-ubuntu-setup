#!/bin/bash
# Script de configuração inicial de servidor Ubuntu para Laravel
# Autor: Lucas (Blit)
# Uso: rodar como root

set -e

USUARIO=""
SENHA_DB=""
DB_NAME=""
DB_USER=""
PHP_VER=""
SITE_DIR="/home/${USUARIO}/site"

# Verificar se as variáveis foram configuradas
if [ -z "$USUARIO" ] || [ -z "$SENHA_DB" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$PHP_VER" ]; then
    echo "❌ ERRO: Configure as variáveis no início do script!"
    echo
    echo "Edite o arquivo setup.sh e configure:"
    echo "  USUARIO=\"seu_usuario\""
    echo "  SENHA_DB=\"sua_senha_db\""
    echo "  DB_NAME=\"nome_do_banco\""
    echo "  DB_USER=\"usuario_do_banco\""
    echo "  PHP_VER=\"8.2\""
    echo
    exit 1
fi

echo "==> Atualizando sistema..."
apt update && apt upgrade -y

echo "==> Instalando utilitários básicos..."
apt install -y sudo vim curl wget git unzip ufw htop software-properties-common

echo "==> Criando usuário '${USUARIO}'..."
id -u $USUARIO &>/dev/null || adduser --disabled-password --gecos "" $USUARIO
usermod -aG sudo $USUARIO

echo "==> Configurando sudo sem senha para '${USUARIO}'..."
echo "${USUARIO} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USUARIO}
chmod 440 /etc/sudoers.d/${USUARIO}

echo "==> Copiando chaves SSH autorizadas para o usuário '${USUARIO}'..."
if [ -f /root/.ssh/authorized_keys ]; then
    sudo -u ${USUARIO} mkdir -p /home/${USUARIO}/.ssh
    cp /root/.ssh/authorized_keys /home/${USUARIO}/.ssh/authorized_keys
    chown ${USUARIO}:${USUARIO} /home/${USUARIO}/.ssh/authorized_keys
    chmod 600 /home/${USUARIO}/.ssh/authorized_keys
    chmod 700 /home/${USUARIO}/.ssh
    echo "Chaves SSH copiadas com sucesso!"
else
    echo "Aviso: Nenhuma chave SSH encontrada em /root/.ssh/authorized_keys"
fi

echo "==> Mudando para usuário '${USUARIO}' para continuar instalação..."
echo "==> Executando comandos restantes como '${USUARIO}' com sudo..."

# Executar o resto do script como o usuário blit mantendo o output
sudo -u ${USUARIO} bash << USER_SCRIPT_EOF
# Definir variáveis no contexto do usuário
USUARIO="${USUARIO}"
SENHA_DB="${SENHA_DB}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
SITE_DIR="${SITE_DIR}"
PHP_VER="${PHP_VER}"

echo "==> Configurando firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

echo "==> Adicionando repositório PHP..."
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

echo "==> Instalando dependências de desenvolvimento..."
sudo apt install -y build-essential libpng-dev libjpeg-dev libfreetype6-dev \
locales libonig-dev zip jpegoptim optipng pngquant gifsicle vim unzip git curl libzip-dev

echo "==> Instalando PHP ${PHP_VER} e extensões..."
sudo apt install -y php${PHP_VER} php${PHP_VER}-fpm php${PHP_VER}-cli php${PHP_VER}-common \
php${PHP_VER}-mysql php${PHP_VER}-xml php${PHP_VER}-curl php${PHP_VER}-mbstring \
php${PHP_VER}-zip php${PHP_VER}-bcmath php${PHP_VER}-gd

echo "==> Configurando extensões PHP..."
sudo phpenmod gd

echo "==> Configurando PHP-FPM..."
sudo systemctl enable php${PHP_VER}-fpm
sudo systemctl start php${PHP_VER}-fpm
sudo systemctl status php${PHP_VER}-fpm --no-pager

echo "==> Verificando socket PHP-FPM..."
ls -la /run/php/php-fpm.sock

echo "==> Limpando cache do apt..."
sudo apt clean && sudo rm -rf /var/lib/apt/lists/*

echo "==> Instalando Composer..."
cd /tmp
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'ed0feb545ba87161262f2d45a633e34f591ebb3381f2e0063c345ebea4d228dd0043083717770234ec00c5a9f9593792') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer

echo "==> Instalando Node.js e npm..."
sudo apt install -y nodejs npm
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

echo "==> Instalando Nginx..."
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

echo "==> Instalando MariaDB..."
sudo apt install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb

echo "==> Configurando segurança do MariaDB..."
sudo mysql_secure_installation <<MYSQL_SECURE_EOF

y
${SENHA_DB}
${SENHA_DB}
y
y
y
y
MYSQL_SECURE_EOF

echo "==> Criando banco e usuário Laravel..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${SENHA_DB}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "==> Instalando Redis..."
sudo apt install -y redis-server
sudo systemctl enable redis
sudo systemctl start redis
sudo sed -i 's/^bind .*/bind 127.0.0.1/' /etc/redis/redis.conf

echo "==> Criando estrutura do site Laravel..."
mkdir -p ${SITE_DIR}
sudo chown -R ${USUARIO}:www-data ${SITE_DIR}
sudo chmod -R 775 ${SITE_DIR}

echo "==> Verificando PHP-FPM antes de configurar Nginx..."
if [ ! -S /run/php/php-fpm.sock ]; then
    echo "PHP-FPM socket não encontrado. Iniciando PHP-FPM..."
    sudo systemctl start php${PHP_VER}-fpm
    sleep 2
fi

echo "==> Criando configuração Nginx..."
sudo tee /etc/nginx/sites-available/laravel > /dev/null <<NGINX_CONFIG_EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root ${SITE_DIR}/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ ^/index\.php(/|\$) {
        fastcgi_pass unix:/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
NGINX_CONFIG_EOF

sudo ln -sf /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/laravel
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-available/default
echo "==> Verificando configuração Nginx..."
sudo nginx -t
echo "==> Recarregando Nginx..."
sudo systemctl reload nginx
echo "==> Sites ativos:"
ls -la /etc/nginx/sites-enabled/

echo "==> Configuração concluída com sucesso!"
USER_SCRIPT_EOF

# Mensagens finais (executadas como root)
echo
echo "Agora você pode conectar-se diretamente como o usuário '${USUARIO}' via SSH!"
echo "As chaves SSH autorizadas foram copiadas do root para o usuário '${USUARIO}'."
echo
echo "Para continuar o setup do Laravel, conecte-se como '${USUARIO}':"
echo "  ssh ${USUARIO}@$(hostname -I | awk '{print $1}')"
echo
echo "Ou se já estiver no servidor:"
echo "  su - ${USUARIO}"
echo
echo "=== CONFIGURAÇÃO SSH PARA GITHUB ==="
echo "Execute os seguintes comandos como usuário '${USUARIO}' para configurar SSH com GitHub:"
echo
echo "1. Gerar chave SSH:"
echo "   ssh-keygen -t rsa -b 4096 -C 'seu-email@exemplo.com'"
echo "   (Pressione Enter para todas as perguntas - usar configurações padrão)"
echo
echo "2. Exibir a chave pública para copiar no GitHub:"
echo "   cat ~/.ssh/id_rsa.pub"
echo
echo "3. Adicionar a chave no GitHub:"
echo "   - Acesse: https://github.com/settings/keys"
echo "   - Clique em 'New SSH key'"
echo "   - Cole o conteúdo da chave pública"
echo
echo "Clone seu projeto Laravel em: ${SITE_DIR}"
echo "Exemplo:"
echo "  git clone git@github.com:SEU_USUARIO/SEU_REPO.git ${SITE_DIR}"
echo "  cd ${SITE_DIR}"
echo "  composer install"
echo "  npm install"
echo "  cp .env.example .env"
echo "  php artisan key:generate"
echo "  npm run build"
echo
echo "Banco de dados:"
echo "  DB_DATABASE=${DB_NAME}"
echo "  DB_USERNAME=${DB_USER}"
echo "  DB_PASSWORD=${SENHA_DB}"
echo
echo "Laravel pronto para deploy 🚀"lit@appcotaagora:~$ ls
site
blit@appcotaagora:~$ composer
Command 'composer' not found, but can be installed with:
sudo apt install composer
blit@appcotaagora:~$ 

