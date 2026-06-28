# ===================================================================
# Archivo: reporter.sh
# Responsabilidad: Exportación de resultados sanitizada.
# ===================================================================

tk_reporter_export() {
    local raw_name="$1"
    local raw_content="$2"
    local extension="${3:-txt}"
    
    # Sanitización severa del nombre para impedir Path Traversal
    local safe_name
    safe_name="${raw_name//[^a-zA-Z0-9_-]/_}"
    
    local timestamp
    timestamp=$(date "+%Y%m%d_%H%M%S")
    local filepath="${TK_REPORTS_DIR:-}/report_${safe_name}_${timestamp}.${extension}"
    
    if [[ -d "${TK_REPORTS_DIR:-}" ]] && [[ -w "${TK_REPORTS_DIR:-}" ]]; then
        echo "$raw_content" > "$filepath"
        tk_log_info "Reporte guardado seguro en: $filepath"
        echo "[i] Reporte generado: $filepath"
    else
        tk_log_error "Fallo al escribir reporte en disco (Permisos o Directorio)."
    fi
}
