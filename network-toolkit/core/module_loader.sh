# ===================================================================
# Archivo: module_loader.sh
# Responsabilidad: Búsqueda segura y a prueba de fallos de módulos.
# ===================================================================

declare -a TK_MODULE_PATHS=()
declare -a TK_MODULE_NAMES=()
declare -a TK_MODULE_DESCS=()

tk_module_loader_scan() {
    tk_log_debug "Buscando plugins en: $TK_MODULES_DIR"
    
    TK_MODULE_PATHS=()
    TK_MODULE_NAMES=()
    TK_MODULE_DESCS=()
    
    # nullglob previene que un dir vacío devuelva un string "*.sh" literal
    shopt -s nullglob
    local mod_files=("${TK_MODULES_DIR}"/*.sh)
    shopt -u nullglob

    if [[ ${#mod_files[@]} -eq 0 ]]; then
        tk_log_warn "No se encontró ningún módulo. El menú aparecerá vacío."
        return 0
    fi
    
    for mod_file in "${mod_files[@]}"; do
        if [[ -f "$mod_file" && -x "$mod_file" ]]; then
            local mod_name=""
            local mod_desc=""
            
            # Subproceso con manejo '|| true' para prevenir fallos por set -e en el núcleo
            mod_name=$("$mod_file" --get-name 2>/dev/null) || true
            mod_desc=$("$mod_file" --get-desc 2>/dev/null) || true
            
            if [[ -n "$mod_name" && -n "$mod_desc" ]]; then
                TK_MODULE_PATHS+=("$mod_file")
                TK_MODULE_NAMES+=("$mod_name")
                TK_MODULE_DESCS+=("$mod_desc")
                tk_log_debug "Plugin detectado: $mod_name"
            else
                tk_log_error "Plugin descartado: $mod_file (Interfaz inválida o error interno)"
            fi
        fi
    done
    
    tk_log_info "Total plugins operativos: ${#TK_MODULE_PATHS[@]}"
}
