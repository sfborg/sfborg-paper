// sf-figure.typ — data-flow overview of the sf tool

#import "@preview/cetz:0.3.4": canvas, draw

// ── colour palette ────────────────────────────────────────────────────────────

#let _fmt-fill    = rgb("#dbeafe")
#let _fmt-stroke  = 0.5pt + rgb("#60a5fa")
#let _sfga-fill   = rgb("#fef3c7")
#let _sfga-stroke = 1pt   + rgb("#f59e0b")
#let _sf-fill     = rgb("#dcfce7")
#let _sf-stroke   = 1.5pt + rgb("#16a34a")
#let _arr         = (end: ">", fill: black, size: 0.2)

#let _fmts = ("DwCA", "CoLDP", "CSV/TSV", "sci. names")
#let _ys   = (1.5, 0.5, -0.5, -1.5)

#let _section(title) = text(size: 14pt, fill: luma(88), style: "italic", title)

// Typst-level box renderers — guaranteed rounded corners
#let _fmt-box(name) = rect(
  fill: _fmt-fill, stroke: _fmt-stroke,
  inset: (x: 6pt, y: 4pt), radius: 3pt,
)[#box(width: 53pt, align(center, raw(name)))]

#let _sfga-box(label: [*SFGA*]) = rect(
  fill: _sfga-fill, stroke: _sfga-stroke,
  inset: (x: 8pt, y: 6pt), radius: 3pt,
)[#text(size: 8pt, label)]

// ── section 1a: sf from (fan-in, tall sf node) ───────────────────────────────

#let _from-diag = canvas(length: 0.9cm, {
  import draw: *

  // Input format nodes
  for i in range(_fmts.len()) {
    content((0, _ys.at(i)), _fmt-box(_fmts.at(i)), name: "f" + str(i))
  }

  // sf ▸ from node drawn as an explicit tall rect
  let sf-cx = 3.2
  let sf-hw = 0.98   // half-width
  let sf-hh = 1.7    // half-height
  rect(
    (sf-cx - sf-hw, -sf-hh),
    (sf-cx + sf-hw,  sf-hh),
    fill: _sf-fill, stroke: _sf-stroke, radius: 0.15,
  )
  content((sf-cx, 0), text(size: 12pt, [*sf from*]))

  // SFGA output node
  content((sf-cx + sf-hw + 1.6, 0), _sfga-box(), name: "sfga")

  // Fan-in arrows from format nodes → sf left edge (evenly spaced)
  for i in range(_fmts.len()) {
    line("f" + str(i) + ".east", (sf-cx - sf-hw, _ys.at(i)), mark: _arr)
  }

  // Single arrow: sf right edge (centred) → SFGA
  line((sf-cx + sf-hw, 0), "sfga.west", mark: _arr)
})

// ── section 1b: sf to (fan-out, tall sf node) ────────────────────────────────

#let _to-diag = canvas(length: 0.9cm, {
  import draw: *

  // SFGA input node
  content((-0.5, 0), _sfga-box(), name: "sfga")

  // sf ▸ to node drawn as an explicit tall rect so we control its edges
  let sf-cx = 2
  let sf-hw = 0.98   // half-width
  let sf-hh = 1.7    // half-height — spans the full format-column range
  rect(
    (sf-cx - sf-hw, -sf-hh),
    (sf-cx + sf-hw,  sf-hh),
    fill: _sf-fill, stroke: _sf-stroke, radius: 0.15,
  )
  content((sf-cx, 0), text(size: 12pt, [*sf to*]))

  // Output format nodes
  let fmt-x = sf-cx + sf-hw + 2.3
  for i in range(_fmts.len()) {
    content((fmt-x, _ys.at(i)), _fmt-box(_fmts.at(i)), name: "f" + str(i))
  }

  // Single arrow: SFGA → sf left edge (centred)
  line("sfga.east", (sf-cx - sf-hw, 0), mark: _arr)

  // Fan-out arrows from sf right edge (evenly spaced) → format nodes
  for i in range(_fmts.len()) {
    line((sf-cx + sf-hw, _ys.at(i)), "f" + str(i) + ".west", mark: _arr)
  }
})

