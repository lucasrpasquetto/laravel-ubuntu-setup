# 🚀 Deploy Ubuntu para Laravel

Script automatizado para configurar um servidor Ubuntu completo para desenvolvimento e produção Laravel.

## ⚠️ Configuração Inicial

**IMPORTANTE:** Antes de executar o script, configure as variáveis no arquivo `setup.sh`:

```bash
USUARIO="seu_usuario"           # Nome do usuário que será criado
SENHA_DB="sua_senha_db"         # Senha do banco de dados
DB_NAME="nome_do_banco"         # Nome do banco de dados
DB_USER="usuario_do_banco"      # Usuário do banco de dados
PHP_VER="8.2"                   # Versão do PHP (8.1, 8.2, 8.3, etc.)
```

## 📋 O que é instalado

### 🔧 **Sistema Base**
- Ubuntu atualizado com utilitários essenciais
- Firewall UFW configurado (SSH, HTTP, HTTPS)
- Usuário personalizado com privilégios sudo sem senha

### 🐘 **PHP**
- PHP-FPM, CLI e extensões essenciais
- Extensões: MySQL, XML, cURL, mbstring, zip, bcmath, GD
- Composer instalado com verificação de integridade
- Todas as dependências de desenvolvimento

### 🌐 **Nginx**
- Configuração otimizada para Laravel
- Site padrão removido
- Headers de segurança configurados
- Suporte a IPv6

### 🗄️ **MariaDB**
- Servidor e cliente instalados
- Configuração de segurança automática
- Banco e usuário personalizados criados

### ⚡ **Redis**
- Servidor Redis instalado e configurado
- Bind apenas para localhost

### 📦 **Node.js & npm**
- Node.js e npm para build de assets
- Suporte a Vite, Mix e ferramentas frontend

## 🚀 Como usar

### **Opção 1: Deploy Remoto (Recomendado)**

```bash
# Na sua máquina local
./deploy-remote.sh IP_DA_VM

# Exemplo
./deploy-remote.sh 192.168.1.100
```

### **Opção 2: Execução Manual**

```bash
# Transferir script para o servidor
scp setup.sh root@IP_DA_VM:/root/

# Conectar e executar
ssh root@IP_DA_VM
chmod +x /root/setup.sh
/root/setup.sh
```

### **Opção 3: Execução Direta via SSH**

```bash
ssh root@IP_DA_VM 'bash -s' < setup.sh
```

## 📁 Estrutura do Projeto

```
deploy-ubuntu/
├── setup.sh           # Script principal de instalação
├── deploy-remote.sh   # Script para deploy remoto
└── README.md          # Este arquivo
```

## ⚙️ Configurações Padrão

### **Usuário e Diretórios**
- **Usuário:** Configurável (definido em `USUARIO`)
- **Diretório do site:** `/home/{USUARIO}/site`
- **Permissões:** `{USUARIO}:www-data` com `775`

### **Banco de Dados**
- **Nome:** Configurável (definido em `DB_NAME`)
- **Usuário:** Configurável (definido em `DB_USER`)
- **Senha:** Configurável (definido em `SENHA_DB`)

### **PHP**
- **Versão:** Configurável (definido em `PHP_VER`)
- **Socket FPM:** `/run/php/php-fpm.sock`

### **Nginx**
- **Porta:** 80
- **Root:** `/home/{USUARIO}/site/public`
- **Index:** `index.php`

## 🔑 Configuração SSH para GitHub

Após a instalação, configure SSH para GitHub:

```bash
# Conectar como seu usuário
ssh SEU_USUARIO@IP_DA_VM

# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -C 'seu-email@exemplo.com'

# Exibir chave pública
cat ~/.ssh/id_rsa.pub
```

1. Copie a chave pública
2. Acesse: https://github.com/settings/keys
3. Clique em "New SSH key"
4. Cole a chave e salve

## 📦 Deploy de Projeto Laravel

```bash
# Conectar como seu usuário
ssh SEU_USUARIO@IP_DA_VM

# Clonar projeto
cd ~/site
git clone git@github.com:SEU_USUARIO/SEU_REPO.git .

# Instalar dependências
composer install
npm install

# Configurar ambiente
cp .env.example .env
php artisan key:generate

# Configurar banco no .env
# DB_DATABASE=SEU_DB_NAME
# DB_USERNAME=SEU_DB_USER
# DB_PASSWORD=SUA_SENHA_DB

# Executar migrações
php artisan migrate

# Build de assets
npm run build

# Ajustar permissões
sudo chown -R SEU_USUARIO:www-data ~/site
sudo chmod -R 775 ~/site/storage
sudo chmod -R 775 ~/site/bootstrap/cache
```

## 🔧 Comandos Úteis

### **Verificar Status dos Serviços**
```bash
sudo systemctl status nginx
sudo systemctl status php8.2-fpm
sudo systemctl status mariadb
sudo systemctl status redis
```

### **Logs**
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/php8.2-fpm.log
sudo tail -f /var/log/mysql/error.log
```

### **Reiniciar Serviços**
```bash
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm
sudo systemctl restart mariadb
sudo systemctl restart redis
```

## 🛡️ Segurança

### **Firewall**
- SSH (porta 22)
- HTTP (porta 80)
- HTTPS (porta 443)

### **Headers Nginx**
- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`

### **MariaDB**
- Configuração de segurança aplicada
- Usuário root com senha
- Usuários anônimos removidos

## 📝 Requisitos

### **Servidor**
- Ubuntu 20.04+ (testado em 24.04)
- Acesso root via SSH
- Mínimo 1GB RAM
- Mínimo 10GB disco

### **Cliente**
- SSH configurado
- Chave SSH ou senha root

## 🐛 Troubleshooting

### **Erro: "File not found"**
- Normal se não há projeto Laravel no diretório
- Clone seu projeto em `/home/blit/site`

### **Erro: "502 Bad Gateway"**
- Verificar se PHP-FPM está rodando: `sudo systemctl status php8.2-fpm`
- Verificar socket: `ls -la /run/php/php-fpm.sock`

### **Erro: "Permission denied"**
- Verificar permissões: `sudo chown -R blit:www-data /home/blit/site`
- Verificar chmod: `sudo chmod -R 775 /home/blit/site/storage`

### **Composer não encontrado**
```bash
sudo apt install -y composer
```

### **Node.js não encontrado**
```bash
sudo apt install -y nodejs npm
```

## 📄 Licença

Este projeto é de domínio público. Use e modifique livremente.

## 👨‍💻 Autor

**Lucas (Blit)** - Desenvolvedor Full Stack

---

## 🎯 Próximos Passos

1. ✅ Execute o script de deploy
2. ✅ Configure SSH para GitHub
3. ✅ Clone seu projeto Laravel
4. ✅ Configure variáveis de ambiente
5. ✅ Execute migrações
6. ✅ Build de assets
7. 🚀 **Seu Laravel está no ar!**

**Happy Coding! 🎉**
