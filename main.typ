#import "template/lib.typ": article, author-meta

#show: article.with( title: "SFBorg: a frictionless biodiversity data
  exchange.", authors: ( "Dmitry Mozzherin": author-meta( "AFF1", email:
    "mozzheri@illinois.edu",), "Geoffrey Ower": author-meta( "AFF1",),),
  affiliations: ( "AFF1": "University of Illinois, Champaign, USA",),

  abstract: [ *Background:* Sharing biodiversity datasets across projects and
  organisations depends on common exchange formats e.g., Darwin Core Archive
  (DwCA) or the Catalogue of Life Data Package (ColDP). These formats bundle
  multiple CSV, JSON, or XML files into a single compressed archive. While
  widely adopted, this approach has a fundamental limitation: the data is
  effectively inert until a recipient imports it into a database. Generatation
  of a dataset's archive is error-prone and introduced inconsistencies might
  create significant problems on the receiving end. Also, there is no standard
  mechanism to detect what has changed between two successive releases of the
  same dataset.

  *New information:* We introduce SFBorg, a SQLite-based ecosystem for
  biodiversity datasets exchange centred on the Species File Group Archive
  (SFGA) schema. An SFGA single file is a self-contained SQLite database,
  allowing recipients to query and modify data immediately using standard SQL
  tools — no import step required. The ecosystem includes: `sf`, a universal
  converter between DwCA, ColDP, and other formats, which also computes data
  diffs between two SFGA archives to identify added, modified, or removed taxa,
  names, and synonyms; `harvester`, for ingesting non-standard or legacy
  sources; and `gndb`, which loads SFGA archives directly into the GNverifier
  PostgreSQL database. Shared functionality is centralised in the `sflib`
  library, reducing duplication and lowering the cost of adding new tools.
  SFBorg is currently in production use across Species File Group projects. All
  code is open source and available on GitHub under the MIT licence. #v(1em) ],
  keywords: ( "biodiversity informatics", "checklist", "SQLite", "data format",
  "taxonomic data", "data conversion",),)
//#set cite(style: "pensoft") #show link: underline



= Introduction

Biodiversity projects routinely manage thousands, millions, or even billions of
records. The resulting datasets are commonly shared with researchers, organisations
such as the Global Biodiversity Information Facility (GBIF) @gbif and the
Integrated Taxonomic Information System (ITIS) @itis, checklist aggregators
such as the Catalogue of Life (CoL) @col and Global Names @globalnames-web,
and nomenclatural authorities such as the International Plant Names Index
(IPNI) @ipni and ZooBank @zoobank.

Standards developed under the auspices of Biodiversity Information Standards
(TDWG) @tdwg greatly simplify data exchange. Darwin Core Archive (DwCA) is the
workhorse format for supplying GBIF with checklist and occurrence data; openly
published DwCA archives allow anyone to ingest these datasets for a wide
variety of purposes. The Catalogue of Life Data Package (CoLDP) standard
@coldp, developed jointly by CoL and GBIF, enables taxonomists to contribute
their systematics work to CoL, helping to build a comprehensive list of all
known species on Earth.

Despite the advantages these standards offer, they are not without limitations.
A shared dataset is typically a compressed archive containing a collection of
XML, JSON, and CSV files. Such archives are effectively 'inert': their contents
cannot be queried or modified until they are imported into a database. The
creation of exchange archives is also error-prone. Providers must ensure that
all field names are correct, that every row contains the right number of items,
that delimiter characters in CSV files are properly escaped, and that all data
uses UTF-8 encoding. Importing a dataset involves several parsing steps, any of
which may fail or produce incorrect results when the archive contains
inconsistencies. Such errors must then be resolved by the recipient, and the
imported data may not faithfully represent the original. Furthermore, when a
dataset is released multiple times there is no standard mechanism to identify
what has changed between successive versions.

