// gndb-figure.typ — data-flow overview of the gndb tool

#import "@preview/cetz:0.3.4": canvas, draw

// ── colour palette ────────────────────────────────────────────────────────────

#let _sfga-fill   = rgb("#fef3c7")
#let _sfga-stroke = 1pt   + rgb("#f59e0b")
#let _gndb-fill   = rgb("#dcfce7")
#let _gndb-stroke = 1.5pt + rgb("#16a34a")
#let _pg-fill     = rgb("#dbeafe")
#let _pg-stroke   = 1pt   + rgb("#2563eb")
#let _gn-fill     = rgb("#dcfce7")
#let _gn-stroke   = 1.5pt + rgb("#16a34a")

#let _arr = (end: ">", fill: black, size: 0.2)

// ── Typst-level box renderers ─────────────────────────────────────────────────

#let _sfga-box(label: [*SFGA*]) = rect(
  fill: _sfga-fill, stroke: _sfga-stroke,
  inset: (x: 8pt, y: 6pt), radius: 3pt,
)[#text(size: 11pt, label)]

#let _gndb-box = rect(
  fill: _gndb-fill, stroke: _gndb-stroke,
  inset: (x: 8pt, y: 10pt), radius: 3pt,
)[#text(size: 12pt, [*gndb populate*])]

#let _pg-box(label) = rect(
  fill: _pg-fill, stroke: _pg-stroke,
  inset: (x: 8pt, y: 6pt), radius: 3pt,
)[#text(size: 11pt, label)]

#let _gn-box = rect(
  fill: _gn-fill, stroke: _gn-stroke,
  inset: (x: 8pt, y: 6pt), radius: 3pt,
)[#text(size: 11pt, [*GNverifier*])]

// ── diagram ───────────────────────────────────────────────────────────────────

#let _gndb-diag = canvas(length: 0.9cm, {
  import draw: *

  let ys     = (2.2, 1.0, -0.2, -2.2)
  let gn-cx  = 3.4
  let gn-hw  = 1.7
  let gn-hh  = 2.55

  // 4 SFGA input boxes
  for i in range(ys.len()) {
    content((-1.0, ys.at(i)), _sfga-box(), name: "s" + str(i))
  }

  // Ellipsis above last SFGA
  content((-1, (ys.at(2) + ys.at(3)) / 2.2), text(size: 14pt, […]))

  // Individual arrows from each SFGA → gndb left edge
  for i in range(ys.len()) {
    line("s" + str(i) + ".east", (gn-cx - gn-hw, ys.at(i)), mark: _arr)
  }

  // gndb populate — tall rect
  rect(
    (gn-cx - gn-hw, -gn-hh),
    (gn-cx + gn-hw,  gn-hh),
    fill: _gndb-fill, stroke: _gndb-stroke, radius: 0.15,
  )
  content((gn-cx, 0), text(size: 12pt, [*gndb populate*]))

  // gnames PostgreSQL output
  content((gn-cx + gn-hw + 3.2, 0), _pg-box([*gnames*\ (PostgreSQL)]), name: "pg")
  line((gn-cx + gn-hw, 0), "pg.west", mark: _arr)

  // GNverifier above gnames — dashed arrow pointing down
  content((gn-cx + gn-hw + 3.2, 2.2), _gn-box, name: "gn")
  line("gn.south", "pg.north",
    mark: (end: ">", fill: black, size: 0.2),
    stroke: (dash: "dashed"),
  )
  content((gn-cx + gn-hw + 3.7, 1.3), text(size: 8pt, style: "italic", [uses]))
})

// ── exported figure content ───────────────────────────────────────────────────

#let gndb-figure = block(
  stroke: 0.5pt + luma(200),
  inset: 14pt,
  radius: 4pt,
  width: 100%,
)[
  #align(center, _gndb-diag)
]
