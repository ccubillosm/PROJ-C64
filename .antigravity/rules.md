# Reglas de Ingeniería para Google Antigravity como Agente Desarrollador

## Principios de Actuación
1. **Apego Estricto al Plan:** Implementa exactamente lo especificado en `.agentscontext/COM-011/2B_IMPLEMENTATION_PLAN.md`. No agregues librerías no solicitadas ni alteres la arquitectura acordada.
2. **Contexto Permanente del Proyecto:** Consulta obligatoriamente `./PROJECT_CONTEXT.md` para acatar las reglas de negocio, manual de estilo UX/UI, stack tecnológico y directivas técnicas del proyecto antes de escribir código.
3. **Reutilización de UI:** Copia la estructura visual, tokens y clases CSS/HTML presentes en `.agentscontext/COM-011/UI_PROTOTYPE.html` si está disponible.
4. **Preservación Obligatoria de `data-testid`:** Todos los atributos `data-testid` definidos en la especificación UX/UI y el plan de arquitectura son sagrados. El Agente QA los usará para certificar tu trabajo.
5. **Ciclos de Retrabajo (`08_REWORK_DEV`):** Si recibes un reporte en `.agentscontext/COM-011/4_QA_REPORT.json`, enfócate quirúrgicamente en resolver los fallos y stacktraces identificados sin romper los escenarios que ya pasaron.
6. **Calidad y Verificación:** Valida que no queden errores de sintaxis, variables sin definir o scripts rotos antes de entregar el control al orquestador.

## Protocolo de Cierre (Modo Híbrido Multicanal)
Al finalizar la implementación de los requerimientos y verificar tus pruebas locales, registra tu entrega en `.agentscontext/COM-011/3_DEV_OUTPUT.md` y sincroniza mediante cualquiera de las 3 vías disponibles:
1. **Vía 1 (Puente CLI):**
   ```bash
   python .agentscontext/ma_bridge.py complete-dev --issue COM-011
   ```
2. **Vía 2 (Rama Git):**
   ```bash
   git add .
   git commit -m "feat(COM-011): desarrollo completado"
   git push origin feat/COM-011
   ```
3. **Vía 3 (Manual):** Carga manual de `.agentscontext/COM-011/3_DEV_OUTPUT.md` en el Estudio Web.
