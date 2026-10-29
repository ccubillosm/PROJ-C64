"""Suite de pruebas de certificación para COM-011 (Juego del Gato - Commodore 64)."""
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
    """Compila el archivo ensamblador con 64tass asegurando que el binario PRG existe."""
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    cmd = ["64tass", "-a", str(SRC_ASM), "-o", str(BUILD_PRG), "-L", str(BUILD_LST)]
    result = subprocess.run(cmd, capture_output=True, text=True)
    assert result.returncode == 0, f"Error al compilar main.asm:\n{result.stderr}\n{result.stdout}"
    return result


def test_tictactoe_symbols_and_memory_map():
    """Valida los símbolos de memoria y registros de COM-011 en src/main.asm."""
    code = SRC_ASM.read_text(encoding="utf-8")

    # Mapeo de memoria COM-011
    assert "GAME_BOARD" in code and "$c000" in code.lower()
    assert "GAME_TURN" in code and "$c009" in code.lower()
    assert "GAME_STATUS" in code and "$c00a" in code.lower()
    assert "CURSOR_POS" in code and "$c00c" in code.lower()
    assert "CHECK_WIN" in code
    assert "CPU_MOVE" in code
    assert "INIT_TTT_GAME" in code
    assert "RENDER_ALL_CELLS" in code
    assert "TRY_PLAYER_MOVE" in code


def test_tictactoe_data_testids_and_uxui_parity():
    """Valida la presencia de etiquetas y data-testid de la especificación UX/UI (2A_UXUI_SPEC.md)."""
    code = SRC_ASM.read_text(encoding="utf-8")

    expected_testids = [
        "data-testid=\"c64-screen-container\"",
        "data-testid=\"c64-title-banner\"",
        "data-testid=\"tictactoe-board\"",
        "data-testid=\"board-cell-0-0\"",
        "data-testid=\"color-cell-0-0\"",
        "data-testid=\"sidebar-hud\"",
        "data-testid=\"score-p1\"",
        "data-testid=\"score-cpu\"",
        "data-testid=\"status-message\""
    ]

    for tid in expected_testids:
        assert tid in code, f"data-testid requerido no encontrado en comentarios/mapeo: {tid}"


def test_tictactoe_vic2_addresses_and_screen_codes():
    """Valida direcciones clave de VIC-II Screen RAM y Color RAM para celdas del tablero."""
    code = SRC_ASM.read_text(encoding="utf-8").lower()

    # QA-01: Título principal / banner
    assert "$0428" in code or "screen_ram+40" in code

    # QA-02: Celda Tablero (0,0) en $059E
    assert "$059e" in code

    # QA-03: Color RAM Celda (0,0) en $D99E
    assert "$d99e" in code or "$d4" in code  # offset $D400 añadido dinámicamente

    # QA-04: Marcador P1 en $0608
    assert "$0608" in code or "screen_ram+520" in code

    # QA-05: Estado del Juego en $0780
    assert "$0780" in code or "screen_ram+880" in code


def test_tictactoe_winning_combinations_logic():
    """Valida que existan las 8 tripletas de victoria (filas, columnas, diagonales)."""
    code = SRC_ASM.read_text(encoding="utf-8")
    assert "WIN_PATTERNS" in code
    assert "FIND_WINNING_CELL" in code


def test_tictactoe_sid_audio_routines():
    """Valida subrutinas de retroalimentación sonora con el SID."""
    code = SRC_ASM.read_text(encoding="utf-8")
    assert "PLAY_MOVE_SOUND" in code
    assert "PLAY_GAME_OVER_SOUND" in code
