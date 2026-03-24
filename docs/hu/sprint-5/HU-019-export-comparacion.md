# HU-019: Export PDF/CSV + comparación de períodos

**Sprint**: 5 — Polish + Reports + Deploy (Semana 6)
**Track**: B (Frontend)
**Dependencias**: HU-008 (Overview), HU-013 (Channel panels)
**Consola sugerida**: Terminal 2 (Frontend)

---

## Descripción

Funcionalidad de export (CSV y PDF con branding) y panel de Reports con comparación de períodos (este mes vs anterior) mostrando deltas porcentuales.

## Criterios de aceptación

- [ ] Botón export CSV descarga tabla actual como .csv
- [ ] Botón export PDF genera report con branding del tenant
- [ ] Comparación de períodos: "este mes vs anterior" con deltas %

## Prompt para Claude Code

```
Lee CLAUDE.md.

1. Crea src/components/shared/ExportButton.tsx:
   - CSV: tomar data actual del hook, generar CSV string, trigger download con Blob + URL.createObjectURL
   - PDF: usar librería jsPDF + html2canvas. Capturar el panel actual como imagen, agregar header con logo del tenant + fecha. O alternativamente: generar HTML formateado y usar window.print() con @media print CSS.

2. Actualiza ReportsPanel con:
   - Date range picker con opción "Compare to previous period"
   - Cuando activado: ejecutar 2 queries (current period + previous period)
   - Mostrar delta % en cada KPI card (green up / red down)
   - Tabla comparativa: canal | current spend | prev spend | delta % | current conv | prev conv | delta %

3. Crea src/panels/ReportsPanel.tsx que compone todo lo anterior.
```

## Archivos a crear/modificar

- `src/components/shared/ExportButton.tsx`
- `src/components/panels/ReportsPanel.tsx`
- `src/pages/ReportsPage.tsx`

## Estimación

~3-4 horas con Claude Code
