#!/usr/bin/env bash
# ===================================================================
# Módulo: 01_health_check.sh
# Responsabilidad: Diagnóstico integral y pasivo del estado de la red.
# ===================================================================

set -euo pipefail

# -- INTERFAZ DE METADATOS --
get_name() { echo "Network Health Check"; }
get_desc() { echo "Diagnóstico integral del estado de la red (L2 a L7)"; }

# -- INTEGRACIÓN CON EL NÚCLEO --
if [[ -n "${TK_BASE_DIR:-}" ]] && [[ -f "${TK_BASE_DIR}/core/logger.sh" ]]; then
    # shellcheck disable=SC1091
    source "${TK_BASE_DIR}/core/logger.sh"
    # shellcheck disable=SC1091
    source "${TK_BASE_DIR}/core/reporter.sh"
else
    tk_log_info() { echo "[INFO] $1"; }
    tk_log_error() { echo "[ERROR] $1" >&2; }
    tk_log_warn() { echo "[WARN] $1"; }
    tk_reporter_export() { echo "[i] Reporte generado: $1.$3"; }
fi

# -- CONSTANTES Y CONFIGURACIÓN VISUAL --
C_GRN='\033[0;32m'
C_YEL='\033[1;33m'
C_RED='\033[0;31m'
C_BLU='\033[0;34m'
C_NC='\033[0m'
SYM_OK="✔"
SYM_WARN="⚠"
SYM_FAIL="✖"

# -- VARIABLES GLOBALES DEL MÓDULO --
declare -A HC_DATA

# -- FUNCIONES AUXILIARES --
print_section() { printf "\n%b=== %s ===%b\n" "$C_BLU" "$1" "$C_NC"; }
print_item() { printf "  %-20s : %s\n" "$1" "$2"; }

get_icon() {
    if [[ "$1" == "OK" ]]; then
        printf "%b%s%b" "$C_GRN" "$SYM_OK" "$C_NC"
    elif [[ "$1" == "WARN" ]]; then
        printf "%b%s%b" "$C_YEL" "$SYM_WARN" "$C_NC"
    else
        printf "%b%s%b" "$C_RED" "$SYM_FAIL" "$C_NC"
    fi
}

# -- 1. ADQUISICIÓN DE DATOS --

hc_acquire_sys_info() {
    HC_DATA[sys_host]=$(hostname 2>/dev/null || echo "Desconocido")
    HC_DATA[sys_user]=$(whoami 2>/dev/null || echo "Desconocido")
    HC_DATA[sys_date]=$(date '+%Y-%m-%d %H:%M:%S')
    HC_DATA[sys_up]=$(uptime -p 2>/dev/null || echo "Desconocido")
    HC_DATA[sys_kernel]=$(uname -r 2>/dev/null || echo "Desconocido")

    local distro="Linux"
    if [[ -f /etc/os-release ]]; then
        distro=$( (source /etc/os-release && echo "${PRETTY_NAME:-Linux}") )
    fi
    HC_DATA[sys_distro]="$distro"
}

hc_acquire_active_if_stats() {
    local active_if="${HC_DATA[if_active]}"
    local sys_path="/sys/class/net/$active_if"
    
    if [[ -d "$sys_path" ]]; then
        HC_DATA[if_state]=$(cat "$sys_path/operstate" 2>/dev/null || echo "UNKNOWN")
        local speed
        speed=$(cat "$sys_path/speed" 2>/dev/null || echo "")
        HC_DATA[if_speed]=${speed:+"${speed} Mbps"}
        HC_DATA[if_speed]=${HC_DATA[if_speed]:-"N/A"}
        HC_DATA[if_mac]=$(cat "$sys_path/address" 2>/dev/null || echo "N/A")
        HC_DATA[cfg_mtu]=$(cat "$sys_path/mtu" 2>/dev/null || echo "N/A")
        
        if [[ -d "$sys_path/statistics" ]]; then
            HC_DATA[stat_rx_pkts]=$(cat "$sys_path/statistics/rx_packets" 2>/dev/null || echo "0")
            HC_DATA[stat_tx_pkts]=$(cat "$sys_path/statistics/tx_packets" 2>/dev/null || echo "0")
            HC_DATA[stat_rx_errs]=$(cat "$sys_path/statistics/rx_errors" 2>/dev/null || echo "0")
            HC_DATA[stat_tx_errs]=$(cat "$sys_path/statistics/tx_errors" 2>/dev/null || echo "0")
            HC_DATA[stat_drop]=$(cat "$sys_path/statistics/rx_dropped" 2>/dev/null || echo "0")
            HC_DATA[stat_overruns]=$(cat "$sys_path/statistics/rx_over_errors" 2>/dev/null || echo "0")
        fi
        HC_DATA[stat_carrier]=$(cat "$sys_path/carrier" 2>/dev/null || echo "N/A")
    fi
}

