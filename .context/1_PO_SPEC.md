Entendido, Comandante de Código. Como Product Owner para este desarrollo en 6502, he desglosado la iniciativa **C64P-001** en Historias de Usuario técnicas, optimizadas para las restricciones del MOS 6510 y el VIC-II.

Aquí tienes el Backlog Refinado para el Sprint 1:

---

### Historia de Usuario 1: Inicialización de Sistema y Layout de Mesa
**ID: C64P-001-ST01**
**Prioridad: Crítica**

**Como** Desarrollador,
**Quiero** que el programa arranque desde un BASIC Stub y configure el VIC-II en modo texto con colores de mesa de póker,
**Para** establecer el entorno visual base sin colisiones de memoria.

*   **Reglas de Negocio Técnicas:**
    *   **Stub de Inicio:** Debe residir en `$0801` con el token `SYS 2062` (`$080E`).
    *   **Mapa de Memoria:** El código principal debe residir entre `$080E` y `$9FFF`. El área `$C000-$CFFF` se reserva para el set de caracteres personalizado (Cartas).
    *   **Configuración VIC-II:** Fondo (`$D021`) y Borde (`$D020`) configurados en Verde Oscuro (`$05`) o Negro (`$00`) para simular fielmente el tapete.
    *   **Limpieza de Pantalla:** Uso de la rutina KERNAL `$E544` o un bucle `STA $0400,x` optimizado.

*   **Criterios de Aceptación (Gherkin):**
    *   **Given** que el C64 está en el prompt de READY.
    *   **When** se carga el binario y se ejecuta `RUN`.
    *   **Then** el registro PC debe saltar a `$080E`.
    *   **And** el registro `$D011` (Screen Control) debe tener el bit 4 activo (pantalla encendida).
    *   **And** la memoria de pantalla `$0400-$07E7` debe llenarse con el carácter de espacio (`$20`).

---

### Historia de Usuario 2: Motor de Baraja y Gestión de Memoria de Cartas
**ID: C64P-001-ST02**
**Prioridad: Alta**

**Como** Motor de Juego,
**Quiero** inicializar un array de 52 bytes que represente el mazo y una rutina de barajado,
**Para** garantizar que las cartas sean aleatorias y no se repitan.

*   **Reglas de Negocio Técnicas:**
    *   **Estructura de Datos:** Un array de 52 bytes en `$1000`. Cada byte: Bits 0-3 (Valor: 1-13), Bits 4-5 (Palo: 0=Corazones, 1=Diamantes, 2=Tréboles, 3=Picas).
    *   **Entropía (RNG):** Se debe usar el registro de ruido del SID (`$D41B`) como semilla para el algoritmo de barajado (Fisher-Yates simplificado).
    *   **Puntero de Mazo:** Un byte en Zero Page (`$FB`) para rastrear la posición de la siguiente carta a repartir.

*   **Criterios de Aceptación (Gherkin):**
    *   **Given** que el mazo está inicializado en `$1000`.
    *   **When** se llama a la subrutina `SHUFFLE_DECK`.
    *   **Then** el contenido de `$1000-$1033` no debe contener valores duplicados.
    *   **And** el registro `$D412` (SID Control) debe haber sido configurado previamente para generar ruido.

---

### Historia de Usuario 3: Renderizado de Cartas y Panel de Fichas
**ID: C64P-001-ST03**
**Prioridad: Alta**

**Como** Jugador,
**Quiero** ver mis 5 cartas representadas gráficamente en la pantalla y mi saldo de fichas,
**Para** poder tomar decisiones de apuesta.

*   **Reglas de Negocio Técnicas:**
    *   **Charset Personalizado:** Cargar en `$2000` (o `$C000`) los glifos para los palos (PETSCII no es suficiente para cartas de alta calidad). Apuntar `$D018` para usar este set.
    *   **Dibujo de Carta:** Cada carta ocupa un bloque de 3x3 caracteres en la Screen RAM.
    *   **Panel de Fichas:** Ubicado en la línea 23-24 (`$0798` en adelante). Los valores numéricos deben convertirse de Hexadecimal a Decimal (BCD) para mostrarse en pantalla.

*   **Criterios de Aceptación (Gherkin):**
    *   **Given** que el mazo está barajado.
    *   **When** el usuario presiona la tecla `SPACE` (detectado vía `$FFE4` GETIN).
    *   **Then** la rutina de dibujo debe escribir en `$0400 + offset` los índices de caracteres correspondientes a las 5 cartas del tope del mazo.
    *   **And** el Color RAM (`$D800`) debe actualizarse: Rojo (`$02`) para Corazones/Diamantes, Negro (`$00`) para Picas/Tréboles.

---

### Mapa de Memoria Propuesto (Memory Map)

| Rango | Función | Notas |
| :--- | :--- | :--- |
| `$0002-$00FF` | Zero Page | Punteros de pantalla y variables de mazo. |
| `$0801-$080D` | BASIC Stub | `10 SYS 2062` |
| `$080E-$0FFF` | Código Principal | Lógica de juego y control de flujo. |
| `$1000-$1033` | Deck Array | 52 bytes (Mazo actual). |
| `$2000-$27FF` | Custom Charset | Definición de glifos de cartas. |
| `$0400-$07E7` | Screen RAM | Mesa de juego (40x25). |
| `$D800-$DBE7` | Color RAM | Atributos de color por carácter. |

---

### Notas del PO para el Equipo de Desarrollo:
*   **Optimización de Ciclos:** La rutina de barajado no debe ejecutarse durante el VBLANK para evitar "glitches" visuales si se usa música SID de fondo más adelante.
*   **Restricción de Sprites:** No usaremos sprites para las cartas para evitar el límite de 8 por línea; todo se manejará mediante redefinición de caracteres (Tiles) para permitir las 5 cartas del jugador + las de la CPU simultáneamente.

**¿Procedemos con la implementación de la subrutina de barajado o prefieres definir primero el set de caracteres?**