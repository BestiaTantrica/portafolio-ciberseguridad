# ===================================================================
# Archivo: module_loader.sh
# Responsabilidad: Descubrir dinámicamente archivos en modules/ e
#                  inyectar su metadatos (nombre/desc) en arrays globales.
# ===================================================================

# Estructuras de datos para almacenar el menú dinámico
declare -a TK_MODULE_PATHS=()
declare -a TK_MODULE_NAMES=()
declare -a TK_MODULE_DESCS=()

tk_module_loader_scan() {
    tk_log_debug "Iniciando escaneo del directorio de módulos: $TK_MODULES_DIR"
    
    # Reiniciar arrays por si se llama múltiples veces
    TK_MODULE_PATHS=()
    TK_MODULE_NAMES=()
    TK_MODULE_DESCS=()
    
    if [[ ! -d "$TK_MODULES_DIR" ]]; then
        tk_log_error "El directorio de módulos ($TK_MODULES_DIR) no existe."
        return 1
    fi
    
    # Escanear scripts terminados en .sh
    for mod_file in "$TK_MODULES_DIR"/*.sh; do
        if [[ -f "$mod_file" && -x "$mod_file" ]]; then
            local mod_name
            local mod_desc
            
            # Consultar al propio módulo sus metadatos usando la interfaz estándar
            # Se oculta stdout/stderr en caso de que el archivo falle
            mod_name=$("$mod_file" --get-name 2>/dev/null) || true
            mod_desc=$("$mod_file" --get-desc 2>/dev/null) || true
            
            if [[ -n "$mod_name" && -n "$mod_desc" ]]; then
                TK_MODULE_PATHS+=("$mod_file")
                TK_MODULE_NAMES+=("$mod_name")
                TK_MODULE_DESCS+=("$mod_desc")
                tk_log_debug "Módulo descubierto correctamente: $mod_name"
            else
                tk_log_warn "El script '$mod_file' se ignoró porque no responde a la interfaz (--get-name/--get-desc)."
            fi
        fi
    done
    
    tk_log_info "Escaneo finalizado. Se descubrieron ${#TK_MODULE_PATHS[@]} módulos listos para usarse."
}
