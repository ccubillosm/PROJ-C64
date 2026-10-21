# Contexto y Antecedentes del Proyecto: PROJ-C64-POKER (PROJ-C64-POKER)

## 1. Reglas de Negocio (business_rules)
> **Agentes Consumidores:** PO, ARCH, QA
Juego de Póker clásico (Texas Hold'em simplificado o Draw Poker) para un solo jugador contra 3 contrincantes controlados por la CPU. Debe incluir interfaz basada en caracteres PETSCII, apuestas con fichas virtuales, baraja de 52 cartas y lógica de evaluación de manos de póker (Par, Trío, Escalera, Color, Full House, etc.).

## 2. Manual de Estilo UX/UI (ux_style_guide)
> **Agentes Consumidores:** UXUI, DEV, QA
Pantalla monocromática o multicolor de 40x25 caracteres sobre el VIC-II de C64. Uso intensivo de caracteres de cartas personalizados mediante custom charset ($3000), colores contrastantes para fichas y textos, y manejo del teclado de C64 para seleccionar opciones (ej. Teclas 1-5 para descartar/seleccionar, R para retirar, A para apostar).

## 3. User Persona & Journey (user_personas_journey)
> **Agentes Consumidores:** PO, UXUI
Jugador nostálgico de los 8 bits que busca una experiencia de juego de cartas rápida, fluida y con animaciones de texto fluidas en hardware real o emulador VICE.

## 4. Stack Tecnológico (tech_stack)
> **Agentes Consumidores:** ARCH, DEV, QA
Ensamblador MOS 6502/6510 utilizando la sintaxis de `64tass`. Compilación hacia binario ejecutable `.prg` con dirección de inicio en BASIC stub `$0801`.

## 5. Configuraciones Técnicas (tech_configs)
> **Agentes Consumidores:** ARCH, DEV, QA
Zero Page disponible en `$02-$8F`. Screen RAM en `$0400`. Rutinas de manejo de números pseudoaleatorios y lógica de cartas optimizadas para ciclos de CPU limitados.

## 6. Notas Adicionales (custom_notes)
> **Agentes Consumidores:** Todos los agentes (PO, UXUI, ARCH, DEV, QA)
Asegurar compatibilidad con ciclos PAL/NTSC en VIC-II y optimizar llamadas a interrupciones IRQ de raster.
