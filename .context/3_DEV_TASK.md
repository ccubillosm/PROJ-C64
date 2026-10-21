# Orden de Trabajo para Agente Desarrollador (Google Antigravity)

**Iniciativa:** [C64P-001] Motor de Lógica de Cartas y Pantalla Principal de Apuestas para C64 Poker
**Proyecto:** `PROJ-C64-POKER` | **Perfil Técnico:** `commodore_64_retro` (Commodore 64 Retro Dev (6502 ASM / C))
**Espacio de Trabajo (Sandbox):** `sandboxes/PROJ-C64-POKER/`
**Estado:** 06_DEV_WORKING
**Reglas Obligatorias:** Lee y respeta [.antigravity/rules.md](file:///Users/acidlabs/Desktop/MultiAgente/.antigravity/rules.md) (Específicas de commodore_64_retro)
**Contexto del Proyecto:** [sandboxes/PROJ-C64-POKER/PROJECT_CONTEXT.md](file:///Users/acidlabs/Desktop/MultiAgente/sandboxes/PROJ-C64-POKER/PROJECT_CONTEXT.md)

---

## 🎯 Instrucciones de Ejecución Binario Nativo / Commodore 64 Retro (MOS 6502 Assembly)
1. **REGLA OBLIGATORIA:** PROHIBIDO escribir la solución en HTML/JS si el stack del proyecto es C / 6502 Assembly. Debes crear los archivos `.asm` o `.c` dentro de `sandboxes/PROJ-C64-POKER/src/`, compilarlos con el compilador configurado (`64tass -a src/main.asm -o build/program.prg -L build/program.lst`) y generar el archivo ejecutable `.prg` en `sandboxes/PROJ-C64-POKER/build/`.
2. Lee detalladamente el plan de arquitectura: [.agentscontext/C64P-001/2B_IMPLEMENTATION_PLAN.md](file:///Users/acidlabs/Desktop/MultiAgente/.agentscontext/C64P-001/2B_IMPLEMENTATION_PLAN.md).
3. Revisa la especificación UX/UI técnica de memoria VIC-II y sprites: [.agentscontext/C64P-001/2A_UXUI_SPEC.md](file:///Users/acidlabs/Desktop/MultiAgente/.agentscontext/C64P-001/2A_UXUI_SPEC.md). *(Nota: UI_PROTOTYPE.html es únicamente mockup de referencia visual para el Estudio 360°)*.
4. Consulta el contexto del proyecto en: [sandboxes/PROJ-C64-POKER/PROJECT_CONTEXT.md](file:///Users/acidlabs/Desktop/MultiAgente/sandboxes/PROJ-C64-POKER/PROJECT_CONTEXT.md).
5. Comando de compilación: `64tass -a src/main.asm -o build/program.prg -L build/program.lst` (ej. `64tass -a src/main.asm -o build/program.prg -L build/program.lst`).
6. Genera el artefacto ejecutable `build/program.prg` (ej. `build/program.prg`) con cabecera de carga `$0801`.
7. **EXTENSIONES PROHIBIDAS:** ['.html', '.jsx', '.tsx', '.css'] (No crees archivos `.html`, `.jsx`, `.tsx`, `.css`).



---

### CONTEXTO Y ANTECEDENTES DEL PROYECTO
> Proyecto: **Commodore 64 Retro Poker Game** (`PROJ-C64-POKER`) | Información contextual relevante para el rol `DEV`.

#### Manual de Estilo UX/UI del Proyecto
Pantalla monocromática o multicolor de 40x25 caracteres sobre el VIC-II de C64. Uso intensivo de caracteres de cartas personalizados mediante custom charset ($3000), colores contrastantes para fichas y textos, y manejo del teclado de C64 para seleccionar opciones (ej. Teclas 1-5 para descartar/seleccionar, R para retirar, A para apostar).

#### Stack Tecnológico Oficial
Ensamblador MOS 6502/6510 utilizando la sintaxis de `64tass`. Compilación hacia binario ejecutable `.prg` con dirección de inicio en BASIC stub `$0801`.

#### Configuraciones y Parámetros Técnicos
Zero Page disponible en `$02-$8F`. Screen RAM en `$0400`. Rutinas de manejo de números pseudoaleatorios y lógica de cartas optimizadas para ciclos de CPU limitados.

#### Notas y Directivas Adicionales
Asegurar compatibilidad con ciclos PAL/NTSC en VIC-II y optimizar llamadas a interrupciones IRQ de raster.

---
*Cuando finalices los cambios en `sandboxes/PROJ-C64-POKER/`, ejecuta `python orchestrator.py finish-dev --id C64P-001` para lanzar la certificación de QA.*