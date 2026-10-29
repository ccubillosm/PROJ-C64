# TAREA DE AUDITORÍA QA Y AUTOMATIZACIÓN DE PRUEBAS (ANTIGRAVITY QA STAGE)
**Iniciativa:** COM-011
**Espacio de Trabajo (Repositorio):** `./`
**Directorio de Contexto:** `.agentscontext/COM-011`

## 1. MISIÓN DEL AGENTE QA EN ANTIGRAVITY
Actúa como **Principal SDET y Auditor de Código (Estilo CodeRabbit)**. El desarrollo ha finalizado. Tu objetivo NO es hacer un smoke test superficial, sino auditar el código fuente real línea por línea, diseñar y escribir las pruebas automatizadas en la tecnología correspondiente al proyecto, ejecutarlas en la terminal y registrar el veredicto certificando el Definition of Done (DoD).

## 2. INVENTARIO REAL DE LO IMPLEMENTADO EN DESARROLLO
- **Archivos fuente y binarios creados/modificados:**
  - `src/main.asm`: Módulo completo de Tic-Tac-Toe (Gato / Tres en Raya) para Commodore 64 en ensamblador MOS 6502/6510, manteniendo compatibilidad con la suite PROJ-C64-POKER.
  - `build/program.prg`: Binario C64 generado con cabecera de carga `$0801` (Little-endian: `01 08`) y BASIC Loader Stub (`10 SYS 2062`).
  - `build/program.lst`: Archivo de listado de ensamblado generado por `64tass`.
  - `tests/test_tictactoe_com011.py`: Suite de certificación automatizada con pytest para COM-011.
  - `tests/test_c64_build.py` y `tests/test_c64p_001.py`: Suites preexistentes que continúan pasando al 100%.

- **Subrutinas Principales implementadas:**
  - `INIT_TTT_GAME`: Inicializa matriz de 9 bytes en `$C000-$C008`, turno `$C009`, estado `$C00A` y cursor `$C00C`.
  - `TRY_PLAYER_MOVE`: Procesa entrada humana, validación de celda vacía, colocación de ficha ('X' o 'O') y alternancia de turnos.
  - `CPU_MOVE`: Algoritmo heurístico de IA para oponente automático (Prioridad 1: Ganar si tiene 2 en línea; Prioridad 2: Bloquear si Humano tiene 2 en línea; Prioridad 3: Ocupar centro `$C004`; Prioridad 4: Espacio libre asistido por entropía SID `$D41B`).
  - `FIND_WINNING_CELL`: Búsqueda de líneas de victoria o bloqueo en las 8 combinaciones posibles.
  - `CHECK_WIN`: Evaluación de los 8 patrones ganadores (`WIN_PATTERNS`) y detección de empate (`GAME_STATUS` = `$01` Gana X, `$02` Gana O, `$03` Empate).
  - `RENDER_ALL_CELLS`: Renderiza las celdas en Screen RAM (`$0400+`) y Color RAM (`$D800+`) usando caracteres PETSCII/Screen Codes ('X' en Verde `$05`, 'O' en Rojo `$02`).
  - `DRAW_TTT_UI`: Dibuja cuadrícula del tablero centrado, títulos (`data-testid="c64-title-banner"`), HUD lateral (`data-testid="sidebar-hud"`) y barra de estado (`data-testid="status-message"`).
  - `UPDATE_STATUS_MSG` y `UPDATE_SCORES`: Actualiza textos de turnos/victoria en fila 22 (`$0780`) y marcadores numéricos en `$0608` (P1) y `$0630` (CPU/P2).
  - `PLAY_MOVE_SOUND` y `PLAY_GAME_OVER_SOUND`: Efectos sonoros mediante sintetizador SID (`$D400-$D418`) (Beep en movimiento, barrido de victoria y ruido blanco en empate).

- **Compilación y Ejecución:**
  ```bash
  64tass -a src/main.asm -o build/program.prg -L build/program.lst
  ```
  Ejecución de pruebas automatizadas:
  ```bash
  /Users/acidlabs/Desktop/MultiAgente/.venv/bin/pytest tests/
  ```

## 3. PLAN DE PRUEBAS A IMPLEMENTAR Y EJECUTAR (SEGÚN STACK DEL PROYECTO)
Lee `./PROJECT_CONTEXT.md` y los contratos en `.agentscontext/COM-011/`. Debes escribir y ejecutar en `./` una suite de pruebas automatizadas en la tecnología nativa del proyecto que valide:

