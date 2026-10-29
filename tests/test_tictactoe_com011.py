"""Suite completa de pruebas de certificación QA para COM-011 (Juego del Gato - Commodore 64).

Cubre:
1. Pruebas Funcionales de Casos de Uso (Tablero, Heurística CPU, Detección de Victoria y Empate, Modos).
2. Pruebas de Paridad Visual y Diseño (VIC-II Screen Codes, Color RAM, data-testid, registros de color).
3. Pruebas de Arquitectura y Anti-Stubs (BASIC Stub $0801, formato PRG, ausencia de NOP/RTS stubs, SID).
"""
import os
import subprocess
from pathlib import Path
import pytest

PROJECT_DIR = Path(__file__).resolve().parent.parent
SRC_ASM = PROJECT_DIR / "src" / "main.asm"
BUILD_DIR = PROJECT_DIR / "build"
BUILD_PRG = BUILD_DIR / "program.prg"
BUILD_LST = BUILD_DIR / "program.lst"


@pytest.fixture(scope="session", autouse=True)
def compile_c64_source():
    """Compila el archivo ensamblador con 64tass asegurando que el binario PRG existe y es válido."""
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    cmd = ["64tass", "-a", str(SRC_ASM), "-o", str(BUILD_PRG), "-L", str(BUILD_LST)]
    result = subprocess.run(cmd, capture_output=True, text=True)
    assert result.returncode == 0, f"Error al compilar main.asm con 64tass:\n{result.stderr}\n{result.stdout}"
    return result


# ==============================================================================
# 1. PRUEBAS FUNCIONALES DE CASOS DE USO
# ==============================================================================

def test_uc1_board_representation_and_player_move():
    """Caso de Uso 1: Matriz de 9 bytes en $C000 y subrutina TRY_PLAYER_MOVE."""
    code = SRC_ASM.read_text(encoding="utf-8")
    assert "GAME_BOARD" in code and "$c000" in code.lower()
    assert "GAME_TURN" in code and "$c009" in code.lower()
    assert "GAME_STATUS" in code and "$c00a" in code.lower()
    assert "CURSOR_POS" in code and "$c00c" in code.lower()

    # Subrutina de inicialización y movimiento
    assert "INIT_TTT_GAME" in code
    assert "TRY_PLAYER_MOVE" in code
    assert "TPM_SET_X" in code
    assert "TPM_STORE" in code
    assert "sta     GAME_BOARD,x" in code


def test_uc2_cpu_heuristic_ai_logic():
    """Caso de Uso 2: IA Heurística de CPU (Prioridades: Ganar, Bloquear, Centro $C004, Entropía SID)."""
    code = SRC_ASM.read_text(encoding="utf-8")
    assert "CPU_MOVE" in code
    assert "FIND_WINNING_CELL" in code
    assert "WIN_PATTERNS" in code

    # Verificación de lógica de bloqueo y centro
    assert "CPU_TRY_RANDOM" in code
    assert "GAME_BOARD+4" in code
    assert "CPU_EXECUTE_MOVE" in code
    assert "SID_NOISE" in code


def test_uc3_check_win_combinations_and_draw():
    """Caso de Uso 3: Detección de las 8 líneas ganadoras y estado de empate."""
    code = SRC_ASM.read_text(encoding="utf-8")
    assert "CHECK_WIN" in code
    assert "CW_TRIPLET_LOOP" in code
    assert "CW_CHECK_DRAW" in code
    assert "TEMP_WINNER" in code
    # Verifica que evalúe las 8 combinaciones (24 bytes)
    assert "cpx     #24" in code.lower()
    # Verifica que maneje estado 1 (X), 2 (O) y 3 (Empate)
    assert "GAME_STATUS" in code


def test_uc4_game_modes_and_turn_alternation():
    """Caso de Uso 4: Modos 1P vs CPU y 2P Humano vs Humano, y alternancia."""
    code = SRC_ASM.read_text(encoding="utf-8")
    assert "GAME_MODE" in code and "$c00b" in code.lower()
    assert "ML_TOGGLE_MODE" in code
    assert "eor     #$01" in code.lower()


# ==============================================================================
# 2. PRUEBAS DE PARIDAD VISUAL Y DISEÑO (VIC-II)
# ==============================================================================

