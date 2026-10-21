import os
import subprocess
import pytest

# Rutas relativas basadas en el workspace sandboxes/PROJ-C64-POKER/
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_ASM = os.path.join(PROJECT_DIR, "src", "main.asm")
BUILD_PRG = os.path.join(PROJECT_DIR, "build", "program.prg")
BUILD_LST = os.path.join(PROJECT_DIR, "build", "program.lst")

@pytest.fixture(scope="session", autouse=True)
def ensure_build():
    """Fixture para asegurar que el código ensamblado con 64tass existe antes de correr las pruebas QA."""
    os.makedirs(os.path.join(PROJECT_DIR, "build"), exist_ok=True)
    
    # Ejecutar 64tass
    cmd = ["64tass", "-a", SRC_ASM, "-o", BUILD_PRG, "-L", BUILD_LST]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    # Guardar resultado en atributo de clase o verificar directamente
    pytest.assembler_result = result

def test_source_file_exists():
    """Verifica la presencia y sintaxis básica del archivo fuente src/main.asm."""
    assert os.path.exists(SRC_ASM), f"El archivo fuente crítico {SRC_ASM} no existe."
    with open(SRC_ASM, "r", encoding="utf-8") as f:
        content = f.read()
    assert len(content) > 0, "El archivo src/main.asm está vacío."
    assert "* = $0801" in content, "El archivo asm debe definir el origen BASIC stub en $0801."

def test_assembler_execution():
    """Ejecuta el ensamblador 64tass verificando que exit_code == 0."""
    res = pytest.assembler_result
    assert res.returncode == 0, f"Error de ensamblaje 64tass:\nSTDOUT:\n{res.stdout}\nSTDERR:\n{res.stderr}"

def test_binary_prg_exists_and_size():
    """Valida que build/program.prg exista, no esté vacío y no exceda los límites de memoria de 64KB."""
    assert os.path.exists(BUILD_PRG), f"El binario ejecutable {BUILD_PRG} no fue generado."
    file_size = os.path.getsize(BUILD_PRG)
    assert file_size > 2, "El binario PRG es demasiado pequeño para contener un stub y código."
    assert file_size <= 65536, "El binario PRG excede los límites de memoria de 64KB del Commodore 64."

def test_binary_little_endian_header():
    """Valida que el archivo .prg tenga una cabecera de carga Little Endian válida ($01 $08 para $0801)."""
    with open(BUILD_PRG, "rb") as f:
        header = f.read(2)
    
    # $0801 en Little Endian se almacena como byte bajo 0x01, byte alto 0x08
    assert header == b'\x01\x08', f"Cabecera PRG inválida. Esperada: 0x01 0x08 ($0801), Obtenida: {header.hex()}"

def test_gherkin_routines_and_labels_presence():
    """Valida que el código fuente contenga las rutinas y etiquetas exigidas en los escenarios Gherkin del PO."""
    with open(SRC_ASM, "r", encoding="utf-8") as f:
        code = f.read()

    # Etiquetas críticas de control e inicialización
    required_symbols = [
        "SYS_START",
        "CLEAR_SCREEN",
        "INIT_DECK",
        "INIT_SID_RNG",
        "SHUFFLE_DECK",
        "DRAW_CARDS",
        "MAIN_LOOP"
    ]

    for symbol in required_symbols:
        assert symbol in code, f"Etiqueta o rutina requerida '{symbol}' no encontrada en el código fuente asm."

def test_memorymap_and_hardware_registers():
    """Valida la correcta utilización de los registros de hardware VIC-II, SID y mapa de memoria especificados."""
    with open(SRC_ASM, "r", encoding="utf-8") as f:
        code = f.read()

    # Registros VIC-II y SID obligatorios por especificación técnica
    hardware_markers = [
        "$d011",  # VIC_CTRL1 (Screen Control)
        "$d020",  # VIC_BORDER
        "$d021",  # VIC_BG0 (Tapete verde $05)
        "$d41b",  # SID_NOISE (Entropía RNG)
        "$0400",  # Screen RAM
        "$d800",  # Color RAM
        "$1000"   # Deck Array base
    ]

    for marker in hardware_markers:
        assert marker in code.lower(), f"Registro de hardware o dirección de memoria clave '{marker}' ausente en el código."