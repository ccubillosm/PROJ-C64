#!/usr/bin/env python3
"""MultiAgente Factory - CLI Bridge (.agentscontext/ma_bridge.py).

Herramienta de sincronización entre el workspace local y la plataforma web.
Uso:
  python .agentscontext/ma_bridge.py login --api-url <URL> --token <TOKEN>
  python .agentscontext/ma_bridge.py complete-dev [--issue <KEY>]
  python .agentscontext/ma_bridge.py submit-qa [--issue <KEY>]
  python .agentscontext/ma_bridge.py inject-lesson --lesson "<TEXTO>"
  python .agentscontext/ma_bridge.py pull-context [--issue <KEY>]
"""

import os
import sys
import json
import argparse
import urllib.request
import urllib.error
from pathlib import Path

CONFIG_FILENAME = "ma_config.json"


def load_dotenv():
    """Carga variables desde archivo .env local si existen (sin dependencias externas)."""
    candidates = [
        Path.cwd() / ".env",
        Path(".agentscontext") / ".env",
        Path(__file__).resolve().parent / ".env",
        Path(__file__).resolve().parent.parent / ".env",
    ]
    for env_path in candidates:
        if env_path.is_file():
            try:
                for line in env_path.read_text(encoding="utf-8").splitlines():
                    line = line.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    k, v = line.split("=", 1)
                    k = k.strip()
                    v = v.strip()
                    for q in ['"', chr(39)]:
                        if len(v) >= 2 and v.startswith(q) and v.endswith(q):
                            v = v[1:-1]
                    if k and k not in os.environ:
                        os.environ[k] = v
            except Exception:
                pass


load_dotenv()


def find_config_path() -> Path:
    candidates = [
        Path(".agentscontext") / CONFIG_FILENAME,
        Path(__file__).resolve().parent / CONFIG_FILENAME,
        Path.cwd() / ".agentscontext" / CONFIG_FILENAME,
    ]
    for c in candidates:
        if c.exists():
            return c
    return Path(".agentscontext") / CONFIG_FILENAME


def load_config() -> dict:
    cfg_path = find_config_path()
    if cfg_path.exists():
        try:
            return json.loads(cfg_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"[!] Error leyendo {cfg_path}: {e}", file=sys.stderr)
    return {}


def save_config(cfg: dict) -> Path:
    cfg_path = find_config_path()
    cfg_path.parent.mkdir(parents=True, exist_ok=True)
    cfg_path.write_text(json.dumps(cfg, indent=2, ensure_ascii=False), encoding="utf-8")
    gi_path = cfg_path.parent / ".gitignore"
    if not gi_path.exists():
        gi_path.write_text("# MultiAgente secret and temporary files protector\nma_config.json\n.env\n*.tmp\n__pycache__/\n*.pyc\n", encoding="utf-8")
    return cfg_path


