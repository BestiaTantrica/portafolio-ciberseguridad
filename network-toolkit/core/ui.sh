# ===================================================================
# Archivo: ui.sh
# Responsabilidad: Generación segura de menús interactivos.
# ===================================================================

TK_C_RED='\033[0;31m'
TK_C_GREEN='\033[0;32m'
TK_C_CYAN='\033[0;36m'
TK_C_NC='\033[0m'

tk_ui_show_banner() {
    clear
    echo -e "${TK_C_CYAN}"
    echo "  _   _      _                      _    "
    echo " | \\ | |    | |                    | |   "
    echo " |  \\| | ___| |___      _____  _ __| | __"
    echo " | . \` |/ _ \\ __\\ \\ /\\ / / _ \\| '__| |/ /"
    echo " | |\\  |  __/ |_ \\ V  V / (_) | |  |   < "
    echo " |_| \\_|\\___|\\__| \\_/\\_/ \\___/|_|  |_|\\_\\"
    echo -e "                 TOOLKIT v${TK_VERSION:-Unknown}${TK_C_NC}"
    echo "================================================="
}

tk_ui_main_menu() {
    while true; do
        tk_ui_show_banner
        
        local total_mods=${#TK_MODULE_PATHS[@]}
        
        if [[ $total_mods -eq 0 ]]; then
            echo -e "${TK_C_RED}[!] Advertencia: No hay módulos disponibles para ejecución.${TK_C_NC}"
        else
            echo " Módulos Detectados:"
            echo " -------------------"
            for (( i=0; i<total_mods; i++ )); do
                printf "  [${TK_C_GREEN}%d${TK_C_NC}] %-20s - %s\n" "$((i+1))" "${TK_MODULE_NAMES[$i]}" "${TK_MODULE_DESCS[$i]}"
            done
        fi
        
        echo ""
        echo -e "  [${TK_C_RED}0${TK_C_NC}] Salir"
        echo ""
        
        local choice
        read -r -p " > " choice
        
        if [[ "$choice" == "0" ]]; then
            break
        elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= total_mods )); then
            local index=$((choice-1))
            local selected_file="${TK_MODULE_PATHS[$index]}"
            local selected_name="${TK_MODULE_NAMES[$index]}"
            
            tk_log_info "Usuario lanzó módulo: $selected_name"
            echo -e "\n${TK_C_CYAN}>>> Ejecutando: $selected_name ${TK_C_NC}\n"
            
            # if ! command ... protege contra el cierre súbito (set -e) si el módulo falla
            if ! "$selected_file" --run; then
                local mod_exit=$?
                tk_log_error "El plugin '$selected_name' arrojó error interno (Código: $mod_exit)."
                echo -e "\n${TK_C_RED}[!] Ocurrió un error dentro del módulo. El sistema sigue en línea.${TK_C_NC}"
            else
                tk_log_info "Ejecución de $selected_name exitosa."
            fi
            
            echo -e "\n${TK_C_CYAN}<<< Módulo Finalizado ${TK_C_NC}"
            read -r -p "Presione [ENTER] para volver al menú..."
        else
            echo -e "${TK_C_RED}[!] Opción errónea.${TK_C_NC}"
            sleep 1
        fi
    done
}
