Entendido. Como Product Owner para este desarrollo en Commodore 64, noto una discrepancia entre el contexto previo (Poker) y el nuevo requerimiento (Gato/Tic-Tac-Toe). Asumiré que el "Juego del Gato" es un **módulo adicional o mini-juego** dentro de la suite `PROJ-C64-POKER`.

Dado que el C64 tiene recursos limitados, implementaremos el tablero usando **Caracteres Definidos por el Usuario (UDG)** para ahorrar RAM de video y usaremos **Sprites** para el selector de casilla.

Aquí tienes la definición técnica del requerimiento:

---

### Épica: COM-011 - Módulo Tic-Tac-Toe (Gato)

#### Historia de Usuario 1: Lógica de Tablero y Renderizado
**Como** jugador de C64,
**Quiero** visualizar un tablero de 3x3 con símbolos X y O definidos con claridad,
**Para** poder jugar una partida sin ambigüedad visual.

*   **INVEST:**
    *   **I**ndependiente: No depende del motor de Poker.
    *   **N**egociable: Los glifos pueden ser PETSCII o UDG.
    *   **V**aliosa: Provee la base visual del juego.
    *   **E**stimable: ~4-6 horas de ensamblado.
    *   **S**mall: Acotado a la matriz de 3x3.
    *   **T**esteable: Verificable vía Screen RAM.

*   **Reglas de Negocio Técnicas (RNT):**
    1.  **Memoria de Video:** El tablero se ubicará en `$0400` (Screen RAM). Se usarán caracteres personalizados cargados en `$2000-$27FF`.
    2.  **Representación en Memoria:** El estado del juego se guardará en una matriz de 9 bytes en `$C000` (00=Vacío, 01=X, 02=O).
    3.  **Sprites:** Se usará el **Sprite 0** como cursor de selección, moviéndose en coordenadas fijas (X/Y) correspondientes al centro de cada celda.
    4.  **Color:** X en color Blanco (`$01`), O en color Rojo (`$02`) vía Color RAM en `$D800`.

*   **Criterios de Aceptación (Gherkin):**
    *   **Escenario:** Dibujar símbolo en tablero.
        *   **Dado** que el jugador selecciona la casilla central (índice 4).
        *   **Cuando** presiona el botón de disparo (Fire) del Joystick en Port 2.
        *   **Entonces** el valor en la dirección de memoria `$C004` debe cambiar a `$01`.
        *   **Y** el byte en la Screen RAM correspondiente a esa posición debe actualizarse con el índice del carácter 'X'.

---

#### Historia de Usuario 2: Inteligencia Artificial (CPU Opponent)
**Como** jugador solitario,
**Quiero** enfrentarme a una CPU que tome decisiones lógicas,
**Para** tener un reto cuando no hay un segundo jugador.

*   **INVEST:** (Independiente, Valiosa, Testeable).

*   **Reglas de Negocio Técnicas (RNT):**
    1.  **Algoritmo:** Debido a la limitación de ciclos de raster, no usaremos Minimax completo, sino una **Máquina de Estados Heurística**:
        *   Prioridad 1: Ganar (si hay 2 en línea).
        *   Prioridad 2: Bloquear (si el humano tiene 2 en línea).
        *   Prioridad 3: Ocupar el centro (`$C004`).
        *   Prioridad 4: Aleatorio en espacios vacíos.
    2.  **Delay:** La CPU debe esperar 30 frames (aprox. 0.5s en PAL) antes de mover para simular "pensamiento" y no confundir al jugador.

*   **Criterios de Aceptación (Gherkin):**
    *   **Escenario:** CPU bloquea victoria humana.
        *   **Dado** que el Humano (X) ocupa `$C000` y `$C001`.
        *   **Cuando** es el turno de la CPU (O).
        *   **Entonces** la rutina de IA debe escribir `$02` en `$C002` antes de cualquier otro movimiento aleatorio.

---

#### Historia de Usuario 3: Detección de Victoria y Sonido (SID)
**Como** jugador,
**Quiero** que el juego identifique automáticamente quién ganó y emita un sonido,
**Para** finalizar la partida formalmente.

*   **Reglas de Negocio Técnicas (RNT):**
    1.  **Check de Victoria:** Se ejecutará una subrutina después de cada movimiento que compare los 8 posibles combos de victoria (3 filas, 3 columnas, 2 diagonales).
    2.  **Sonido (SID):**
        *   **Victoria:** Barrido de frecuencia ascendente en Voz 1 (Filtro Pasa-Banda activo).
        *   **Empate:** Ruido blanco (Waveform `$80`) corto en Voz 1.
    3.  **Interrupción:** Al ganar, se debe deshabilitar el movimiento del Sprite 0 para evitar cambios post-game.

*   **Criterios de Aceptación (Gherkin):**
    *   **Escenario:** Detección de línea horizontal superior.
        *   **Dado** que las direcciones `$C000`, `$C001` y `$C002` contienen el valor `$01`.
        *   **Cuando** se ejecuta la subrutina `CHECK_WIN`.
        *   **Entonces** el registro de estado de juego `$C00A` debe setearse en `$01` (Human Wins).
        *   **Y** el acumulador `A` debe cargar el valor de la nota para el SID.

---

### Mapa de Memoria Propuesto (Acotado a 64KB)

| Rango | Función | Descripción |
| :--- | :--- | :--- |
| `$0400 - `$07E7` | Screen RAM | Visualización del tablero y texto. |
| `$D800 - `$DBE7` | Color RAM | Colores de las X y O. |
| `$2000 - `$27FF` | Charset | Glifos personalizados para el tablero. |
| `$C000 - `$C008` | Game State | Matriz de 3x3 (9 bytes). |
| `$C009` | Turn Flag | 00 = Humano, 01 = CPU/Jugador 2. |
| `$0314 - `$0315` | IRQ Vector | Manejo de música y lectura de Joystick a 50/60Hz. |

**Notas del PO:**
Para mantener la consistencia con el proyecto **Poker**, se recomienda usar la misma paleta de colores (Verde de tapete para el fondo) y la misma rutina de lectura de Joystick que ya se definió para la selección de cartas.