#!/usr/bin/env bash
# ===================================================================
# Módulo de Ejemplo
# ===================================================================

set -euo pipefail

get_name() {
    echo "Plantilla"
}

get_desc() {
    echo "Plugin seguro de prueba."
}

run_module() {
    echo "[*] Lógica del módulo corriendo en aislamiento."
    if [[ -n "${TK_TMP_DIR:-}" ]]; then
        echo "[*] Variables de entorno núcleo legibles."
    fi
    sleep 1
    echo "[*] Tarea finalizada."
    # Descomentar abajo para probar que el menú no crashea
    # exit 2
}

case "${1:-}" in
    --get-name) get_name ;;
    --get-desc) get_desc ;;
    --run) shift; run_module "$@" ;;
    *)
        echo "Modo de uso incorrecto." >&2
        exit 1
        ;;
esac
exit 0
