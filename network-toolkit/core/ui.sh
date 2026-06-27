# ===================================================================
# Archivo: ui.sh
# Responsabilidad: Gestionar la interacción visual con el usuario (CLI),
#                  renderizar el menú y despachar la ejecución.
# ===================================================================

# Definición de colores ANSI (opcional)
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

tk_ui_show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  _   _      _                      _    "
    echo " | \\ | |    | |                    | |   "
    echo " |  \\| | ___| |___      _____  _ __| | __"
    echo " | . \` |/ _ \\ __\\ \\ /\\ / / _ \\| '__| |/ /"
    echo " | |\\  |  __/ |_ \\ V  V / (_) | |  |   < "
    echo " |_| \\_|\\___|\\__| \\_/\\_/ \\___/|_|  |_|\\_\\"
    echo -e "                 TOOLKIT v${TK_VERSION}${NC}"
    echo "================================================="
}

tk_ui_main_menu() {
    while true; do
        tk_ui_show_banner
        
        local total_mods=${#TK_MODULE_PATHS[@]}
        
        if [[ $total_mods -eq 0 ]]; then
            echo -e "${RED}[!] No hay módulos listos en el directorio. Agrega plugins a modules/${NC}"
        else
            echo " Módulos Detectados:"
            echo " -------------------"
            # Iterar sobre arrays cargados por el loader
            for (( i=0; i<$total_mods; i++ )); do
                printf "  [${GREEN}%d${NC}] %-20s - %s\n" "$((i+1))" "${TK_MODULE_NAMES[$i]}" "${TK_MODULE_DESCS[$i]}"
            done
        fi
        
        echo ""
        echo -e "  [${RED}0${NC}] Salir del Toolkit"
        echo ""
        
        read -r -p " Seleccione una opción: " choice
        
        # Evaluar opción
        if [[ "$choice" == "0" ]]; then
            break
        elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= total_mods )); then
            # Ajustar índice (arrays comienzan en 0, el menú en 1)
            local index=$((choice-1))
            local selected_file="${TK_MODULE_PATHS[$index]}"
            local selected_name="${TK_MODULE_NAMES[$index]}"
            
            tk_log_info "Usuario inició el módulo: $selected_name"
            
            echo -e "\n${CYAN}>>> Ejecutando: $selected_name ${NC}\n"
            
            # Ejecutar el módulo (Subproceso).
            # Esto previene que una variable mal definida en el módulo rompa la interfaz
            "$selected_file" --run
            
            echo -e "\n${CYAN}<<< Módulo Finalizado ${NC}"
            read -r -p "Presione [ENTER] para volver al menú..."
        else
            echo -e "${RED}[!] Selección no válida. Intente nuevamente.${NC}"
            sleep 1.5
        fi
    done
}
