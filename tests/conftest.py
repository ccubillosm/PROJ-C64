"""Configuración de pytest para proyectos Commodore 64 / Binarios Nativos."""
import pytest
from pathlib import Path


@pytest.fixture
def project_root():
    return Path(__file__).resolve().parent.parent


@pytest.fixture
def build_dir(project_root):
    bdir = project_root / "build"
    bdir.mkdir(parents=True, exist_ok=True)
    return bdir