hc_acquire_net_info() {
    HC_DATA[if_all]="N/A"
    HC_DATA[if_active]="Ninguna"
    HC_DATA[if_state]="N/A"
    HC_DATA[if_speed]="N/A"
    HC_DATA[if_mac]="N/A"
    HC_DATA[if_ipv4]="N/A"
    HC_DATA[if_ipv6]="N/A"
    HC_DATA[cfg_gw]="Ninguno"
    HC_DATA[cfg_dns]="Ninguno"
    HC_DATA[cfg_mtu]="N/A"
    HC_DATA[cfg_routes_txt]="N/A"
    HC_DATA[stat_rx_pkts]="0"
    HC_DATA[stat_tx_pkts]="0"
    HC_DATA[stat_rx_errs]="0"
    HC_DATA[stat_tx_errs]="0"
    HC_DATA[stat_drop]="0"
    HC_DATA[stat_overruns]="0"
    HC_DATA[stat_carrier]="N/A"

    if ! command -v ip >/dev/null 2>&1; then
        tk_log_warn "Comando 'ip' no disponible. Diagnóstico de interfaces limitado."
        return 0
    fi

    local ip_link_out ip_route_out
    ip_link_out=$(ip -o link show 2>/dev/null || echo "")
    ip_route_out=$(ip route show 2>/dev/null || echo "")

    if [[ -n "$ip_link_out" ]]; then
        HC_DATA[if_all]=$(echo "$ip_link_out" | awk -F': ' '{print $2}' | paste -sd, -)
    fi

    local active_if
    active_if=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -n1 || echo "")
    if [[ -n "$active_if" ]]; then
        HC_DATA[if_active]="$active_if"
        hc_acquire_active_if_stats
        HC_DATA[if_ipv4]=$(ip -4 addr show "$active_if" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | head -n1 || echo "N/A")
        HC_DATA[if_ipv6]=$(ip -6 addr show "$active_if" 2>/dev/null | grep -oP '(?<=inet6\s)[a-f0-9:]+/\d+' | head -n1 || echo "N/A")
    fi

    if [[ -n "$ip_route_out" ]]; then
        HC_DATA[cfg_gw]=$(echo "$ip_route_out" | awk '/default via/ {print $3}' | head -n1 || echo "Ninguno")
        HC_DATA[cfg_routes_txt]="$ip_route_out"
    fi

    if [[ -f /etc/resolv.conf ]]; then
        HC_DATA[cfg_dns]=$(grep -i '^nameserver' /etc/resolv.conf | awk '{print $2}' | paste -sd, - || echo "Ninguno")
    fi
}

hc_acquire_svc_info() {
    local services=("NetworkManager" "systemd-resolved" "systemd-networkd")
    local cmd_systemctl
    cmd_systemctl=$(command -v systemctl 2>/dev/null || echo "")
    
    for svc in "${services[@]}"; do
        local state="No disponible"
        if [[ -n "$cmd_systemctl" ]]; then
            state=$("$cmd_systemctl" is-active "$svc" 2>/dev/null || echo "inactivo")
        fi
        HC_DATA["svc_$svc"]="$state"
    done
}

hc_ping_test() {
    local target="$1"
    if [[ -z "$target" || "$target" == "Ninguno" || "$target" == "N/A" ]]; then
        echo "N/A"
        return
    fi
    
    if ! command -v ping >/dev/null 2>&1; then
        echo "No disponible"
        return
    fi

    local res
    res=$(ping -c 4 -W 2 "$target" 2>/dev/null || true)
    
    if [[ -z "$res" ]] || echo "$res" | grep -q -E "100% packet loss|100% perdidos|unreachable|inaccesible"; then
        echo "FAIL"
    else
        local ploss lat
        ploss=$(echo "$res" | grep -oP '\d+(?=% packet loss|\% perdidos)' | head -n1 || echo "100")
        lat=$(echo "$res" | grep -oP '(?<=min/avg/max/mdev = )[\d.]+/[\d.]+/[\d.]+' || echo "$res" | grep -oP '(?<=mín/med/máx/mdev = )[\d.]+/[\d.]+/[\d.]+' || echo "N/A")
        echo "Loss: ${ploss}%, Lat: ${lat} ms"
    fi
}