// ── section 2: sf diff (fan-in with bracket merge) ───────────────────────────

#let _diff-diag = canvas(length: 0.9cm, {
  import draw: *

  let v-y    = 0.8   // y of SFGA v1 (v2 is mirrored)
  let mrg-x  = 2.2   // x of the vertical merge bar
  let sf-cx  = 3.8   // centre of sf diff rect
  let sf-hw  = 0.9
  let sf-hh  = 0.45

  // Input nodes
  content((0,  v-y), _sfga-box(label: [*SFGA v1*]), name: "v1")
  content((0, -v-y), _sfga-box(label: [*SFGA v2*]), name: "v2")

  // Bracket: two horizontals + one vertical
  line("v1.east", (mrg-x,  v-y))
  line("v2.east", (mrg-x, -v-y))
  line((mrg-x,  v-y), (mrg-x, -v-y))

  // Single arrow from merge midpoint → sf diff
  line((mrg-x, 0), (sf-cx - sf-hw, 0), mark: _arr)

  // sf diff rect + label
  rect(
    (sf-cx - sf-hw, -sf-hh),
    (sf-cx + sf-hw,  sf-hh),
    fill: _sf-fill, stroke: _sf-stroke, radius: 0.15,
  )
  content((sf-cx, 0), text(size: 12pt, [*sf diff*]))

  // Output node
  content((sf-cx + sf-hw + 1.8, 0), _sfga-box(label: [*SFGA diff*]), name: "out")
  line((sf-cx + sf-hw, 0), "out.west", mark: _arr)
})

// ── section 3: sf update (linear chain) ──────────────────────────────────────

#let _update-diag = canvas(length: 0.9cm, {
  import draw: *

  let sf-cx = 3.0
  let sf-hw = 1.2
  let sf-hh = 0.45

  content((0, 0), _sfga-box(label: [*SFGA (old)*]), name: "old")

  line("old.east", (sf-cx - sf-hw, 0), mark: _arr)

  rect(
    (sf-cx - sf-hw, -sf-hh),
    (sf-cx + sf-hw,  sf-hh),
    fill: _sf-fill, stroke: _sf-stroke, radius: 0.15,
  )
  content((sf-cx, 0), text(size: 12pt, [*sf update*]))

  content((sf-cx + sf-hw + 2.0, 0), _sfga-box(label: [*SFGA (current)*]), name: "new")
  line((sf-cx + sf-hw, 0), "new.west", mark: _arr)
})

// ── non-cetz chips for the simpler sections ───────────────────────────────────

#let _sfga(label: [*SFGA*]) = box(
  fill: _sfga-fill, stroke: _sfga-stroke,
  inset: (x: 7pt, y: 4pt), radius: 3pt,
  text(size: 8pt, label),
)

#let _sf-chip(cmd) = box(
  fill: _sf-fill, stroke: _sf-stroke,
  inset: (x: 8pt, y: 6pt), radius: 4pt,
  text(size: 8pt, [*sf* #sym.triangle.r #raw(cmd)]),
)

#let _arr-inline = [#h(6pt)#sym.arrow.r#h(6pt)]
#let _plus       = [#h(5pt)+#h(5pt)]


// ── exported figure content ───────────────────────────────────────────────────

#let sf-figure = block(
  stroke: 0.5pt + luma(200),
  inset: 14pt,
  radius: 4pt,
  width: 100%,
)[
  #_section[A) Format conversion]
  #v(6pt)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 14pt,
    align: center + horizon,
    _from-diag,
    _to-diag,
  )

  #v(10pt)
  #line(length: 100%, stroke: 0.5pt + luma(200))
  #v(8pt)
  #_section[B) Semantic diff]
  #v(5pt)

  #align(center, _diff-diag)

  #v(10pt)
  #line(length: 100%, stroke: 0.5pt + luma(200))
  #v(8pt)
  #_section[C) Schema migration]
  #v(5pt)

  #align(center, _update-diag)
]
