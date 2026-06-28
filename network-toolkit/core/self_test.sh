# ===================================================================
# Archivo: self_test.sh
# Responsabilidad: Ejecutar rutinas de autodiagnóstico del sistema.
# ===================================================================

TK_TESTS_RUN=0
TK_TESTS_OK=0
TK_TESTS_WARN=0
TK_TESTS_FAIL=0

TK_C_RED='\033[0;31m'
TK_C_GREEN='\033[0;32m'
TK_C_YELLOW='\033[1;33m'
TK_C_NC='\033[0m'

_test_log() {
    local status="$1"
    local message="$2"
    # Prevenir fallos con set -e en bash: ((VAR++)) falla si el valor anterior era 0.
    TK_TESTS_RUN=$((TK_TESTS_RUN + 1))
    if [[ "$status" == "OK" ]]; then
        TK_TESTS_OK=$((TK_TESTS_OK + 1))
        printf "[ ${TK_C_GREEN}OK${TK_C_NC} ]   %s\n" "$message"
    elif [[ "$status" == "WARN" ]]; then
        TK_TESTS_WARN=$((TK_TESTS_WARN + 1))
        printf "[ ${TK_C_YELLOW}WARN${TK_C_NC} ] %s\n" "$message"
    else
        TK_TESTS_FAIL=$((TK_TESTS_FAIL + 1))
        printf "[ ${TK_C_RED}FAIL${TK_C_NC} ] %s\n" "$message"
    fi
}

tk_run_self_test() {
    echo ""
    echo "========================================="
    echo "   NETWORK TOOLKIT - AUTO-DIAGNÓSTICO"
    echo "========================================="
    echo ""

    # 1. Estructura completa del proyecto
    local proj_structure_ok=true
    for f in "install.sh" "bin/net-toolkit" "core/ui.sh"; do
        if [[ ! -f "${TK_BASE_DIR}/$f" ]]; then proj_structure_ok=false; fi
    done
    if $proj_structure_ok; then _test_log "OK" "Estructura completa del proyecto"; else _test_log "FAIL" "Estructura completa del proyecto"; fi

    # 2. Existencia de directorios
    local all_dirs_ok=true
    for d in "logs" "tmp" "reports" "modules" "conf" "core"; do
        if [[ ! -d "${TK_BASE_DIR}/$d" ]]; then all_dirs_ok=false; fi
    done
    if $all_dirs_ok; then _test_log "OK" "Existencia de directorios"; else _test_log "FAIL" "Existencia de directorios"; fi

    # 3. Permisos
    if [[ -w "${TK_LOGS_DIR}" && -w "${TK_REPORTS_DIR}" && -w "${TK_TMP_DIR}" ]]; then
        _test_log "OK" "Permisos de escritura del sistema"
    else
        _test_log "FAIL" "Permisos de escritura del sistema"
    fi

    # 4. Archivo de configuración
    if [[ -f "${TK_BASE_DIR}/conf/toolkit.conf" ]]; then
        _test_log "OK" "Existencia del archivo de configuración"
    else
        _test_log "FAIL" "Existencia del archivo de configuración"
    fi

    # 5. Funcionamiento del logger
    if declare -f tk_log > /dev/null; then
        _test_log "OK" "Funcionamiento del logger (Cargado en memoria)"
    else
        _test_log "FAIL" "Funcionamiento del logger (Cargado en memoria)"
    fi

    # 6. Funcionamiento del reporter
    if declare -f tk_reporter_export > /dev/null; then
        _test_log "OK" "Funcionamiento del reporter (Cargado en memoria)"
    else
        _test_log "FAIL" "Funcionamiento del reporter (Cargado en memoria)"
    fi

    # 7. Funcionamiento del cargador de módulos
    if declare -f tk_module_loader_scan > /dev/null && [[ ${#TK_MODULE_PATHS[@]} -ge 0 ]]; then
        _test_log "OK" "Funcionamiento del cargador de módulos"
    else
        _test_log "FAIL" "Funcionamiento del cargador de módulos"
    fi

    # 8. Funcionamiento del menú
    if declare -f tk_ui_main_menu > /dev/null; then
        _test_log "OK" "Funcionamiento del menú"
    else
        _test_log "FAIL" "Funcionamiento del menú"
    fi

    # 9. Carga correcta de un módulo de prueba
    if [[ -x "${TK_MODULES_DIR}/00_template.sh" ]]; then
        local mod_name
        mod_name=$("${TK_MODULES_DIR}/00_template.sh" --get-name 2>/dev/null || true)
        if [[ "$mod_name" == "Plantilla" ]]; then
            _test_log "OK" "Carga correcta de un módulo de prueba"
        else
            _test_log "FAIL" "Carga correcta de un módulo de prueba (Interfaz incorrecta)"
        fi
    else
        _test_log "WARN" "Carga correcta de un módulo de prueba (Ausente o sin permisos)"
    fi

    # 10. Escritura en logs
    local log_test_str="TEST_LOG_WRITE_$(date +%s)"
    tk_log_info "$log_test_str"
    if grep -q "$log_test_str" "${TK_LOG_FILE}"; then
        _test_log "OK" "Escritura persistente en logs"
    else
        _test_log "FAIL" "Escritura persistente en logs"
    fi

    # 11. Escritura en reports
    local rep_test_name="selftest"
    tk_reporter_export "$rep_test_name" "TEST CONTENT" "txt" >/dev/null 2>&1
    shopt -s nullglob
    local test_reports=("${TK_REPORTS_DIR}"/report_${rep_test_name}_*.txt)
    shopt -u nullglob
    if [[ ${#test_reports[@]} -gt 0 ]]; then
        _test_log "OK" "Escritura correcta en motor de reports"
        rm -f "${test_reports[@]}" # Limpieza automática
    else
        _test_log "FAIL" "Escritura correcta en motor de reports"
    fi

    # 12. Validación de dependencias
    local deps_ok=true
    for dep in "curl" "jq" "nmap" "dnsutils"; do
        if ! command -v "$dep" >/dev/null 2>&1; then deps_ok=false; fi
    done
    if $deps_ok; then
        _test_log "OK" "Validación de dependencias externas (APT)"
    else
        _test_log "FAIL" "Validación de dependencias externas (APT)"
    fi

    # 13. Rutas
    if [[ "$TK_BASE_DIR" == /* && -d "$TK_BASE_DIR" ]]; then
        _test_log "OK" "Validación estricta de rutas y paths"
    else
        _test_log "FAIL" "Validación estricta de rutas y paths"
    fi

    # 14. Permisos de ejecución
    if [[ -x "${TK_BASE_DIR}/bin/net-toolkit" && -x "${TK_BASE_DIR}/install.sh" ]]; then
        _test_log "OK" "Permisos de ejecución de binarios"
    else
        _test_log "FAIL" "Permisos de ejecución de binarios"
    fi

    echo ""
    echo "========================================="
    echo " Tests ejecutados: $TK_TESTS_RUN"
    echo ""
    echo -e " ${TK_C_GREEN}OK${TK_C_NC}:   $TK_TESTS_OK"
    echo -e " ${TK_C_YELLOW}WARN${TK_C_NC}: $TK_TESTS_WARN"
    echo -e " ${TK_C_RED}FAIL${TK_C_NC}: $TK_TESTS_FAIL"
    echo "========================================="
    echo ""

    if [[ $TK_TESTS_FAIL -gt 0 ]]; then
        return 1
    fi
    return 0
}
