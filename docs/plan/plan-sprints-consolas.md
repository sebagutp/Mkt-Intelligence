# MIH — Plan de Sprints y Consolas Paralelas

> Guía operativa para ejecutar las 21 HUs en 6 semanas usando 3 consolas de Claude Code en paralelo.

---

## Resumen ejecutivo

| Sprint | Semana | Objetivo | HUs |
|--------|--------|----------|-----|
| 0 | 1 | Scaffold + Infra Base | HU-001, HU-002, HU-003 |
| 1 | 2 | Primer Pipeline E2E (GA4 + Google Ads → BQ → Dashboard) | HU-004, HU-005, HU-006, HU-007, HU-008 |
| 2 | 3 | Canales restantes + Drill-downs | HU-009, HU-010, HU-011, HU-012, HU-013 |
| 3 | 4 | Intelligence (Anomalías, Alertas, Pacing) | HU-014, HU-015, HU-016 |
| 4 | 5 | White-label + Multi-tenant + Provisioning | HU-017, HU-018 |
| 5 | 6 | Polish, Reports, Deploy producción | HU-019, HU-020, HU-021 |

---

## Consolas de trabajo

Se utilizan **3 consolas de Claude Code** que trabajan en paralelo, cada una especializada en un track:

| Consola | Track | Especialización | Skill a cargar |
|---------|-------|-----------------|----------------|
| **Terminal 1** | A — Backend/ETL | Edge Functions, conectores, BigQuery proxy, alertas | `SKILL-track-a-backend-etl.md` |
| **Terminal 2** | B — Frontend | React SPA, componentes, hooks, paneles, charts | `SKILL-track-b-frontend.md` |
| **Terminal 3** | C — Infra/DevOps | Schemas, migrations, provisioning, deploy | `SKILL-track-c-infra-devops.md` |

### Cómo iniciar cada consola

Al abrir cada terminal de Claude Code, ejecutar primero:

```
Lee CLAUDE.md y el skill correspondiente en skills/SKILL-track-{a|b|c}-*.md.
Sigue las reglas del skill durante todo el desarrollo de este track.
```

---

## Diagrama de dependencias

```
Sprint 0 (Semana 1)
┌──────────────────┐   ┌──────────────────┐
│  HU-001 [T3]     │   │  HU-002 [T3]     │
│  Scaffold        │   │  BQ + Supabase   │
└────────┬─────────┘   └────────┬─────────┘
         │                      │
         ▼                      │
┌──────────────────┐            │
│  HU-003 [T2]     │            │
│  Auth + Layout   │            │
└────────┬─────────┘            │
         │                      │
Sprint 1 (Semana 2)             │
         │                      ▼
         │              ┌──────────────────┐
         │              │  HU-004 [T1]     │
         │              │  Shared ETL      │
         │              └────────┬─────────┘
         │                       │
         │              ┌────────┼────────┐
         │              ▼        ▼        ▼
         │       ┌──────────┐ ┌──────┐ ┌──────────┐
         │       │HU-005[T1]│ │HU-006│ │HU-007[T1]│
         │       │Google Ads│ │ GA4  │ │BQ Proxy  │
         │       └──────────┘ └──────┘ └────┬─────┘
         │                                  │
         ▼──────────────────────────────────▼
┌──────────────────┐
│  HU-008 [T2]     │
│  Panel Overview  │
└────────┬─────────┘
         │
Sprint 2 (Semana 3)
         │
┌────────┼──────────────────────────────┐
▼        ▼        ▼        ▼            │
HU-009   HU-010   HU-011   HU-012      │
Meta     Email    LinkedIn  Orchestr.   │
[T1]     [T1]     [T1]     [T1]        │
                                        ▼
                              ┌──────────────────┐
                              │  HU-013 [T2]     │
                              │  Drill-down      │
                              └────────┬─────────┘
                                       │
Sprint 3 (Semana 4)                    │
┌──────────────────┐  ┌──────────┐     │
│  HU-014 [T2]     │  │HU-015[T1]│     │
│  Anomalías       │  │Alertas   │     │
└──────────────────┘  └──────────┘     │
┌──────────────────┐                   │
│  HU-016 [T2]     │◄─────────────────┘
│  Sync Status     │
└──────────────────┘

Sprint 4 (Semana 5)
┌──────────────────┐  ┌──────────────────┐
│  HU-017 [T3]     │  │  HU-018 [T2]     │
│  Provisioning    │  │  Branding        │
└──────────────────┘  └──────────────────┘

Sprint 5 (Semana 6)
┌──────────────────┐  ┌──────────┐  ┌──────────────────┐
│  HU-019 [T2]     │  │HU-020[T1]│  │  HU-021 [T3]     │
│  Export/Reports  │  │Token Ref. │  │  Deploy Prod     │
└──────────────────┘  └──────────┘  └──────────────────┘
```

---

## Plan día a día

### SPRINT 0 — Semana 1: Scaffold + Infra Base

#### Día 1 (Lunes)

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 3 | **HU-001** | Scaffold completo del monorepo | 2-3h |
| Terminal 3 | **HU-002** | Migrations Supabase + Schemas BigQuery + Queries | 2-3h |