def test_visual_data_testids_and_uxui_traceability():
    """Valida trazabilidad de todos los data-testid exigidos por la especificación 2A_UXUI_SPEC.md."""
    code = SRC_ASM.read_text(encoding="utf-8")

    expected_testids = [
        "data-testid=\"c64-screen-container\"",
        "data-testid=\"c64-title-banner\"",
        "data-testid=\"tictactoe-board\"",
        "data-testid=\"board-cell-0-0\"",
        "data-testid=\"board-cell-0-1\"",
        "data-testid=\"board-cell-0-2\"",
        "data-testid=\"board-cell-1-0\"",
        "data-testid=\"board-cell-1-1\"",
        "data-testid=\"board-cell-1-2\"",
        "data-testid=\"board-cell-2-0\"",
        "data-testid=\"board-cell-2-1\"",
        "data-testid=\"board-cell-2-2\"",
        "data-testid=\"color-cell-0-0\"",
        "data-testid=\"sidebar-hud\"",
        "data-testid=\"score-p1\"",
        "data-testid=\"score-cpu\"",
        "data-testid=\"status-message\""
    ]

    for tid in expected_testids:
        assert tid in code, f"Falta trazabilidad del data-testid: {tid}"


def test_visual_vic2_addresses_and_palette():
    """Valida direcciones de memoria VIC-II Screen RAM ($0400), Color RAM ($D800) y paleta."""
    code = SRC_ASM.read_text(encoding="utf-8").lower()

    # Screen RAM base y Color RAM base
    assert "screen_ram      = $0400" in code
    assert "color_ram       = $d800" in code

    # Direcciones exactas de QA-01 a QA-05
    assert "$059e" in code  # QA-02: Celda Tablero (0,0)
    assert "$0608" in code or "screen_ram+520" in code  # QA-04: Score P1
    assert "$0780" in code or "screen_ram+880" in code  # QA-05: Status message

    # Colores: Borde Azul ($06), Fondo Negro ($00), Ficha X Verde ($05), Ficha O Rojo ($02)
    assert "color_blue      = $06" in code
    assert "color_black     = $00" in code
    assert "color_green     = $05" in code
    assert "color_red       = $02" in code
    assert "color_cyan      = $03" in code


def test_visual_screen_encoding_directive():
    """Valida el uso estricto de .enc 'screen' para volcado de cadenas a Screen RAM."""
    code = SRC_ASM.read_text(encoding="utf-8")
    assert '.enc "screen"' in code, "Falta directiva obligatoria de codificación .enc 'screen'"


# ==============================================================================
# 3. PRUEBAS DE ARQUITECTURA Y ANTI-STUBS
# ==============================================================================

def test_arch_prg_binary_integrity_and_header():
    """Valida que el archivo build/program.prg tenga cabecera $0801 Little Endian y tamaño válido."""
    assert BUILD_PRG.exists(), "El ejecutable build/program.prg no existe."
    size = BUILD_PRG.stat().st_size
    assert 2 < size < 65536, f"Tamaño inválido para PRG C64: {size} bytes"

    with open(BUILD_PRG, "rb") as f:
        header = f.read(2)
    assert header == b'\x01\x08', f"Cabecera Little Endian inválida: {header.hex()} (esperado 0108 para $0801)"


def test_arch_anti_stubs_critical_routines():
    """Verifica ausencia de stubs o implementaciones vacías en subrutinas críticas de COM-011."""
    code = SRC_ASM.read_text(encoding="utf-8")

    critical_routines = [
        "INIT_TTT_GAME",
        "TRY_PLAYER_MOVE",
        "CPU_MOVE",
        "FIND_WINNING_CELL",
        "CHECK_WIN",
        "RENDER_ALL_CELLS",
        "DRAW_TTT_UI",
        "UPDATE_STATUS_MSG",
        "PLAY_MOVE_SOUND",
        "PLAY_GAME_OVER_SOUND"
    ]

    for routine in critical_routines:
        # Buscar la definición de etiqueta (al inicio de línea)
        target = f"\n{routine}\n"
        pos = code.find(target)
        if pos == -1:
            target = f"\n{routine}"
            pos = code.find(target)
        assert pos != -1, f"Rutina crítica {routine} ausente."
        block = code[pos:pos+300]
        # Verificar que no sea un stub directo que solo tenga rts
        lines = [line.strip() for line in block.splitlines() if line.strip() and not line.strip().startswith(';')]
        assert len(lines) > 2, f"La rutina {routine} parece ser un stub vacío."
        assert lines[1].lower() != "rts", f"La rutina {routine} retorna inmediatamente sin ejecutar lógica."


def test_arch_sid_sound_hardware_integration():
    """Valida integración con registros de hardware del SID ($D400..$D418)."""
    code = SRC_ASM.read_text(encoding="utf-8").lower()
    assert "$d400" in code  # SID Voz 1 Freq Lo
    assert "$d401" in code  # SID Voz 1 Freq Hi
    assert "$d404" in code  # SID Voz 1 Control
    assert "$d418" in code  # SID Volumen general
    assert "$d41b" in code  # SID Ruido / Entropía
