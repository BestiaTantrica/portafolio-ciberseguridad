# ===================================================================
# Archivo: error_handler.sh
# Responsabilidad: Intercepción de fallos con borrado seguro de TMP.
# ===================================================================

tk_error_handler() {
    local exit_code="$1"
    local line_no="$2"
    local command="$3"
    
    if [[ $exit_code -eq 130 ]]; then
        tk_log_warn "Interrupción por teclado (SIGINT). Saliendo."
        echo -e "\n[i] Interrupción detectada. Apagando..."
    elif [[ $exit_code -ne 0 ]]; then
        tk_log_error "Fallo fatal núcleo - Comando '$command' (Línea $line_no) finalizó con código $exit_code"
        echo -e "\n[!] Fallo del sistema central. Verifica logs."
    fi
    
    # Eliminación segura (evitar rm -rf *) usando find, asegurando variable
    if [[ -n "${TK_TMP_DIR:-}" ]] && [[ -d "$TK_TMP_DIR" ]]; then
        find "$TK_TMP_DIR" -mindepth 1 -delete 2>/dev/null || true
    fi
    
    exit "$exit_code"
}
