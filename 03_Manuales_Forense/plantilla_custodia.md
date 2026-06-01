# 📋 Plantilla de Registro de Cadena de Custodia

Este documento sirve como plantilla oficial para el registro e historial de control de cualquier evidencia física o digital recolectada durante una investigación de incidente o auditoría forense.

---

## 🔍 Información General del Caso

*   **Número de Caso / Incidente:** `[Ej. INC-2026-001]`
*   **Investigador Principal:** `[Nombre Completo del Responsable]`
*   **Fecha de Apertura:** `[AAAA-MM-DD]`

---

## 📦 Detalle del Elemento de Evidencia (Item)

*   **Identificador de Ítem:** `[Ej. ITEM-001]`
*   **Qué se Recolectó (Descripción de la Evidencia):**
    *   *Tipo de activo:* `[Ej. Imagen Forense, Disco Duro, Dispositivo Móvil, Archivo Log, Volcado de RAM]`
    *   *Marca / Modelo / Número de Serie (si aplica):* `[Ej. Seagate 1TB, S/N: 12345678]`
    *   *Detalles lógicos:* `[Ej. Copia bit a bit del volumen /dev/sdb1]`
*   **Valor de Integridad (Hash):**
    *   *Algoritmo:* `[SHA-256 / MD5]`
    *   *Valor de Hash original:* `[Insertar hash hexadecimal generado inmediatamente después de la captura, ej: 8f4e3c2b...]`
*   **Quién Recolectó:** `[Nombre, Cargo y Firma del recolector original]`
*   **Fecha y Hora de Recolección:** `[AAAA-MM-DD HH:MM:SS TZ]`
*   **Ubicación Original de la Recolección (Dónde se guardó inicialmente):** `[Ej. Oficina de Finanzas, Servidor de Producción IP 10.0.1.25, etc.]`

---

## 🔄 Historial de Transferencia de Custodia (Audit Trail)

*Este registro debe actualizarse inmediatamente cada vez que la evidencia se mueva, se examine o cambie de responsable. No se permiten saltos cronológicos ni espacios en blanco.*

| Fecha y Hora | Entregado Por (Nombre y Firma) | Recibido Por (Nombre y Firma) | Dónde se Guardó / Nueva Ubicación | Por qué se Movió (Propósito de la Transferencia) |
| :--- | :--- | :--- | :--- | :--- |
| `[AAAA-MM-DD HH:MM]` | `[Nombre]` | `[Nombre]` | `[Ej. Caja Fuerte de Evidencias, Lab Forense]` | `[Ej. Recolección inicial y traslado seguro]` |
| `[AAAA-MM-DD HH:MM]` | `[Nombre]` | `[Nombre]` | `[Ej. Estación de Trabajo Forense #2]` | `[Ej. Análisis forense y generación de copia de trabajo]` |
| `[AAAA-MM-DD HH:MM]` | `[Nombre]` | `[Nombre]` | `[Ej. Caja Fuerte de Evidencias, Lab Forense]` | `[Ej. Retorno al almacenamiento seguro post-análisis]` |

---

## 📝 Nota de Estudio (Study Note) - Integridad mediante Hashing

*   **Concepto clave de Google Cybersecurity Certificate:** *Cryptographic Hashing for Integrity* (Funciones Hash Criptográficas).
*   **Traducción y Resumen Práctico:** En informática forense, no puedes simplemente abrir un archivo de evidencia para ver si está bien. Hacerlo alteraría metadatos críticos como la fecha de acceso. Por eso se crea un **valor hash (la "huella digital" única del archivo)** utilizando algoritmos como SHA-256 antes y después de cualquier análisis. **Si un solo bit de la evidencia cambia, el hash será completamente diferente (efecto avalancha), demostrando que la evidencia fue manipulada o se corrompió.**
