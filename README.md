# ABIX Skills

Skills repository for ABIX Studio. Contains SAP knowledge bases organized by category.

## Structure

```
manifest.json          <- Master index (versions, plans, paths)
core/                  <- Core technologies (ABAP, CDS, SQLScript, CAP, AI)
functional/            <- Functional consulting (FI, MM, SD)
btp/                   <- BTP Platform services
ui/                    <- UI development (Fiori, SAPUI5)
data/                  <- Data & Analytics (Datasphere, SAC)
tooling/               <- Dev tools (MCP, Clean Core, HANA CLI)
```

## Skill format

Each skill is a directory containing:

```
skill-name/
  SKILL.md             <- Main skill content (injected into AI context)
  plugin.json          <- Metadata: name, version, keywords, category
  references/          <- Reference docs (selectively injected by keyword match)
    01-topic.md
    02-topic.md
```

## Plans

Skills are gated by license plan via `manifest.json`:

- `all` — Available to everyone (Trial, Personal, Professional)
- `personal` — Requires Personal or Professional plan
- `professional` — Requires Professional plan only