1. **Pruebas Funcionales de Casos de Uso:**
   - **Caso de Uso 1 (Lógica de Tablero y Representación de Memoria):** Validar que la matriz de 9 bytes resida en `$C000-$C008` con valores `00` (vacío), `01` ('X') y `02` ('O'). Verificar que la subrutina `TRY_PLAYER_MOVE` escriba `$01` en `$C004` cuando el jugador selecciona la casilla central.
   - **Caso de Uso 2 (IA / CPU Opponent):** Validar que la subrutina `CPU_MOVE` y `FIND_WINNING_CELL` implementen la heurística de bloqueo: si Humano (X) ocupa `$C000` y `$C001`, la CPU (O) debe escribir `$02` en `$C002`.
   - **Caso de Uso 3 (Detección de Victoria y Empate):** Validar que `CHECK_WIN` evalúe las 8 ternas ganadoras (3 filas, 3 columnas, 2 diagonales). Si `$C000`, `$C001` y `$C002` contienen `$01`, `GAME_STATUS` (`$C00A`) debe setearse en `$01` (Victoria X) y cargar nota en acumulador A para el SID. Si el tablero se llena sin victoria, `GAME_STATUS` debe setearse en `$03` (Empate).
   - **Caso de Uso 4 (Alternancia y Modos de Juego):** Validar alternancia entre modo 1 Jugador vs CPU (`GAME_MODE` = `0`) y 2 Jugadores (`GAME_MODE` = `1`).

2. **Pruebas de Paridad Visual y Diseño:**
   - **Verificación de Paleta VIC-II y Registros:** Borde azul (`VIC_BORDER` = `$06`), fondo negro (`VIC_BG0` = `$00`), caracteres en Screen RAM (`$0400`) y atributos en Color RAM (`$D800`).
   - **Trazabilidad de `data-testid`:**
     - `c64-title-banner`: Banner en `$0428` ("**** COMMODORE 64 TRES EN RAYA ****").
     - `tictactoe-board`: Cuadrícula centrada en columnas 12-28, filas 6-17.
     - `board-cell-0-0` a `board-cell-2-2`: Celdas del tablero (ej. `board-cell-0-0` en Screen RAM `$059E`).
     - `color-cell-0-0`: Atributo Color RAM para celda (0,0) en `$D99E` (Color Verde `$05` para 'X' y Rojo `$02` para 'O').
     - `sidebar-hud`: Estadísticas laterales con `score-p1` en `$0608` y `score-cpu` en `$0630`.
     - `status-message`: Mensaje de estado/turno en fila 22 (`$0780`).

3. **Pruebas de Arquitectura y Anti-Stubs:**
   - **Cabecera Binaria y Tamaño PRG:** Carga Little-Endian `$0801` (`01 08`), tamaño de binario menor a 64KB y mayor a 2 bytes.
   - **Ausencia de Stubs:** Verificar que no existan subrutinas vacías (`NOP; RTS` o `RTS` inmediatos sin lógica) en las funciones críticas `CHECK_WIN`, `CPU_MOVE`, `TRY_PLAYER_MOVE`, `RENDER_ALL_CELLS`.
   - **Manejo Estricto de Encodings:** Uso de `.enc "screen"` para volcados de cadenas a Screen RAM evitando discrepancias PETSCII.

## 4. EJECUCIÓN Y REGISTRO DE RESULTADOS (OBLIGATORIO)
1. **Escribe el archivo de pruebas** dentro de `./tests/` (o la ruta de tests del proyecto).
2. **Ejecuta las pruebas en la terminal del IDE** y captura la salida real (`stdout`, `stderr` y `exit_code`).
3. **Realiza la auditoría línea por línea (Estilo CodeRabbit)** sobre los archivos implementados en `./`.
4. **Genera el archivo `.agentscontext/COM-011/4_QA_REPORT.json`** respetando estrictamente el esquema JSON oficial y un resumen legible en `.agentscontext/COM-011/QA_REPORT.txt`.
   - **Regla de Oro:** Si al menos 1 test falla o si cualquier DoD activo incumple un requisito, `overall_status` DEBE ser `"REJECTED"`.
