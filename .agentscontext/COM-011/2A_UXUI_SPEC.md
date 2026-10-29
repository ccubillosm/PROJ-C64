# Especificación de Interfaz de Usuario VIC-II (COM-011: Juego del Gato)

Este documento define la arquitectura visual y de memoria para el clásico juego de Tres en Raya (Gato / Tic-Tac-Toe) adaptado para el chip **VIC-II** del **Commodore 64**.

> **AVISO DE IMPLEMENTACIÓN:** El código final de producción para este proyecto es **100% MOS 6502 Assembly / C** (utilizando el compilador cc65 o ensamblador ACME/KickAssembler). El formato HTML adjunto es estrictamente un **mockup visual de referencia** para el Estudio 360°.

---

## 1. Paleta de 16 Colores Oficial del VIC-II
Para mantener la estética clásica de Commodore 64, se utiliza la paleta oficial:

| Hex | Color VIC-II | Uso en UI COM-011 |
|-----|--------------|-------------------|
| `$0` | Black        | Fondo general de pantalla |
| `$1` | White        | Texto principal y títulos |
| `$2` | Red          | Victoria / Alertas / Ficha 'O' |
| `$3` | Cyan         | Tablero y elementos HUD |
| `$4` | Purple       | Borde decorativo |
| `$5` | Green        | Ficha 'X' / Mensaje de Turno |
| `$6` | Blue         | Zonas de fondo secundarias |
| `$7` | Yellow       | Puntuación y Highlights |
| `$8` | Orange       | Detalles de cartas/marcos |
| `$9` | Brown        | Sombra de celdas |
| `$A` | Light Red    | Énfasis secundario |
| `$B` | Dark Grey    | Líneas de división |
| `$C` | Grey         | Celdas inactivas |
| `$D` | Light Green  | Animaciones de victoria |
| `$E` | Light Blue   | Cursor de selección |
| `$F` | Light Grey   | Borde exterior |

---

## 2. Mapa de Memoria de Pantalla ($0400 - $07E7)
La pantalla consta de una matriz de **40 columnas x 25 filas** (1000 bytes).

* **Filas 0-2:** Cabecera institucional ("COMMODORE 64 - TRES EN RAYA")
* **Filas 4-20:** Zona central de juego (Tablero 3x3 y Marcador lateral)
* **Filas 22-24:** Barra de estado y comandos de control (F1: CPU, F3: 2P, F5: Reset)

### Distribución de Coordenadas Principales
* `$0400`: Esquina superior izquierda (Fila 0, Col 0)
* Tablero de Gato centrado en columnas `10` a `29`, filas `6` a `18`.
* Marcador de Puntos (Jugador 1 vs CPU/Jugador 2) en columnas `31` a `38`.

---

## 3. Mapa de Color RAM ($D800 - $DBE7)
Cada celda de la pantalla de texto tiene asignada un color de 4 bits (valores `$0` a `$F`) en el banco de Color RAM ($D800-$DBE7):

* **Color de Texto/Fichas (`X` y `O`):** 
  * 'X' (Verde - `$5`)
  * 'O' (Rojo - `$2`)
  * Tablero (Cyan - `$3`)
* **Fondo VIC-II (Registro `$D021`):** Negro (`$0`)
* **Borde VIC-II (Registro `$D020`):** Azul (`$6`)

---

## 4. Definición de Caracteres Personalizados (UDG / Cset) y Sprites
Para lograr símbolos nítidos para las fichas 'X' y 'O' y mantener la herencia del poker/cartas del sistema:

### Matriz UDG para Ficha 'X' (Carácter `$E0`)
```text
Row 0: %11000011 ($C3)
Row 1: %01100110 ($66)
Row 2: %00111100 ($3C)
Row 3: %00011000 ($18)
Row 4: %00011000 ($18)
Row 5: %00111100 ($3C)
Row 6: %01100110 ($66)
Row 7: %11000011 ($C3)
```

### Matriz UDG para Ficha 'O' (Carácter `$E1`)
```text
Row 0: %00111100 ($3C)
Row 1: %01000010 ($42)
Row 2: %10000001 ($81)
Row 3: %10000001 ($81)
Row 4: %10000001 ($81)
Row 5: %10000001 ($81)
Row 6: %01000010 ($42)
Row 7: %00111100 ($3C)
```

---

## 5. Matriz de Verificación para QA

| ID Test | Componente | Dirección Memoria | Valor Esperado (Hex) | Descripción | `data-testid` |
|---------|------------|-------------------|----------------------|----------------------|----------------|
| QA-01 | Título principal | `$0428` | `$43 ('C')` | Inicio del banner C64 | `c64-title-banner` |
| QA-02 | Celda Tablero (0,0) | `$059E` | `$E0 (UDG 'X')` | Posición superior izq | `board-cell-0-0` |
| QA-03 | Color RAM Celda (0,0) | `$D99E` | `$05 (Green)` | Color de la ficha X | `color-cell-0-0` |
| QA-04 | Marcador P1 | `$0608` | `$30 ('0')` | Puntuación inicial P1 | `score-p1` |
| QA-05 | Estado del Juego | `$0780` | `$54 ('T')` | Mensaje "TURNO JUGADOR 1" | `status-message` |