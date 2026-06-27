#!/usr/bin/env bash
# ===================================================================
# Archivo: install.sh
# Responsabilidad: Instalador inteligente y robusto de dependencias
# ===================================================================

set -euo pipefail

echo "========================================="
echo "   Instalador del Network Toolkit"
echo "========================================="

DEPS=(
    "nmap"
    "dnsutils"
    "jq"
    "curl"
    "iputils-ping"
    "gawk"
    "netcat-traditional"
    "shellcheck"
    "bats"
)

echo "[*] Detectando sistema operativo..."
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" && "${ID_LIKE:-}" != *"debian"* && "${ID_LIKE:-}" != *"ubuntu"* ]]; then
        echo "[!] Error: Este instalador solo soporta distros basadas en Debian/Ubuntu."
        exit 1
    fi
    echo "[*] Sistema compatible detectado: $PRETTY_NAME"
else
    echo "[!] Error: No se pudo verificar el sistema operativo (/etc/os-release no encontrado)."
    exit 1
fi

echo "[*] Verificando dependencias necesarias..."
TO_INSTALL=()
for dep in "${DEPS[@]}"; do
    if ! dpkg -s "$dep" >/dev/null 2>&1; then
        TO_INSTALL+=("$dep")
    else
        echo "  - $dep ya está instalado."
    fi
done

if [[ ${#TO_INSTALL[@]} -eq 0 ]]; then
    echo "[*] Todas las dependencias requeridas ya se encuentran instaladas."
else
    echo "[*] Dependencias faltantes que se instalarán: ${TO_INSTALL[*]}"
    echo "[*] Actualizando índices..."
    sudo apt-get update
    echo "[*] Procediendo con la instalación..."
    sudo apt-get install -y "${TO_INSTALL[@]}"
fi

echo "========================================="
echo " Resumen de Instalación"
echo "========================================="
echo " Estado: COMPLETADO EXITOSAMENTE"
echo " Ya puedes utilizar el toolkit ejecutando:"
echo " ./bin/net-toolkit"
echo "========================================="
