#!/bin/bash
# Script para executar setup.sh remotamente na VM
# Uso: ./deploy-remote.sh IP_DA_VM

set -e

if [ $# -eq 0 ]; then
    echo "Uso: $0 <IP_DA_VM>"
    echo "Exemplo: $0 192.168.1.100"
    exit 1
fi

VM_IP=$1
SCRIPT_NAME="setup.sh"

echo "🚀 Iniciando deploy na VM: $VM_IP"
echo

# Verificar se o script existe
if [ ! -f "$SCRIPT_NAME" ]; then
    echo "❌ Erro: Script $SCRIPT_NAME não encontrado!"
    exit 1
fi

# Verificar conectividade
echo "🔍 Verificando conectividade com $VM_IP..."
if ! ping -c 1 -W 3 $VM_IP > /dev/null 2>&1; then
    echo "❌ Erro: Não foi possível conectar com $VM_IP"
    exit 1
fi
echo "✅ Conectividade OK"
echo

# Transferir script
echo "📤 Transferindo script para a VM..."
scp $SCRIPT_NAME root@$VM_IP:/root/
echo "✅ Script transferido"
echo

# Executar script na VM
echo "⚡ Executando instalação na VM..."
echo "⚠️  ATENÇÃO: Isso pode demorar alguns minutos!"
echo
ssh root@$VM_IP "chmod +x /root/$SCRIPT_NAME && /root/$SCRIPT_NAME"

echo
echo "🎉 Deploy concluído!"
echo "📋 Para conectar na VM como usuário 'blit':"
echo "   ssh blit@$VM_IP"
