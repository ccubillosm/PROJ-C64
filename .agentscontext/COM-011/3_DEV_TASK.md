# Orden de Trabajo para Agente Desarrollador (Google Antigravity)

**Iniciativa:** [COM-011] Juego del gato
**Proyecto:** `PROJ-C64-POKER` | **Perfil Técnico:** `commodore_64_retro` (Commodore 64 Retro Dev (6502 ASM / C))
**Espacio de Trabajo (Repositorio):** `./`
**Estado:** 06_DEV_WORKING
**Reglas Obligatorias:** Lee y respeta [.antigravity/rules.md](file:///Users/acidlabs/Desktop/MultiAgente/.antigravity/rules.md) (Específicas de commodore_64_retro)
**Contexto del Proyecto:** [./PROJECT_CONTEXT.md](file:///Users/acidlabs/Desktop/MultiAgente/PROJECT_CONTEXT.md)

---

## 🎯 Instrucciones de Ejecución Binario Nativo / Commodore 64 Retro (MOS 6502 Assembly)
1. **REGLA OBLIGATORIA:** PROHIBIDO escribir la solución en HTML/JS si el stack del proyecto es C / 6502 Assembly. Debes crear los archivos `.asm` o `.c` dentro de `./src/`, compilarlos con el compilador configurado (`64tass -a src/main.asm -o build/program.prg -L build/program.lst`) y generar el archivo ejecutable `.prg` en `./build/`.
2. Nota: Etapa de Arquitectura omitida en este perfil. Implementa directamente respetando el requerimiento funcional y directrices del proyecto.
3. Nota: Especificación UX/UI omitida en este perfil. *(Nota: UI_PROTOTYPE.html es únicamente mockup de referencia visual para el Estudio 360° si aplica)*.
4. Consulta el contexto del proyecto en: [./PROJECT_CONTEXT.md](file:///Users/acidlabs/Desktop/MultiAgente/PROJECT_CONTEXT.md).
5. Comando de compilación: `64tass -a src/main.asm -o build/program.prg -L build/program.lst` (ej. `64tass -a src/main.asm -o build/program.prg -L build/program.lst`).
6. Genera el artefacto ejecutable `build/program.prg` (ej. `build/program.prg`) con cabecera de carga `$0801`.
7. **EXTENSIONES PROHIBIDAS:** ['.html', '.jsx', '.tsx', '.css'] (No crees archivos `.html`, `.jsx`, `.tsx`, `.css`).



---

### CONTEXTO Y ANTECEDENTES DEL PROYECTO
> Proyecto: **Commodore 64 Retro Poker Game** (`PROJ-C64-POKER`) | Información contextual relevante para el rol `DEV`.

#### Manual de Estilo UX/UI del Proyecto
VIC-II Screen codes.

#### Stack Tecnológico Oficial
64tass + MOS 6502.

#### Configuraciones y Parámetros Técnicos
VICE C64.
- [Lección C64P-001]: VIC-II: Screen RAM ($0400) exige códigos de pantalla (.enc screen / .enc none)
- [Lección C64P-001]: VIC-II: Screen RAM ($0400) exige códigos de pantalla (.enc screen / .enc none)
- [Lección C64P-001]: VIC-II: Screen RAM ($0400) exige códigos de pantalla (.enc screen / .enc none)
- [Lección C64P-001]: VIC-II: Screen RAM ($0400) exige códigos de pantalla (.enc screen / .enc none)
- [Lección C64P-001]: VIC-II: Screen RAM ($0400) exige códigos de pantalla (.enc screen / .enc none)
- [Lección C64P-001]: VIC-II: Screen RAM ($0400) exige códigos de pantalla (.enc screen / .enc none)
- [Lección C64P-001]: VIC-II: Screen RAM ($0400) exige códigos de pantalla (.enc screen / .enc none)

#### Notas y Directivas Adicionales
Cartas y naipes.

---

## FASE FINAL DE DESARROLLO: HANDOFF OBLIGATORIO A QA (PROHIBIDO CERRAR INICIATIVA)

**IMPORTANTE:** NO ejecutes ningún script que marque la iniciativa como `COMPLETED` ni corras el antiguo `qa_agent.py` automático. Tu trabajo en esta etapa de Desarrollo termina dejando preparado el entorno y el prompt dinámico para la etapa de **QA en Antigravity**.

Cuando hayas terminado de implementar y compilar el código en `./`, ejecuta obligatoriamente estos 2 pasos finales:

### PASO 1: Generar el archivo `.agentscontext/COM-011/4_QA_TASK.md`
Basándote en el código real que acabas de escribir (nombres exactos de archivos, rutas, endpoints, selectores DOM/HTML o direcciones de memoria/subrutinas ASM) y cruzándolo con los contratos disponibles:
- Requerimiento Crudo (PO omitido): "El implementa el clásico juego del gato, que es cruz y circulo, CPU contra Humano o Humano versus Humano. el que forma una linea con su propio signo X o O gana."
- `./PROJECT_CONTEXT.md`

Crea el archivo `.agentscontext/COM-011/4_QA_TASK.md` con la siguiente estructura exacta (rellenando las secciones entre corchetes con los datos reales de tu implementación):

```markdown
# TAREA DE AUDITORÍA QA Y AUTOMATIZACIÓN DE PRUEBAS (ANTIGRAVITY QA STAGE)
**Iniciativa:** COM-011
**Espacio de Trabajo (Repositorio):** `./`
**Directorio de Contexto:** `.agentscontext/COM-011`

## 1. MISIÓN DEL AGENTE QA EN ANTIGRAVITY
Actúa como **Principal SDET y Auditor de Código (Estilo CodeRabbit)**. El desarrollo ha finalizado. Tu objetivo NO es hacer un smoke test superficial, sino auditar el código fuente real línea por línea, diseñar y escribir las pruebas automatizadas en la tecnología correspondiente al proyecto, ejecutarlas en la terminal y registrar el veredicto certificando el Definition of Done (DoD).

## 2. INVENTARIO REAL DE LO IMPLEMENTADO EN DESARROLLO
[LISTAR AQUÍ LOS ARCHIVOS CREADOS/MODIFICADOS EN `./`, SUS FUNCIONES, ENDPOINTS, SELECTORES UI O SUBRUTINAS PRINCIPALES Y CÓMO SE COMPILA/EJECUTA LA APLICACIÓN]

## 3. PLAN DE PRUEBAS A IMPLEMENTAR Y EJECUTAR (SEGÚN STACK DEL PROYECTO)
Lee `./PROJECT_CONTEXT.md` y los contratos en `.agentscontext/COM-011/`. Debes escribir y ejecutar en `./` una suite de pruebas automatizadas en la tecnología nativa del proyecto que valide:

1. **Pruebas Funcionales de Casos de Uso:**
   [DETALLAR AQUÍ CADA CRITERIO DE ACEPTACIÓN Y QUÉ FUNCIÓN/RUTA/INTERACCIÓN REAL DEL CÓDIGO DEBE PROBAR EL TEST]

2. **Pruebas de Paridad Visual y Diseño:**
   [DETALLAR AQUÍ QUÉ COMPONENTES O LAYOUT DEBEN VERIFICARSE, O INDICAR 'N/A' SI UX/UI FUE OMITIDO]

3. **Pruebas de Arquitectura y Anti-Stubs:**
   [DETALLAR AQUÍ CONTRATOS, MANEJO DE ERRORES Y AUSENCIA DE STUBS, O INDICAR 'N/A' SI ARCH FUE OMITIDO]

## 4. EJECUCIÓN Y REGISTRO DE RESULTADOS (OBLIGATORIO)
1. **Escribe el archivo de pruebas** dentro de `./tests/` (o la ruta de tests del proyecto).
2. **Ejecuta las pruebas en la terminal del IDE** y captura la salida real (`stdout`, `stderr` y `exit_code`).
3. **Realiza la auditoría línea por línea (Estilo CodeRabbit)** sobre los archivos implementados en `./`.
4. **Genera el archivo `.agentscontext/COM-011/4_QA_REPORT.json`** respetando estrictamente el esquema JSON oficial y un resumen legible en `.agentscontext/COM-011/QA_REPORT.txt`.
   - **Regla de Oro:** Si al menos 1 test falla o si cualquier DoD activo incumple un requisito, `overall_status` DEBE ser `"REJECTED"`.
```

### PASO 2: Notificar Entrega de Desarrollo (Modo Híbrido / Laboratorio)
Puedes utilizar cualquiera de las siguientes vías habilitadas:

- **Opción CLI Bridge (`BRIDGE_CLI`):**
  Ejecuta en tu terminal:
  ```bash
  python .agentscontext/ma_bridge.py complete-dev --issue COM-011
  ```

- **Opción Rama Git (`GIT_BRANCH`):**
  Asegura que `.agentscontext/COM-011/3_DEV_OUTPUT.md` (y `.agentscontext/COM-011/4_QA_TASK.md` si aplica) esté guardado y ejecuta:
  ```bash
  git add .
  git commit -m "feat(COM-011): complete dev task"
  git push origin main
  ```
  *(Luego pulsa 'Sincronizar Rama Git' en la plataforma web para certificar)*

- **Opción Manual (`MANUAL_ZIP`):**
  Copia o sube el contenido de `.agentscontext/COM-011/3_DEV_OUTPUT.md` en la pestaña de Desarrollo de la plataforma web.

*(Retrocompatibilidad terminal local: `python orchestrator.py --handoff-qa COM-011`)*