> HU-001 y HU-002 se ejecutan en serie en la misma terminal (infra). No hay dependencia entre ellas pero comparten contexto.

#### Día 2 (Martes)

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 2 | **HU-003** | Auth, TenantProvider, Layout, Sidebar, Login, Router | 3-4h |

> Requiere que HU-001 esté terminada (scaffold existe).

**Fin Sprint 0**: Dashboard vacío que carga, se autentica, y muestra skeleton.

---

### SPRINT 1 — Semana 2: Primer Pipeline E2E

#### Día 3 (Miércoles)

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 1 | **HU-004** | Shared ETL: BigQuery client, ConnectorBase, types, credential manager | 3-4h |

> Fundamento de todos los conectores. Debe completarse antes de HU-005/006/007.

#### Día 4 (Jueves) — **PARALELO**

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 1 | **HU-005** | Conector Google Ads | 2-3h |
| Terminal 1 | **HU-006** | Conector GA4 (en serie tras HU-005) | 2-3h |
| Terminal 2 | **HU-008** | Panel Overview (KPIs, charts, tabla) — puede desarrollarse con mock data | 4-5h |

#### Día 5 (Viernes)

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 1 | **HU-007** | BQ Query Proxy | 2-3h |
| Terminal 2 | **HU-008** | (continuación) Conectar Overview a data real via proxy | 1-2h |

**Fin Sprint 1**: Data real de GA4 + Google Ads visible en el dashboard.

---

### SPRINT 2 — Semana 3: Canales Restantes

#### Día 6-7 (Lunes-Martes) — **PARALELO**

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 1 | **HU-009** | Conector Meta Ads | 2-3h |
| Terminal 1 | **HU-010** | Conector Email multi-provider (en serie) | 3-4h |
| Terminal 2 | **HU-013** | Paneles drill-down por canal (puede avanzar con canales existentes) | 4-5h |

#### Día 8 (Miércoles) — **PARALELO**

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 1 | **HU-011** | Conector LinkedIn | 2-3h |
| Terminal 1 | **HU-012** | Orchestrator + Cron (en serie) | 2-3h |
| Terminal 2 | **HU-013** | (continuación) Completar drill-downs para todos los canales | 2h |

**Fin Sprint 2**: Los 5 canales conectados con data fluyendo. Drill-downs funcionando.

---

### SPRINT 3 — Semana 4: Intelligence

#### Día 9-10 (Jueves-Viernes) — **PARALELO**

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 1 | **HU-015** | Sistema de alertas (alert-dispatcher) | 2-3h |
| Terminal 2 | **HU-014** | Panel de anomalías y oportunidades | 3-4h |
| Terminal 2 | **HU-016** | Sync status + manual refresh (en serie tras HU-014) | 2-3h |

**Fin Sprint 3**: Dashboard detecta problemas y sugiere acciones. Alertas a Slack/email.

---

### SPRINT 4 — Semana 5: White-label + Multi-tenant

#### Día 11-12 (Lunes-Martes) — **PARALELO**

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 3 | **HU-017** | Provisioning scripts automatizados | 3-4h |
| Terminal 2 | **HU-018** | Settings de branding con preview live | 2-3h |

**Fin Sprint 4**: Sistema funciona para múltiples clientes. Onboarding automatizado.

---

### SPRINT 5 — Semana 6: Polish + Reports + Deploy

#### Día 13 (Miércoles) — **PARALELO**

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 1 | **HU-020** | Token refresh + health checks | 2-3h |
| Terminal 2 | **HU-019** | Export PDF/CSV + comparación de períodos | 3-4h |

#### Día 14 (Jueves)

| Consola | HU | Qué hacer | Duración est. |
|---------|-----|-----------|---------------|
| Terminal 3 | **HU-021** | Deploy producción Datawalt | 2-3h |

**Fin Sprint 5**: Producto en producción. Datawalt como primer cliente live.

---

## Resumen de carga por consola

| Consola | Total HUs | Horas estimadas |
|---------|-----------|-----------------|
| Terminal 1 (Backend) | 10 HUs (004-007, 009-012, 015, 020) | ~25-33h |
| Terminal 2 (Frontend) | 8 HUs (003, 008, 013, 014, 016, 018, 019) | ~23-31h |
| Terminal 3 (Infra) | 3 HUs (001, 002, 017, 021) | ~9-13h |

> Terminal 3 queda libre la mayor parte del tiempo. Se puede usar como terminal auxiliar para debugging, testing manual, o ejecutar HUs de backend cuando Terminal 1 está ocupada.

---

## Reglas operativas

1. **Antes de cada HU**: leer el archivo individual en `hu/sprint-X/HU-XXX-*.md` que contiene el prompt completo.
2. **Cargar skill del track**: al inicio de cada sesión, leer el skill correspondiente.
3. **Leer CLAUDE.md siempre**: es la fuente de verdad de la arquitectura.
4. **No adelantar sprints**: las dependencias son reales. Si el proxy (HU-007) no existe, el frontend (HU-008) no puede conectarse a data real.
5. **Mock data para frontend**: Terminal 2 puede avanzar con mock data mientras Terminal 1 construye los conectores. Luego conectar.
6. **Commits frecuentes**: al terminar cada HU, hacer commit con mensaje `feat(track-X): HU-XXX - descripción`.
