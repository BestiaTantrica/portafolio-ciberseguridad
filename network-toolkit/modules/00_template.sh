#!/usr/bin/env bash
# ===================================================================
# Módulo de Ejemplo
# Este es un esquema estructural para los módulos del Toolkit.
# No contiene lógica real, sirve para demostrar el desacoplamiento.
# ===================================================================

# Forzar buenas prácticas dentro del módulo
set -euo pipefail

# -- INTERFAZ DE METADATOS --
get_name() {
    echo "Plantilla / Hello World"
}

get_desc() {
    echo "Módulo base para demostrar la carga dinámica (Desacoplado)."
}

# -- LÓGICA PRINCIPAL --
run_module() {
    echo "[*] Iniciando módulo de ejemplo..."
    
    # Comprobar acceso a variables exportadas por el núcleo (solo lectura o uso)
    if [[ -n "${TK_TMP_DIR:-}" ]]; then
        echo "[*] Utilizando directorio temporal: $TK_TMP_DIR"
    fi
    
    # Aquí iría el flujo real (ej. nmap, ping, etc.)
    sleep 1
    
    echo "[*] Operación completada con éxito."
}

# -- DESPACHADOR (API del módulo) --
# Este switch/case es obligatorio para que el core/module_loader pueda interactuar
case "${1:-}" in
    --get-name)
        get_name
        ;;
    --get-desc)
        get_desc
        ;;
    --run)
        # Shift quita '--run' de los argumentos y pasa el resto a la función
        shift
        run_module "$@"
        ;;
    *)
        echo "Error: Uso incorrecto del módulo."
        echo "Modo de uso: $0 {--get-name|--get-desc|--run}"
        exit 1
        ;;
esac

exit 0
