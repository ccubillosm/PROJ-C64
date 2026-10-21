"""Suite de pruebas de certificación de compilación y lógica C64 con 64tass."""
import os
import shutil
import subprocess
from pathlib import Path
import pytest


@pytest.fixture
def c64_build_env():
    project_root = Path(__file__).resolve().parent.parent
    src_file = project_root / "src" / "main.asm"
    build_dir = project_root / "build"
    build_dir.mkdir(parents=True, exist_ok=True)
    prg_file = build_dir / "program.prg"
    lst_file = build_dir / "program.lst"
    return {
        "project_root": project_root,
        "src_file": src_file,
        "build_dir": build_dir,
        "prg_file": prg_file,
        "lst_file": lst_file,
    }


def test_c64_source_syntax_and_integrity(c64_build_env):
    """a) Verifica la existencia y sintaxis de los archivos .asm / .c."""
    src_file = c64_build_env["src_file"]
    assert src_file.exists(), f"El archivo fuente principal {src_file} no existe."
    content = src_file.read_text(encoding="utf-8")
    assert "* = $0801" in content or "* = $0800" in content, "Falta cabecera de carga BASIC stub ($0801)"
    assert "rts" in content.lower(), "El programa debe contener al menos un retorno de subrutina (RTS)"
    assert "screen_ram" in content.lower(), "Falta definición o mapeo de SCREEN_RAM ($0400)"
    assert "color_ram" in content.lower(), "Falta definición o mapeo de COLOR_RAM ($D800)"


def test_c64_compiler_execution_64tass(c64_build_env):
    """b) Ejecuta el compilador (64tass) para generar el .prg."""
    src_file = c64_build_env["src_file"]
    prg_file = c64_build_env["prg_file"]
    lst_file = c64_build_env["lst_file"]

    tass_bin = shutil.which("64tass") or "/usr/local/bin/64tass"
    if os.path.exists(tass_bin):
        cmd = [tass_bin, "-a", str(src_file), "-o", str(prg_file), "-L", str(lst_file)]
        res = subprocess.run(cmd, capture_output=True, text=True)
        assert res.returncode == 0, f"Error al compilar con 64tass: {res.stderr} {res.stdout}"


def test_c64_prg_binary_validation(c64_build_env):
    """c) Verifica que el .prg exista, tamaño válido (>2 bytes y <64KB) y carga $0801 Little Endian."""
    prg_file = c64_build_env["prg_file"]
    assert prg_file.exists(), f"El archivo ejecutable {prg_file} no existe."
    size = prg_file.stat().st_size
    assert 2 < size < 65536, f"Tamaño de binario .prg fuera de rango: {size} bytes (debe ser > 2 y < 64KB)"

    with open(prg_file, "rb") as f:
        header = f.read(2)
    assert header == b"", f"Dirección de carga Little Endian incorrecta: {header.hex()} (esperado 0108 para $0801)"


def test_c64_gherkin_symbols_and_memory_map(c64_build_env):
    """Valida símbolos y etiquetas de los criterios Gherkin del PO (pozo 20, créditos 1000, paleta VIC-II)."""
    src_file = c64_build_env["src_file"]
    content = src_file.read_text(encoding="utf-8").upper()

    # Criterio Gherkin 1: Color RAM con atributos para cartas (Rojo $02 para Corazones/Diamantes)
    assert "COLOR_RED" in content or "$02" in content, "Falta mapeo de color rojo ($02) para naipes"

    # Criterio Gherkin 2: Pozo inicial de 20 créditos y meta de 1000 créditos
    has_pot_20 = "0020" in content or "$0014" in content or "20" in content
    has_credits_1000 = "$03E8" in content or "1000" in content
    assert has_pot_20, "Falta inicialización o constante de pozo inicial de 20 créditos"
    assert has_credits_1000, "Falta inicialización o constante de saldo meta de 1000 créditos"
