# ===================================================================
# Archivo: reporter.sh
# Responsabilidad: Funciones de utilidad para que los módulos
#                  puedan exportar hallazgos y reportes.
# ===================================================================

tk_reporter_export() {
    local report_name="$1"
    local raw_content="$2"
    local extension="${3:-txt}"
    
    local timestamp
    timestamp=$(date "+%Y%m%d_%H%M%S")
    local filepath="${TK_REPORTS_DIR}/${report_name}_${timestamp}.${extension}"
    
    if [[ -d "$TK_REPORTS_DIR" ]]; then
        echo "$raw_content" > "$filepath"
        tk_log_info "Reporte generado: $filepath"
        echo "[i] Resultado guardado en: $filepath"
    else
        tk_log_error "No se pudo guardar reporte. Directorio ausente: $TK_REPORTS_DIR"
    fi
}
