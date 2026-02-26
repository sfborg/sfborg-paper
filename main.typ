#import "template/lib.typ": article, author-meta

#show: article.with(
  title: "SFBorg: a frictionless biodiversity data exchange.",
  authors: (
    "Dmitry Mozzherin": author-meta(
      "AFF1",
      email: "mozzheri@illinois.edu",
    ),
    "Geoffrey Ower": author-meta(
      "AFF2",
      email: "gdower@illinois.edu",
    ),
  ),
  affiliations: (
    "AFF1": "Department, Institution, City, Country",
    "AFF2": "Department, Institution, City, Country",
  ),
  abstract: [
    *Background:* Exchanging datasets is crucial for biodiversity researchers.
    Existing standard-based formats such as Darwin Core Archive (DwCA) for
    example, significantly simplify the exchange. However, until a receiver of
    the dataset imports it into a database the dataset cannot be used. The data
    usually contains multiple files in CSV, JSON, or XML formats compressed
    into one file and to query the data is very impractical. Moreover,
    the creation of dataset is often not trivial and error-prone. The resulting
    inconsistencies and errors on the client side create additional frictions
    and innacuracies during import.

    *New information:* We suggest a different approach to data exchange using
    SFBorg project as an example. SFBorg project provides a frictionless,
    "active" data exchange format that is not only easily queryable, but even
    can be used as a backend for an ecosystem of applications and tools for
    data manipulation and Visualization. SFBorg consists of a SQLite-based
    data schema, Species File Group Archive (SFGA), and a growing collection
    of software (universal formats converter `sf`, importer for non-standard
    datasets `harvester`, GNverifier database importer `gndb`). The functionlity
    of these tools in large part is located in a shared librarey `sflib` which
    removes duplication of code and simplifies creation new tools and
    maintenance of esiting ones. All the code OpenSource and is available
    on GitHub. Species File Group uses SFBorg to make interproject data exchange
    easier and to provide critial functionality for a variety of projects.
    We consider this experiment a success, and consider SQLite to be an
    amazing platform for archival and exchange of biodiversity data.
  ],
  keywords: (
    "biodiversity informatics",
    "checklist",
    "SQLite",
    "data format",
    "taxonomic data",
    "data conversion",
  ),
)


= Introduction

Explain the landscape of biodiversity checklist data and why a common archive format
is needed. Cover:

- The diversity of existing checklist formats (DwC-A, CoL Data Package, custom TSVs,
  legacy Species File databases, etc.) and their limitations for interchange
- The lack of tooling to detect and communicate *changes* between dataset versions
- Why SQLite is a suitable foundation for a portable, self-contained archive format
- The goals of the SFBorg project: a stable format spec, a shared library, and a
  suite of interoperable tools
- Brief overview of how the rest of the paper is structured

Cite relevant prior work: Darwin Core, Catalogue of Life, TaxonWorks, related tools.


= Project Description

Describe the SFBorg project as a whole, for a non-technical biodiversity audience:

- The core idea: SFGA as a portable, versioned, self-contained unit of checklist data
- Who the target users are (checklist curators, aggregators, data pipelines)
- What workflows the ecosystem enables: ingesting heterogeneous sources → normalising
  to SFGA → diffing versions → loading into downstream databases
- Institutional context: Species File Group, connection to gnverifier / GN projects
- Current status and funding (if applicable)


