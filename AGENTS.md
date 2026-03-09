# SFBorg Paper — Agent Instructions

## Project Overview

Academic paper about SFBorg, a SQLite-based ecosystem for biodiversity dataset
exchange. Written in Typst (`main.typ`), targeting a biodiversity informatics
journal.

## File Structure

- `main.typ` — main paper content (Typst)
- `sfborg.bib` — bibliography (IEEE style via `ieee.csl`)
- `gnparser.bib` — gnparser-specific bibliography (currently unused)
- `ref.bib` — old bibliography (superseded by `sfborg.bib`)
- `template/` — Typst article template
- `main.pdf` — compiled output

## Build

```bash
# Watch mode (recompiles on save)
typst watch main.typ

# One-off compile
typst compile main.typ
```

## Paper Structure and Status

| Section              | Status                              |
|----------------------|-------------------------------------|
| Abstract             | Complete                            |
| Introduction         | Complete (written prose)            |
| Project Description  | Complete (written prose)            |
| Web Location (URIs)  | Complete (real GitHub URLs)         |
| Technical Spec       | Table present; versions are TBA     |
| Repository           | References Web Location table       |
| Usage Licence        | Complete                            |
| Implementation       | Outlines only — needs writing       |
| Additional Info      | Outlines only — needs writing       |
| Acknowledgements     | Placeholder — needs writing         |
| Author Contributions | Placeholder — needs writing         |

## Key Content

- **Project**: SFBorg — SQLite-based biodiversity data exchange ecosystem
- **Core format**: SFGA (Species File Group Archive) — single SQLite file
- **Components**:
  - `sflib` — shared Go library (SFGA read/write, diff, normalisation)
  - `sf` — universal converter (DwCA, CoLDP, CSV, name lists → SFGA) + differ
  - `harvester` — bespoke ingestion for non-standard/legacy sources
  - `gndb` — loads SFGA into GNverifier's PostgreSQL database
- **Language**: Go (modules via `go.mod`)
- **Licence**: MIT
- **Org**: Species File Group, Illinois Natural History Survey, U of Illinois
- **GitHub**: https://github.com/sfborg

## Relevant Applications

- https://github.com/sfborg/sfga
- https://github.com/sfborg/sflib
- https://github.com/sfborg/sf
- https://github.com/sfborg/harvester
- https://github.com/gnames/gndb

## Authors and Affiliations

Both authors are at AFF1 (University of Illinois, Champaign, USA):
- Dmitry Mozzherin — mozzheri@illinois.edu
- Geoffrey Ower

## Bibliography

Bibliography is in `sfborg.bib`, rendered with IEEE style (`ieee.csl`).
Key citations already present: gbif, itis, col, globalnames-web, ipni,
zoobank, tdwg, coldp, taxonworks, SQLite3LOC.
