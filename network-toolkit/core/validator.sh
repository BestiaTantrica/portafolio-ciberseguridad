# ===================================================================
# Archivo: validator.sh
# Responsabilidad: Validaciones previas al inicio real.
# ===================================================================

tk_validate_env() {
    local is_valid=true

    # 1. Chequeo de carpetas
    local dirs=("${TK_LOGS_DIR:-}" "${TK_TMP_DIR:-}" "${TK_REPORTS_DIR:-}" "${TK_MODULES_DIR:-}")
    for d in "${dirs[@]}"; do
        if [[ ! -d "$d" ]]; then
            tk_log_error "Falta el directorio requerido: $d"
            is_valid=false
        elif [[ "$d" != "${TK_MODULES_DIR:-}" ]] && [[ ! -w "$d" ]]; then
            tk_log_error "Permisos de escritura denegados en: $d"
            is_valid=false
        fi
    done

    # 2. Chequeo de binarios mínimos (para no crashear en la UI)
    local deps=("curl" "jq")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            tk_log_error "Dependencia crítica ausente: $dep"
            is_valid=false
        fi
    done

    if [[ "$is_valid" == "false" ]]; then
        echo "[!] Falló la pre-validación del entorno. (Ver STDERR y Logs)." >&2
        exit 1
    fi
    tk_log_debug "Validación del sistema superada."
}