= Web Location (URIs)

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  [*Project homepage*],    [https://github.com/sfborg — or a dedicated site if available],
  [*SFGA format spec*],    [URL to format specification / schema documentation],
  [*SF (converter)*],      [https://github.com/sfborg/sf],
  [*harvester*],           [https://github.com/sfborg/harvester],
  [*gndb*],                [https://github.com/sfborg/gndb],
  [*sflib*],               [https://github.com/sfborg/sflib],
  [*Bug tracker*],         [https://github.com/sfborg — issues on each respective repo],
  [*Documentation*],       [URL to docs site or README links],
)


= Technical Specification

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  [*Programming language*], [Go (version X.Y)],
  [*Archive format*],       [SQLite 3],
  [*Interface*],            [Command-line interface (all tools); Go library (sflib)],
  [*Standards*],            [Darwin Core, Catalogue of Life Data Package, GBIF],
  [*Operating system*],     [Linux, macOS, Windows (cross-platform via Go)],
  [*Licence*],              [MIT License (or state the actual licence)],
  [*SFGA spec version*],    [e.g. v1.0],
  [*SF version*],           [e.g. v0.x.y],
  [*harvester version*],    [e.g. v0.x.y],
  [*gndb version*],         [e.g. v0.x.y],
  [*sflib version*],        [e.g. v0.x.y],
)


= Repository

Source code for all components is openly available:

#table(
  columns: (auto, 1fr, auto),
  stroke: 0.5pt,
  [*Component*], [*Repository*], [*Archived DOI*],
  [SFGA spec], [https://github.com/sfborg/sfga], [https://doi.org/10.5281/zenodo.XXXXXXX],
  [sflib],     [https://github.com/sfborg/sflib], [https://doi.org/10.5281/zenodo.XXXXXXX],
  [SF],        [https://github.com/sfborg/sf],    [https://doi.org/10.5281/zenodo.XXXXXXX],
  [harvester], [https://github.com/sfborg/harvester], [https://doi.org/10.5281/zenodo.XXXXXXX],
  [gndb],      [https://github.com/sfborg/gndb],  [https://doi.org/10.5281/zenodo.XXXXXXX],
)

Versioned releases are archived to Zenodo to ensure long-term availability and
citability. Each repository contains a `go.mod` file listing Go module dependencies.


= Usage Licence

All components of the SFBorg ecosystem are released under the MIT License. The full
license text is available in the `LICENSE` file in each repository. Any bundled
reference data or example datasets should state their license separately (e.g.
CC BY 4.0 if derived from Catalogue of Life or GBIF).


= Implementation

== SFGA Format

Describe the SFGA (Species File Group Archive) SQLite schema:

- Top-level design decisions: why SQLite, why a single-file archive
- Key tables and their relationships (taxa, names, references, distributions,
  vernacular names, metadata, etc.)
- Versioning and provenance fields built into the schema
- How SFGA compares to DwC-A or CoL Data Package structurally
- The format specification repository and any schema migration tooling

Include an entity-relationship diagram or a simplified schema table if helpful.

== sflib

Describe the shared Go library that underpins all tools:

- What functionality sflib encapsulates (SFGA read/write, normalisation,
  diff computation, name parsing integration, etc.)
- Why centralising logic in a library was chosen over per-tool implementations
- Public API surface (key interfaces/types exposed to tool authors)
- How to use sflib as a dependency in a Go project

== SF — Universal Converter and Differ

Describe the SF command-line tool:

- *Conversion:* supported input formats (DwC-A, CoL DP, TSV, legacy Species File
  databases, …) → SFGA output. How format detection works.
- *Diff calculation:* how SF computes semantic differences between two SFGA
  archives (added/modified/deleted taxa, names, synonyms, etc.)
- *Output formats:* what SF can export to (SFGA, CoL DP, plain TSV, …)
- Example invocations:

#raw(block: true, lang: "sh",
  "# Convert a Darwin Core Archive to SFGA\n" +
  "sf convert input.zip -o output.sfga\n\n" +
  "# Calculate diff between two versions\n" +
  "sf diff v1.sfga v2.sfga -o changes.tsv"
)

== harvester

Describe the harvester tool:

- What "non-standard" sources it targets (legacy formats, bespoke database dumps,
  sources that cannot be handled by the generic SF converter)
- How sources are defined or configured (config files, plugins, hardcoded adapters)
- The import pipeline: fetch → parse → normalise → write SFGA
- How to add support for a new source

== gndb

Describe the gndb tool:

- Its specific purpose: loading an SFGA archive into a PostgreSQL database schema
  used by gnverifier
- The target database schema (briefly) and how SFGA fields map to it
- Typical invocation:

#raw(block: true, lang: "sh",
  "gndb load dataset.sfga --db postgres://user:pass@localhost/gnverifier"
)

- How gndb fits into the broader gnverifier data pipeline


= Additional Information

== Dependencies

All tools are written in Go and manage dependencies via Go modules (`go.mod`).
Key shared dependencies across the ecosystem:

- *sflib* — internal shared library (all tools)
- List other major external Go packages used (e.g. for SQLite driver, name parsing,
  CLI framework), with links and brief roles

Tool-specific dependencies (e.g. gndb → PostgreSQL driver) should be noted per tool.

== Availability and Maintenance

State the current development status of each component (stable / beta / active
development). Describe the maintenance commitment and how the community can contribute
(pull requests, issue tracker, contribution guidelines).


= Acknowledgements

Acknowledge funding sources (grant numbers), the Species File Group, any data
providers whose datasets were used for testing, and contributors who do not qualify
as authors.


= Author Contributions

List each author's CRediT roles:

- *Author One:* Conceptualization, Software (sflib, SF, gndb), Writing – original draft
- *Author Two:* Methodology, Validation, Writing – review & editing

_(CRediT taxonomy: Conceptualization, Data curation, Formal analysis, Funding
acquisition, Investigation, Methodology, Project administration, Resources, Software,
Supervision, Validation, Visualization, Writing – original draft, Writing – review
& editing)_


#bibliography("./ref.bib")