hc_acquire_conn_info() {
    HC_DATA[conn_gw]=$(hc_ping_test "${HC_DATA[cfg_gw]}")
    HC_DATA[conn_1111]=$(hc_ping_test "1.1.1.1")
    HC_DATA[conn_8888]=$(hc_ping_test "8.8.8.8")
    
    if command -v dig >/dev/null 2>&1; then
        HC_DATA[dns_res]=$(dig +short google.com A 2>/dev/null | grep -m1 -E '^[0-9.]+$' || echo "FAIL")
    elif command -v host >/dev/null 2>&1; then
        HC_DATA[dns_res]=$(host google.com 2>/dev/null | awk '/has address/ {print $4}' | head -n1 || echo "FAIL")
    else
        HC_DATA[dns_res]="No disponible (Falta dig/host)"
    fi
    
    if command -v curl >/dev/null 2>&1; then
        local code
        code=$(curl -s -o /dev/null -w "%{http_code}" https://1.1.1.1 --connect-timeout 3 || true)
        if [[ -z "$code" || "$code" == "000" ]]; then
            HC_DATA[http_code]="FAIL"
        else
            HC_DATA[http_code]="$code"
        fi
    else
        HC_DATA[http_code]="No disponible (Falta curl)"
    fi
}

# -- 2. PROCESAMIENTO --

hc_process_status() {
    HC_DATA[st_iface]="OK"
    HC_DATA[st_gw]="OK"
    HC_DATA[st_inet]="OK"
    HC_DATA[st_dns]="OK"
    HC_DATA[st_ipv6]="OK"
    HC_DATA[st_lat]="OK"
    HC_DATA[st_err]="OK"
    HC_DATA[st_svc]="OK"
    
    if [[ "${HC_DATA[if_active]}" == "Ninguna" ]] || [[ "${HC_DATA[if_state]}" == "down" ]]; then
        HC_DATA[st_iface]="FAIL"
    fi
    
    if [[ "${HC_DATA[cfg_gw]}" == "Ninguno" ]] || [[ "${HC_DATA[conn_gw]}" == "FAIL" ]]; then
        HC_DATA[st_gw]="FAIL"
    fi
    
    if [[ "${HC_DATA[conn_8888]}" == "FAIL" ]] && [[ "${HC_DATA[conn_1111]}" == "FAIL" ]]; then
        HC_DATA[st_inet]="FAIL"
    fi
    
    if [[ "${HC_DATA[dns_res]}" == "FAIL" ]] || [[ "${HC_DATA[dns_res]}" == *"No disponible"* ]]; then
        HC_DATA[st_dns]="FAIL"
    fi
    
    if [[ "${HC_DATA[if_ipv6]}" == "N/A" ]]; then
        HC_DATA[st_ipv6]="WARN"
    fi
    
    if [[ "${HC_DATA[st_inet]}" == "OK" ]] && [[ "${HC_DATA[conn_8888]}" != "N/A" ]] && [[ "${HC_DATA[conn_8888]}" != "FAIL" ]]; then
        local avg_lat
        avg_lat=$(echo "${HC_DATA[conn_8888]}" | grep -oP '(?<=Lat: )[\d.]+/[\d.]+/[\d.]+' | awk -F'/' '{print $2}' || echo "0")
        if [[ -n "$avg_lat" ]]; then
            local lat_high
            lat_high=$(awk -v a="$avg_lat" 'BEGIN {print (a>100)?1:0}' 2>/dev/null || echo 0)
            if [[ "$lat_high" -eq 1 ]]; then HC_DATA[st_lat]="WARN"; fi
        fi
    else
        HC_DATA[st_lat]="FAIL"
    fi
    
    local rx_err="${HC_DATA[stat_rx_errs]:-0}"
    local tx_err="${HC_DATA[stat_tx_errs]:-0}"
    local drop="${HC_DATA[stat_drop]:-0}"
    [[ "$rx_err" =~ ^[0-9]+$ ]] || rx_err=0
    [[ "$tx_err" =~ ^[0-9]+$ ]] || tx_err=0
    [[ "$drop" =~ ^[0-9]+$ ]] || drop=0
    if (( rx_err > 0 || tx_err > 0 || drop > 0 )); then
        HC_DATA[st_err]="WARN"
    fi
    
    if [[ "${HC_DATA[svc_NetworkManager]}" == "inactivo" || "${HC_DATA[svc_NetworkManager]}" == "No disponible" ]] && \
       [[ "${HC_DATA[svc_systemd-networkd]}" == "inactivo" || "${HC_DATA[svc_systemd-networkd]}" == "No disponible" ]]; then
        HC_DATA[st_svc]="WARN"
    fi
}

# -- 3. PRESENTACIÓN --

hc_present_ui_sections() {
    print_section "1. Información del Sistema"
    print_item "Hostname" "${HC_DATA[sys_host]}"
    print_item "Usuario" "${HC_DATA[sys_user]}"
    print_item "Uptime" "${HC_DATA[sys_up]}"
    print_item "Distribución" "${HC_DATA[sys_distro]}"
    print_item "Kernel" "${HC_DATA[sys_kernel]}"
    
    print_section "2. Interfaces de Red"
    print_item "Disponibles" "${HC_DATA[if_all]}"
    print_item "Activa" "${HC_DATA[if_active]}"
    print_item "Estado (UP/DOWN)" "${HC_DATA[if_state]}"
    print_item "Velocidad Enlace" "${HC_DATA[if_speed]}"
    print_item "Dirección MAC" "${HC_DATA[if_mac]}"
    print_item "IPv4" "${HC_DATA[if_ipv4]}"
    print_item "IPv6" "${HC_DATA[if_ipv6]}"
    
    print_section "3. Configuración"
    print_item "Gateway" "${HC_DATA[cfg_gw]}"
    print_item "DNS Servers" "${HC_DATA[cfg_dns]}"
    print_item "MTU" "${HC_DATA[cfg_mtu]}"
    
    print_section "4. Conectividad (Internet & DNS)"
    print_item "Ping Gateway" "${HC_DATA[conn_gw]}"
    print_item "Ping 8.8.8.8" "${HC_DATA[conn_8888]}"
    print_item "Resolución DNS" "${HC_DATA[dns_res]}"
    print_item "HTTPS (1.1.1.1)" "Code: ${HC_DATA[http_code]}"
    
    print_section "5. Estado de Interfaz (Errores/Drop)"
    print_item "Paquetes RX/TX" "${HC_DATA[stat_rx_pkts]} / ${HC_DATA[stat_tx_pkts]}"
    print_item "Errores RX/TX" "${HC_DATA[stat_rx_errs]} / ${HC_DATA[stat_tx_errs]}"
    print_item "Descartados" "${HC_DATA[stat_drop]}"
    print_item "Overruns" "${HC_DATA[stat_overruns]}"
    print_item "Carrier Status" "${HC_DATA[stat_carrier]}"

    print_section "6. Servicios"
    print_item "NetworkManager" "${HC_DATA[svc_NetworkManager]}"
    print_item "systemd-resolved" "${HC_DATA[svc_systemd-resolved]}"
    print_item "systemd-networkd" "${HC_DATA[svc_systemd-networkd]}"
}

hc_present_ui() {
    clear 2>/dev/null || true
    printf "%b=================================================%b\n" "$C_BLU" "$C_NC"
    printf "       REPORTE DE SALUD DE RED (HEALTH CHECK)\n"
    printf "%b=================================================%b\n" "$C_BLU" "$C_NC"
    
    hc_present_ui_sections
    
    print_section "7. Resumen de Estado"
    printf "  %-15s %b\n" "Interfaces" "$(get_icon "${HC_DATA[st_iface]}")"
    printf "  %-15s %b\n" "Gateway" "$(get_icon "${HC_DATA[st_gw]}")"
    printf "  %-15s %b\n" "Internet" "$(get_icon "${HC_DATA[st_inet]}")"
    printf "  %-15s %b\n" "DNS" "$(get_icon "${HC_DATA[st_dns]}")"
    printf "  %-15s %b\n" "IPv6" "$(get_icon "${HC_DATA[st_ipv6]}")"
    printf "  %-15s %b\n" "Latencia" "$(get_icon "${HC_DATA[st_lat]}")"
    printf "  %-15s %b\n" "Errores RX/TX" "$(get_icon "${HC_DATA[st_err]}")"
    printf "  %-15s %b\n" "Servicios" "$(get_icon "${HC_DATA[st_svc]}")"
    echo ""
}

# -- 4. GENERACIÓN DE REPORTES --

hc_write_reports() {
    tk_log_info "Compilando reporte de auditoría (JSON/TXT)..."
    
    local txt_report
    txt_report=$(cat <<EOF
=== NETWORK HEALTH CHECK ===
Fecha: ${HC_DATA[sys_date]}
Host: ${HC_DATA[sys_host]}
OS: ${HC_DATA[sys_distro]}
Kernel: ${HC_DATA[sys_kernel]}

[Interfaces]
Activa: ${HC_DATA[if_active]} (${HC_DATA[if_state]}, ${HC_DATA[if_speed]})
MAC: ${HC_DATA[if_mac]}
IPv4: ${HC_DATA[if_ipv4]}
IPv6: ${HC_DATA[if_ipv6]}

[Configuración]
Gateway: ${HC_DATA[cfg_gw]}
DNS: ${HC_DATA[cfg_dns]}
MTU: ${HC_DATA[cfg_mtu]}
Rutas:
${HC_DATA[cfg_routes_txt]}

[Conectividad]
Ping GW: ${HC_DATA[conn_gw]}
Ping 8.8.8.8: ${HC_DATA[conn_8888]}
DNS Res: ${HC_DATA[dns_res]}
HTTPs: ${HC_DATA[http_code]}

[Estadísticas]
RX/TX Pkts: ${HC_DATA[stat_rx_pkts]} / ${HC_DATA[stat_tx_pkts]}
RX/TX Errs: ${HC_DATA[stat_rx_errs]} / ${HC_DATA[stat_tx_errs]}
Drops: ${HC_DATA[stat_drop]}

[Panel]
Iface:${HC_DATA[st_iface]} | GW:${HC_DATA[st_gw]} | Inet:${HC_DATA[st_inet]} | DNS:${HC_DATA[st_dns]} | IPv6:${HC_DATA[st_ipv6]} | Lat:${HC_DATA[st_lat]} | Err:${HC_DATA[st_err]} | Svc:${HC_DATA[st_svc]}
EOF
)
    
    local json_report
    if command -v jq >/dev/null 2>&1; then
        json_report=$(jq -n \
            --arg date "${HC_DATA[sys_date]}" --arg host "${HC_DATA[sys_host]}" --arg distro "${HC_DATA[sys_distro]}" --arg kernel "${HC_DATA[sys_kernel]}" \
            --arg iface "${HC_DATA[if_active]}" --arg state "${HC_DATA[if_state]}" --arg ip4 "${HC_DATA[if_ipv4]}" --arg ip6 "${HC_DATA[if_ipv6]}" \
            --arg gw "${HC_DATA[cfg_gw]}" --arg dns "${HC_DATA[cfg_dns]}" --arg mtu "${HC_DATA[cfg_mtu]}" \
            --arg pgw "${HC_DATA[conn_gw]}" --arg p8888 "${HC_DATA[conn_8888]}" --arg dnsres "${HC_DATA[dns_res]}" --arg http "${HC_DATA[http_code]}" \
            --arg rx "${HC_DATA[stat_rx_pkts]}" --arg tx "${HC_DATA[stat_tx_pkts]}" --arg rxerr "${HC_DATA[stat_rx_errs]}" --arg txerr "${HC_DATA[stat_tx_errs]}" \
            --arg st_inet "${HC_DATA[st_inet]}" --arg st_err "${HC_DATA[st_err]}" \
            '{
                timestamp: $date,
                system: { hostname: $host, distro: $distro, kernel: $kernel },
                interface: { name: $iface, state: $state, ipv4: $ip4, ipv6: $ip6, mtu: $mtu },
                network: { gateway: $gw, dns: $dns },
                connectivity: { ping_gw: $pgw, ping_inet: $p8888, dns_resolve: $dnsres, https_code: $http },
                statistics: { rx_packets: $rx, tx_packets: $tx, rx_errors: $rxerr, tx_errors: $txerr },
                summary: { internet_status: $st_inet, link_health: $st_err }
            }' 2>/dev/null || echo '{"error": "fallo interno de jq"}')
    else
        json_report='{"error": "jq no está instalado en el sistema."}'
    fi

    if declare -f tk_reporter_export > /dev/null; then
        tk_reporter_export "health_check" "$txt_report" "txt"
        tk_reporter_export "health_check" "$json_report" "json"
    else
        echo "[!] No se pudo exportar el reporte (Falta TK_REPORTS_DIR o reporter.sh)."
    fi
}

run_module() {
    hc_acquire_sys_info
    hc_acquire_net_info
    hc_acquire_svc_info
    hc_acquire_conn_info
    hc_process_status
    hc_present_ui
    hc_write_reports
    tk_log_info "Health Check concluido exitosamente."
}

# -- DESPACHADOR (API) --
case "${1:-}" in
    --get-name) get_name ;;
    --get-desc) get_desc ;;
    --run) shift; run_module "$@" ;;
    *) echo "Uso: $0 {--get-name|--get-desc|--run}" >&2; exit 1 ;;
esac
exit 0
