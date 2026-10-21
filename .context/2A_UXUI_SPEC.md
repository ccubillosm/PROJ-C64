# Especificación de Diseño UX/UI y Hardware (VIC-II C64)
**Iniciativa ID:** C64P-001 | Motor de Lógica de Cartas y Pantalla Principal de Apuestas para C64 Poker  
**Rol:** Diseñador de Interfaces / Experto en VIC-II (Commodore 64)

> **AVISO CRÍTICO DE IMPLEMENTACIÓN:** El código final de producción de este sistema es **100% MOS 6502 Assembly / C**. Queda estrictamente PROHIBIDO escribir la solución lógica o de producción en lenguajes de alto nivel web (HTML/JS). El archivo `UI_PROTOTYPE.html` adjunto en este paquete actúa **únicamente como mockup visual de referencia** para la previsualización en el Estudio 360°.

---

## 1. Mapa de Memoria de Pantalla VIC-II (40x25 celdas)
El VIC-II controla una matriz estándar de 40 columnas por 25 filas de texto. Para el motor de póker, la pantalla se divide en zonas funcionales fijas para evitar parpadeos y optimizar la actualización de celdas mediante direccionamiento directo.

*   **Rango Screen RAM:** `$0400 - $07E7` (1000 bytes totales).
*   **Organización por filas:**
    *   `$0400 - $0427`: Fila 0 (Cabecera de Estado / Título del Juego)
    *   `$0428 - $071F`: Filas 1 a 18 (Área de juego principal, mesa, zona de cartas comunitarias y mano del jugador)
    *   `$0720 - $0797`: Filas 19 a 21 (Panel de diálogo / Mensajes de estado / Apuestas)
    *   `$0798 - $07E7`: Filas 22 a 24 (Panel de Fichas, Saldo, Controles y Ayuda de Teclado)

---

## 2. Color RAM y Mapeo de Atribución (`$D800 - $DBE7`)
Cada celda en Screen RAM tiene un byte correspondiente en Color RAM (`$D800`), el cual define el color de primer plano (nibble inferior 0-F) para ese carácter específico.

| Zona de Pantalla | Rango Screen RAM | Rango Color RAM | Color Predeterminado | Valor Hex VIC-II | Descripción Estética |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Cabecera / Título** | `$0400-$0427` | `$D800-$D827` | Amarillo / Azul | `$7` / `$6` | Título brillante sobre fondo oscuro. |
| **Tapete de Mesa** | `$0428-$071F` | `$D828-$DB1F` | Verde Oscuro / Claro | `$5` / `$D` | Simula el paño de fieltro de la mesa. |
| **Cartas (Corazones/Diamantes)**| *Variable* | *Variable* | Rojo / Blanco | `$2` / `$1` | Identificación visual clara de palos rojos. |
| **Cartas (Picas/Tréboles)** | *Variable* | *Variable* | Negro / Blanco | `$0` / `$1` | Alto contraste para palos oscuros. |
| **Panel de Fichas / Apuestas**| `$0798-$07E7` | `$D998-$DBE7` | Cian / Blanco | `$3` / `$1` | Información financiera legible y destacada. |

---

## 3. Paleta Oficial de 16 Colores del VIC-II
El VIC-II opera con una paleta fija de 16 colores mapeada en los registros de hardware `$D020-$D023` y Color RAM:

| Hex | Color | Uso en C64 Poker | Hex | Color | Uso en C64 Poker |
| :---: | :--- | :--- | :---: | :--- | :--- |
| `$0` | Negro | Picas/Tréboles, Bordes | `$8` | Naranja | Acentos de alerta |
| `$1` | Blanco | Texto general, Fondos de carta | `$9` | Marrón | Detalles de mesa |
| `$2` | Rojo | Corazones/Diamantes, Errores | `$A` | Rojo Claro | Selecciones activas |
| `$3` | Cyan | Saldo de fichas, Menús | `$B` | Gris Oscuro | Sombra de elementos |
| `$4` | Púrpura | Elementos secundarios | `$C` | Gris Medio | Líneas divisorias |
| `$5` | Verde Oscuro | Tapete de juego (`$D021`) | `$D` | Verde Claro | Texto resaltado |
| `$6` | Azul | Cabeceras de ventana | `$E` | Azul Claro | Fondos secundarios |
| `$7` | Amarillo | Títulos y Puntuaciones | `$F` | Gris Claro | Textos inactivos |

---

## 4. Definición de Caracteres Personalizados (UDG / Charset)
Para evitar las limitaciones del PETSCII estándar en la representación de naipes, se define un bloque de caracteres personalizados ubicado en `$2000-$27FF` (apuntado mediante `$D018`). Cada carta se compone de un bloque de 3x3 celdas de texto.

### Estructura de Datos de Glifos (Ejemplo: Símbolo de Corazón - 8x8 píxeles / 8 bytes)
```assembly
; Definición de patrón binario para Corazón (Hexadecimal)
CHAR_HEART:
    .byte %00011010  ; Row 0: ..@@.@@.
    .byte %00111111  ; Row 1: .@@@@@@.
    .byte %01111111  ; Row 2: @@@@@@@@
    .byte %01111111  ; Row 3: @@@@@@@@
    .byte %00111110  ; Row 4: .@@@@@..
    .byte %00011100  ; Row 5: ...@@@..
    .byte %00001000  ; Row 6: ....@...
    .byte %00000000  ; Row 7: ........
```

---

## 5. Matriz de Verificación para QA (Pruebas de Unidad / Hardware)

| ID Prueba | Componente | Dirección / Registro | Valor Esperado | Criterio de Éxito QA |
| :--- | :--- | :--- | :--- | :--- |
| **QA-01** | VIC-II Control | `$D011` | Bit 4 = `1` | Pantalla activada correctamente tras el arranque. |
| **QA-02** | Color de Fondo | `$D021` | `$05` (Verde Oscuro) | Fondo de pantalla configurado como tapete de póker. |
| **QA-03** | Color de Borde | `$D020` | `$00` (Negro) | Marco exterior del monitor en negro puro. |
| **QA-04** | Inicialización Mazo | `$1000 - `$1033 | 52 bytes únicos (`1-53`) | Ausencia de cartas duplicadas en el array del mazo. |
| **QA-05** | Memoria de Pantalla | `$0400` | `$20` (Espacio) | Limpieza total de pantalla completada sin basura. |
| **QA-06** | Color RAM Fichas | `$D798` | `$03` (Cyan) | Panel de fichas con atribución de color correcta. |

---

## 6. Tabla de Atributos `data-testid` (Referencia UI Prototype)

| data-testid | Elemento UI / Componente | Mapeo Memoria C64 Real | Función Principal |
| :--- | :--- | :--- | :--- |
| `screen-container` | Monitor VIC-II C64 | `$0400-$07E7` + `$D800` | Contenedor principal de la matriz 40x25. |
| `status-header` | Cabecera de Estado | `$0400-$0427` | Muestra título, ronda y estado del juego. |
| `card-slot-1` a `5` | Zonas de Cartas del Jugador | Filas 8-10, Cols 4-32 | Renderizado visual de la mano de 5 cartas (3x3 celdas). |
| `chip-panel` | Panel de Fichas y Apuesta | `$0798-$07E7` | Visualización BCD de saldo y apuesta actual. |
| `terminal-log` | Log de Eventos / Acciones | Filas 19-21 | Mensajes del sistema (Dealer, Apuestas, Victorias). |
| `kbd-help` | Barra de Ayuda Teclado | Fila 24 | Indicadores de teclas activas (`1-5`, `SPACE`, `R`). |