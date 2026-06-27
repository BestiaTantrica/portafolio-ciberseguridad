# ===================================================================
# Archivo: logger.sh
# Responsabilidad: Sistema de logs estandarizado y sin echos directos.
# ===================================================================

tk_log() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_entry="[$timestamp] [$level] $msg"
    
    # Intenta escribir a log silenciosamente si está disponible
    if [[ -d "${TK_LOGS_DIR:-}" ]] && [[ -w "${TK_LOGS_DIR:-}" ]]; then
        echo "$log_entry" >> "${TK_LOG_FILE:-/dev/null}"
    fi
    
    # Solo los errores se inyectan a stderr si es vital (interfaz visual o crasheo)
    if [[ "$level" == "ERROR" ]]; then
        echo -e "\033[0;31m[ERROR]\033[0m $msg" >&2
    fi
}

tk_log_debug() {
    if [[ "${TK_LOG_LEVEL:-}" == "DEBUG" ]]; then
        tk_log "DEBUG" "$1"
    fi
}

tk_log_info() {
    tk_log "INFO" "$1"
}

tk_log_warn() {
    tk_log "WARN" "$1"
}

tk_log_error() {
    tk_log "ERROR" "$1"
}