def make_request(method: str, url: str, token: str, data: dict = None) -> dict:
    headers = {
        "Accept": "application/json",
        "User-Agent": "MultiAgente-Bridge/2.0"
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = None
    if data is not None:
        headers["Content-Type"] = "application/json"
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")

    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode("utf-8")
            if raw:
                try:
                    return json.loads(raw)
                except Exception:
                    return {"raw": raw}
            return {}
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8", errors="replace")
        print(f"[!] Error HTTP {e.code} en {url}: {err_msg}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"[!] Error de conexión en {url}: {e.reason}", file=sys.stderr)
        sys.exit(1)


def cmd_login(args):
    cfg = load_config()
    api_url = args.api_url or os.environ.get("MA_API_URL")
    if api_url:
        cfg["api_url"] = api_url.rstrip("/")
    token = args.token or os.environ.get("MA_SYNC_TOKEN")
    if token:
        cfg["sync_token"] = token
    project = getattr(args, "project", None) or os.environ.get("MA_PROJECT_CODE")
    if project:
        cfg["project_code"] = project
    issue = getattr(args, "issue", None) or os.environ.get("MA_ISSUE_KEY")
    if issue:
        cfg["issue_key"] = issue

    path = save_config(cfg)
    try:
        import subprocess
        subprocess.run(["git", "update-index", "--assume-unchanged", str(path)], capture_output=True)
    except Exception:
        pass
    print(f"[+] Configuración guardada exitosamente en {path}")
    print(f"    API URL : {cfg.get('api_url')}")
    print(f"    Proyecto: {cfg.get('project_code')}")
    print(f"    Issue   : {cfg.get('issue_key')}")


def cmd_complete_dev(args):
    cfg = load_config()
    api_url = (args.api_url or os.environ.get("MA_API_URL") or cfg.get("api_url") or "").rstrip("/")
    token = args.token or os.environ.get("MA_SYNC_TOKEN") or cfg.get("sync_token")
    issue = args.issue or os.environ.get("MA_ISSUE_KEY") or cfg.get("issue_key")

    if not api_url or not token or not issue:
        print("[!] Faltan parámetros requeridos: --api-url, --token o --issue (o configúralos en .env o login)", file=sys.stderr)
        sys.exit(1)

    dev_output_path = Path(".agentscontext") / issue / "3_DEV_OUTPUT.md"
    if not dev_output_path.exists():
        dev_output_path = Path(__file__).resolve().parent / issue / "3_DEV_OUTPUT.md"

    if not dev_output_path.exists():
        print(f"[!] No se encontró el archivo de entrega: {dev_output_path}", file=sys.stderr)
        sys.exit(1)

    dev_output = dev_output_path.read_text(encoding="utf-8")
    qa_task = None
    qa_task_path = dev_output_path.parent / "4_QA_TASK.md"
    if qa_task_path.exists():
        qa_task = qa_task_path.read_text(encoding="utf-8")

    payload = {
        "dev_output": dev_output,
        "qa_task": qa_task,
        "notes": f"Entregado vía CLI Bridge desde rama {cfg.get('branch', 'local')}"
    }

    url = f"{api_url}/api/v1/remote/initiatives/{issue}/complete-dev"
    print(f"[*] Enviando entrega de desarrollo para {issue} hacia {url}...")
    res = make_request("POST", url, token, payload)
    print(f"[+] Desarrollo registrado exitosamente:")
    print(f"    Estado: {res.get('current_state')}")
    print(f"    Responsable: {res.get('active_owner')}")


def cmd_submit_qa(args):
    cfg = load_config()
    api_url = (args.api_url or os.environ.get("MA_API_URL") or cfg.get("api_url") or "").rstrip("/")
    token = args.token or os.environ.get("MA_SYNC_TOKEN") or cfg.get("sync_token")
    issue = args.issue or os.environ.get("MA_ISSUE_KEY") or cfg.get("issue_key")

    if not api_url or not token or not issue:
        print("[!] Faltan parámetros requeridos: --api-url, --token o --issue (o configúralos en .env o login)", file=sys.stderr)
        sys.exit(1)

    qa_report_path = Path(".agentscontext") / issue / "4_QA_REPORT.json"
    if not qa_report_path.exists():
        qa_report_path = Path(__file__).resolve().parent / issue / "4_QA_REPORT.json"

    if not qa_report_path.exists():
        print(f"[!] No se encontró el reporte QA: {qa_report_path}", file=sys.stderr)
        sys.exit(1)

    try:
        report_data = json.loads(qa_report_path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[!] Error leyendo JSON de {qa_report_path}: {e}", file=sys.stderr)
        sys.exit(1)

    url = f"{api_url}/api/v1/remote/initiatives/{issue}/submit-qa"
    print(f"[*] Enviando reporte de QA para {issue} hacia {url}...")
    res = make_request("POST", url, token, report_data)
    print(f"[+] QA procesado exitosamente:")
    print(f"    Estado: {res.get('current_state')}")
    print(f"    QA Status: {res.get('qa_status')}")


def cmd_inject_lesson(args):
    cfg = load_config()
    api_url = (args.api_url or os.environ.get("MA_API_URL") or cfg.get("api_url") or "").rstrip("/")
    token = args.token or os.environ.get("MA_SYNC_TOKEN") or cfg.get("sync_token")
    project = args.project or os.environ.get("MA_PROJECT_CODE") or cfg.get("project_code")

    if not api_url or not token or not project:
        print("[!] Faltan parámetros requeridos: --api-url, --token o --project (o configúralos en .env o login)", file=sys.stderr)
        sys.exit(1)

    payload = {
        "lesson": args.lesson,
        "key": args.key or "tech_configs",
        "target": args.target or "project",
        "reason": args.reason or "Lección agregada vía CLI Bridge"
    }

    url = f"{api_url}/api/v1/remote/projects/{project}/lessons"
    print(f"[*] Inyectando lección aprendida en {project}...")
    res = make_request("POST", url, token, payload)
    print(f"[+] Lección inyectada con éxito: {res.get('message', 'OK')}")

    # Actualizar PROJECT_CONTEXT.md local si existe
    local_ctx = Path("PROJECT_CONTEXT.md")
    if not local_ctx.exists():
        local_ctx = Path(__file__).resolve().parent.parent / "PROJECT_CONTEXT.md"
    if local_ctx.exists():
        try:
            curr = local_ctx.read_text(encoding="utf-8")
            bullet = f"- [Lección {project}]: {args.lesson}"
            if args.lesson not in curr:
                local_ctx.write_text(curr.rstrip() + f"\n\n### Lecciones Aprendidas Recientes\n{bullet}\n", encoding="utf-8")
                print("    Actualizado localmente ./PROJECT_CONTEXT.md")
        except Exception:
            pass


def cmd_pull_context(args):
    cfg = load_config()
    api_url = (args.api_url or os.environ.get("MA_API_URL") or cfg.get("api_url") or "").rstrip("/")
    token = args.token or os.environ.get("MA_SYNC_TOKEN") or cfg.get("sync_token")
    issue = args.issue or os.environ.get("MA_ISSUE_KEY") or cfg.get("issue_key")

    if not api_url or not token or not issue:
        print("[!] Faltan parámetros requeridos: --api-url, --token o --issue (o configúralos en .env o login)", file=sys.stderr)
        sys.exit(1)

    url = f"{api_url}/api/v1/remote/initiatives/{issue}/context-pack"
    print(f"[*] Obteniendo paquete de contexto actualizado para {issue}...")
    res = make_request("GET", url, token)

    files = res.get("files", {})
    for rel_path, content in files.items():
        dest = Path(rel_path)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(content, encoding="utf-8")
        print(f"    Actualizado: {rel_path}")
    print(f"[+] {len(files)} archivos sincronizados exitosamente.")


def main():
    parser = argparse.ArgumentParser(description="MultiAgente Factory CLI Bridge")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Login
    p_login = subparsers.add_parser("login", help="Configura URL de API y credenciales")
    p_login.add_argument("--api-url", help="URL base de MultiAgente (ej: http://localhost:8000)")
    p_login.add_argument("--token", help="Token de sincronización (sync_token JWT)")
    p_login.add_argument("--project", help="Código del proyecto")
    p_login.add_argument("--issue", help="Clave de la iniciativa")

    # Complete Dev
    p_dev = subparsers.add_parser("complete-dev", help="Envía entrega de desarrollo")
    p_dev.add_argument("--api-url", help="Override de URL de API")
    p_dev.add_argument("--token", help="Override de token")
    p_dev.add_argument("--issue", help="Override de clave de iniciativa")

    # Submit QA
    p_qa = subparsers.add_parser("submit-qa", help="Envía reporte de QA")
    p_qa.add_argument("--api-url", help="Override de URL de API")
    p_qa.add_argument("--token", help="Override de token")
    p_qa.add_argument("--issue", help="Override de clave de iniciativa")

    # Inject Lesson
    p_lesson = subparsers.add_parser("inject-lesson", help="Registra lección aprendida")
    p_lesson.add_argument("--lesson", required=True, help="Texto de la lección aprendida")
    p_lesson.add_argument("--key", default="tech_configs", help="Sección destino en PROJECT_CONTEXT.md")
    p_lesson.add_argument("--target", default="project", choices=["project", "profile"], help="Ámbito de la lección")
    p_lesson.add_argument("--reason", default="", help="Motivo de la lección")
    p_lesson.add_argument("--api-url", help="Override de URL de API")
    p_lesson.add_argument("--token", help="Override de token")
    p_lesson.add_argument("--project", help="Override de código de proyecto")

    # Pull Context
    p_pull = subparsers.add_parser("pull-context", help="Descarga contexto actualizado")
    p_pull.add_argument("--api-url", help="Override de URL de API")
    p_pull.add_argument("--token", help="Override de token")
    p_pull.add_argument("--issue", help="Override de clave de iniciativa")

    args = parser.parse_args()
    if args.command == "login":
        cmd_login(args)
    elif args.command == "complete-dev":
        cmd_complete_dev(args)
    elif args.command == "submit-qa":
        cmd_submit_qa(args)
    elif args.command == "inject-lesson":
        cmd_inject_lesson(args)
    elif args.command == "pull-context":
        cmd_pull_context(args)


if __name__ == "__main__":
    main()
