# SFBorg paper

## PDF generation

```bash
# PDF generation  on the fly
typst watch main.typ

# Ocasional PDF generation
typst compile main.typ
```

## Compiling images for import to Pensoft

```bash
typst compile sf-figure-standalone.typ sf-figure.png --ppi 300
typst compile gndb-figure-standalone.typ gndb-figure.png --ppi 300
typst compile harvester-figure-standalone.typ harvester-figure.png --ppi 300
```