In this paper we propose a different approach: representing an exchange
standard as a SQLite database. SQLite is an exception to the general rule that
database files make poor archival targets. The SQLite binary format and
its SQL representation have been stable for more than twenty years and are
committed to remaining backward-compatible until at least the year 2050.
Because a database and its SQL backup each consist of a single file, sharing is
straightforward. The format is so well regarded that the United States Library
of Congress designates SQLite as an archival standard @SQLite3LOC, alongside
XML and JSON. SQLite is a high-performance, locally accessible database that
scales to terabytes, covering the vast majority of biodiversity datasets in
practice. It is supported by well-maintained libraries in every major
programming language, and it is pre-installed on virtually all modern computers
and mobile devices. A dataset delivered as a SQLite file is immediately
'active': recipients can query and modify it directly, without any import step.
A stable, schema-defined archive also enables a wide variety of applications to
use it directly as their database backend, and applications written in
different programming languages can interoperate through their respective
SQLite bindings. Because the schema defines all fields and controlled
vocabularies in advance, the risk of structural inconsistencies is
substantially reduced.

Species File Group (SFG) of the Illinois Natural History Survey at the
University of Illinois participates in three major biodiversity informatics
projects: TaxonWorks @taxonworks, a taxonomic workbench; the Catalogue of Life
@col, a builder of a comprehensive checklist of all known species; and Global
Names Architecture @globalnames-web, a suite of tools for scientific names.

We developed the SFBorg project to consolidate datasets from diverse sources
and to streamline data exchange among SFG projects. Rather than the
conventional XML, JSON, or CSV formats, SFBorg defines its exchange standard
as an SQLite schema. This design allows datasets to be explored and modified
via SQL without any prior import step, and supports a growing ecosystem of
applications that use SFGA archives directly as their database backend. The
SFBorg project comprises the SFGA SQLite schema, the `sflib` shared library
that encapsulates the functionality required to convert archives to and from
SFGA, and several applications that use an SFGA file as their primary database.

In this paper we describe the SFBorg project and its components: the SFGA
schema and its suite of SFGA-powered applications.

= Project Description

At the heart of SFBorg is the Species File Group Archive (SFGA): a single,
self-contained SQLite database file that serves simultaneously as the exchange
unit and as a live, queryable database. Unlike conventional archive formats
that bundle static CSV, JSON, or XML files, an SFGA file is immediately
accessible via any SQL client or SQLite-aware library — the dataset and its
query interface travel together. This design positions SFGA as a practical
answer to the limitations of inert archive formats: recipients can inspect,
filter, and transform a dataset the moment they receive it, without any
import pipeline.

The ecosystem around SFGA currently consists of four applications. The `sf`
tool is a universal converter: it reads biodiversity data from DwCA, CoLDP, CSV
files where fields are names according to DwCA or CoLDP terms, or simply from
lists of scientific names, normalises them into SFGA, and can re-export SFGA
files as all these formats. `sf` also computes semantic diffs between two SFGA
versions of data, identifying added, modified, and removed taxa, names, and
synonyms. The `harvester` tool handles sources that cannot be processed
generically by `sf` — non-standard or legacy datasets that require bespoke
parsing and normalisation logic. The `gndb` tool loads an SFGA archive directly
into the PostgreSQL database schema used by GNverifier, completing the pipeline
at the downstream end. All four tools are built on `sflib`, a shared Go library
that encapsulates core SFGA functionality and prevents duplication of
conversion, diff, and normalisation logic across the ecosystem. The overall
data flow is: _ingest_ (sf / harvester) → _normalise_ to SFGA → _diff_ (sf) →
_export or load_ (sf / gndb).

SFBorg is in active production use, though the SFGA schema is still maturing
and may undergo significant revision if limitations are encountered. The
Catalogue of Life uses `sf` and `harvester` to generate CoLDP archives for
their incorporation into the CoL global checklist. Global Names relies on
`gndb` as its sole mechanism for updating the taxonomic data in its GNverifier
PostgreSQL database. A third production workflow is under active development:
`sf` is being extended to convert flat taxonomic classifications — datasets
that list taxa without explicit identifiers or parent–child relationships —
into a proper Parent/Child hierarchy with generated identifiers. This
capability is intended to support the migration of taxonomist-curated datasets
into TaxonWorks, lowering the barrier for working taxonomists to contribute
their data to a managed workbench.

SFBorg was created by the Species File Group (SFG) at the Illinois Natural
History Survey, University of Illinois at Urbana-Champaign, to serve the
data-exchange needs of its three main projects: TaxonWorks, Catalogue of Life,
and Global Names. All components of the ecosystem are released under the MIT
licence and hosted on GitHub; contributions from the broader
community are welcome.

