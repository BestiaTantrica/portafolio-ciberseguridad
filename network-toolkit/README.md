# Network Toolkit

Herramienta profesional de diagnóstico y monitoreo de red, diseñada en Bash para sistemas Linux. Creado como parte del portafolio de ciberseguridad, con un enfoque en código limpio, arquitectura modular y fácil mantenimiento.

## Arquitectura del Proyecto

El proyecto está diseñado bajo una arquitectura modular y desacoplada (Plug-and-play). El núcleo principal solo orquesta y provee servicios compartidos (logging, manejo de errores), mientras que toda la lógica de red reside en módulos independientes.

- `bin/net-toolkit`: Punto de entrada principal. Carga la configuración, inicializa el núcleo y levanta la interfaz.
- `conf/`: Configuración global y variables de entorno del sistema.
- `core/`: Motor del sistema.
  - `logger.sh`: Sistema de logs estandarizado.
  - `error_handler.sh`: Captura de señales y fallos para apagado seguro.
  - `module_loader.sh`: Lógica de auto-descubrimiento de plugins.
  - `ui.sh`: Interfaz gráfica en terminal interactiva.
  - `validator.sh`: Verificaciones de integridad y dependencias.
  - `reporter.sh`: Funciones estandarizadas para guardar hallazgos de forma segura.
- `modules/`: Plugins independientes. No están fuertemente acoplados al núcleo.
- `logs/`, `reports/`, `tmp/`: Almacenamiento local de ejecución y resultados.

## Flujo de Ejecución

1. **Inicialización**: `bin/net-toolkit` se ejecuta y localiza el directorio base.
2. **Validación**: `validator.sh` revisa si existen los directorios necesarios, permisos de escritura y las dependencias críticas instaladas en el sistema.
3. **Descubrimiento**: `module_loader.sh` escanea `/modules`, interrogando de forma aislada a cada script (`--get-name`, `--get-desc`). Los módulos con fallos en la interfaz son ignorados sin romper la ejecución.
4. **Interacción**: `ui.sh` renderiza dinámicamente el menú.
5. **Ejecución y Aislamiento**: Al lanzar una opción, el módulo se ejecuta. Si el módulo falla (Exit Status > 0), el núcleo captura el fallo, lo registra en el log y el sistema continúa operando.

## Instalación

El toolkit incluye un instalador automático que detecta tu distribución y valida/instala de forma inteligente las herramientas necesarias.

```bash
chmod +x install.sh
./install.sh
```

## Ejecución

Una vez instalado, arranca la herramienta:

```bash
./bin/net-toolkit
```

## Cómo crear un nuevo módulo

Añadir una herramienta nueva no requiere tocar código existente. Solo crea un archivo ejecutable en `modules/` (ej: `01_escaner.sh`) que implemente la siguiente interfaz (ver `00_template.sh` para el código base):

```bash
case "${1:-}" in
    --get-name) echo "Mi Herramienta" ;;
    --get-desc) echo "Descripción breve para el menú" ;;
    --run) shift; funcion_principal "$@" ;;
esac
```
