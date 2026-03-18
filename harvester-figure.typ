// harvester-figure.typ — data-flow overview of the harvester tool

#import "@preview/cetz:0.3.4": canvas, draw

// ── colour palette ────────────────────────────────────────────────────────────

// Each source shape gets a distinct colour not used elsewhere in the figures
#let _src-styles = (
  (fill: rgb("#fce7f3"), stroke: 1pt + rgb("#ec4899")),  // circle   — rose
  (fill: rgb("#ffedd5"), stroke: 1pt + rgb("#f97316")),  // diamond  — orange
  (fill: rgb("#ccfbf1"), stroke: 1pt + rgb("#0d9488")),  // hexagon  — teal
  (fill: rgb("#e0e7ff"), stroke: 1pt + rgb("#4f46e5")),  // pentagon — indigo
)
#let _sfga-fill   = rgb("#fef3c7")
#let _sfga-stroke = 1pt   + rgb("#f59e0b")
#let _hv-fill     = rgb("#dcfce7")
#let _hv-stroke   = 1.5pt + rgb("#16a34a")

#let _arr = (end: ">", fill: black, size: 0.2)

// ── Typst-level box renderers ─────────────────────────────────────────────────

#let _sfga-box(label: [*SFGA*]) = rect(
  fill: _sfga-fill, stroke: _sfga-stroke,
  inset: (x: 8pt, y: 6pt), radius: 3pt,
)[#text(size: 11pt, label)]

#let _section(title) = text(size: 14pt, fill: luma(88), style: "italic", title)

// ── diagram ───────────────────────────────────────────────────────────────────

#let _harvester-diag = canvas(length: 0.9cm, {
  import draw: *

  let ys     = (2.15, 0.98, -0.2, -2.2)    // y positions of the 4 source shapes
  let hv-cx  = 3.4                        // centre of harvester rect
  let hv-hw  = 1.6
  let hv-hh  = 2.55                       // tall — spans full shape column
  let r      = 0.38                       // bounding radius for all shapes

  // ── source shapes (all neutral grey) ──────────────────────────────────────

  // 1. Circle — rose
  let c0 = _src-styles.at(0)
  circle((0, ys.at(0)), radius: r, fill: c0.fill, stroke: c0.stroke, name: "s0")

  // 2. Diamond — orange
  let c1 = _src-styles.at(1)
  let y1 = ys.at(1)
  line((0, y1 + r), (r*1.1, y1), (0, y1 - r), (-r*1.1, y1),
    close: true, fill: c1.fill, stroke: c1.stroke)

  // 3. Hexagon (pointy sides) — teal
  let c2 = _src-styles.at(2)
  let y2 = ys.at(2)
  let hx-pts = range(6).map(i => {
    let a = i * 60deg
    (r * calc.cos(a), y2 + r * calc.sin(a))
  })
  line(..hx-pts, close: true, fill: c2.fill, stroke: c2.stroke)

  // 4. Pentagon (one vertex pointing right) — indigo
  let c3 = _src-styles.at(3)
  let y3 = ys.at(3)
  let pn-pts = range(5).map(i => {
    let a = i * 72deg
    (r * calc.cos(a), y3 + r * calc.sin(a))
  })
  line(..pn-pts, close: true, fill: c3.fill, stroke: c3.stroke)

  // Ellipsis between 3rd and 4th shape
  content((0, (ys.at(2) + ys.at(3)) / 2.2), text(size: 14pt, […]))

  // ── individual arrows from each shape → harvester left edge ──────────────

  line((r,       ys.at(0)), (hv-cx - hv-hw, ys.at(0)), mark: _arr)
  line((r * 1.1, ys.at(1)), (hv-cx - hv-hw, ys.at(1)), mark: _arr)
  line((r,       ys.at(2)), (hv-cx - hv-hw, ys.at(2)), mark: _arr)
  line((r,       ys.at(3)), (hv-cx - hv-hw, ys.at(3)), mark: _arr)

  // ── harvester node ────────────────────────────────────────────────────────

  rect(
    (hv-cx - hv-hw, -hv-hh),
    (hv-cx + hv-hw,  hv-hh),
    fill: _hv-fill, stroke: _hv-stroke, radius: 0.15,
  )
  content((hv-cx, 0), text(size: 12pt, [*harvester get*]))

  // ── SFGA output ───────────────────────────────────────────────────────────

  content((hv-cx + hv-hw + 2.5, 0), _sfga-box(), name: "sfga")
  line((hv-cx + hv-hw, 0), "sfga.west", mark: _arr)
})

// ── exported figure content ───────────────────────────────────────────────────

#let harvester-figure = block(
  stroke: 0.5pt + luma(200),
  inset: 14pt,
  radius: 4pt,
  width: 100%,
)[
  #align(center, _harvester-diag)
]