Looking ahead, the SFBorg team sees SFGA not merely as a pipeline format but
as a stable platform for a broader class of tools — analogous to the role that
stable document formats play in enabling diverse editors, viewers, and
collaboration workflows. A normalised, SQL-queryable schema for biodiversity
data could support a universal taxonomic editor, where any SFGA-aware
application can open any checklist file without server setup; a web-based
viewer that makes a taxonomist's life work publicly accessible the moment data
are converted; diff-based peer review, where reviewers annotate semantic
changes between two SFGA versions much as tracked changes work in a word
processor; offline field tools that carry a working checklist on a tablet and
synchronise changes back via the existing diff mechanism; direct data
publication as citable packages on repositories such as Zenodo or Dryad; and
AI-assisted workflows, where the SQL interface allows natural-language queries
over a checklist without custom integration. These directions are under active
discussion within the Species File Group.


= Web Location (URIs)

#figure(
  placement: none,
  caption: [Web locations of SFBorg components.],
  table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    [*SFBorg*],               [https://github.com/sfborg],
    [*SFGA schema*],          [https://github.com/sfborg/sfga],
    [*SFlib*],                [https://github.com/sfborg/sflib],
    [*SF (converter)*],       [https://github.com/sfborg/sf],
    [*Harvester*],            [https://github.com/sfborg/harvester],
    [*GNdb*],                 [https://github.com/sfborg/gndb],
  )
) <web-locations>


= Technical Specification

#figure(
  placement: none,
  caption: [SFBorg project specifications],
  table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    [*Programming language*], [Go (version TBA)],
    [*Archive format*],       [SQLite 3],
    [*Interface*],            [Command-line interface (all tools); Go library (sflib)],
    [*Standards*],            [Darwin Core, Catalogue of Life Data Package],
    [*Operating system*],     [Linux, macOS, Windows (cross-platform via Go)],
    [*Licence*],              [MIT License],
    [*SFGA schema version*],  [TBA],
    [*SF version*],           [TBA],
    [*harvester version*],    [TBA],
    [*gndb version*],         [TBA],
    [*sflib version*],        [TBA],
  )
) <specifications>

= Repository

Source code for all components is openly available as shown in @web-locations.
Versioned releases are archived to Zenodo to ensure long-term availability and
citability. Each repository contains a `go.mod` file listing Go module
dependencies.

= Usage Licence

All components of the SFBorg ecosystem are released under the MIT License. The
full license text is available in the `LICENSE` file in each repository. 

= Implementation

The SFBorg implementation consists of two layers: the SFGA SQLite schema,
which defines the exchange format, and a suite of applications — `SFlib`,
`SF`, `Harvester`, and `GNdb` — that produce, consume, and transform SFGA
archives.

== SFGA Format

The Species File Group Archive (SFGA) defines a SQLite schema for
biodiversity taxonomic and nomenclatural data. The schema by itself is
already functional albeit empty SQLite database. Our goal was to make the
schema compatible with CoLDP, DwCA, and stand-alone Darwin Core terms used
in 'flat' CSV file. We decided to use CoLDP as a starting point, as it is
the closest to a relational database sandard. The schema is already augmented
with significant number of fields created to accomodate needs of Species
File Group and will continue to evolve by breaking backward compatibility
if necessary, until we feel it reaches stable v1.0.0 stage.

The schema is published as a SQLite dump file and its tables currently
follow CoLDP design closely. The following tables exist in v0.4.2

// TODO: LIST OF tables without enums

Tables' collumns start by namespace following with the semantic meaning
of the column.

// TODO: Table that describes the namespaces. TW, SF and GN doe not exist yet
// lets assume these terms go to 'https://terms.sfg.org'.

Controlled vocabularies are implemented as tables with hardcoded values and
currently mostly follow controlled vocabularies of CoLDP.

// TODO: add an example of controlled vocabulary. 

// TODO: explain semantic versioning, and what current version v0.4.2 implies.

The purpose of the schema is to provide accurate and looseless migration of data between
three out main projects: TaxonWorks, the CoL, and GN. TaxonWorks is the most
challenging, because it is based on rich ontologies.

The schema continues to evolve rapidly according to current day to day tasks
and is already used in production in applications described further.

// TODO: emphasize benefits of the schema compare to traditional formats?


== SFlib

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

#bibliography("./sfborg.bib", style: "ieee.csl")

