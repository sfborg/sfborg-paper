#import "template/lib.typ": article, author-meta
#import "sf-figure.typ": sf-figure
#import "harvester-figure.typ": harvester-figure
#import "gndb-figure.typ": gndb-figure

#show: article.with(
  title: "SFBorg: a frictionless biodiversity data
  exchange.",
  authors: (
    "Dmitry Mozzherin": author-meta("AFF1", email: "mozzheri@illinois.edu"),
    "Geoffrey Ower": author-meta("AFF1"),
  ),
  affiliations: ("AFF1": "University of Illinois, Champaign, USA"),

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
  keywords: (
    "biodiversity informatics",
    "checklist",
    "SQLite",
    "data format",
    "taxonomic data",
    "data conversion",
  ),
)
//#set cite(style: "pensoft") #show link: underline



= Introduction

Biodiversity projects routinely manage thousands, millions, or even billions of
records. The resulting datasets are commonly shared with researchers,
organisations such as the Global Biodiversity Information Facility (GBIF) @gbif
and the Integrated Taxonomic Information System (ITIS) @itis, checklist
aggregators such as the Catalogue of Life (CoL) @col and Global Names
@globalnames-web, and nomenclatural authorities such as the International Plant
Names Index (IPNI) @ipni and ZooBank @zoobank.

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
    [*SFBorg*], [https://github.com/sfborg],
    [*SFGA schema*], [https://github.com/sfborg/sfga],
    [*SFlib*], [https://github.com/sfborg/sflib],
    [*SF (converter)*], [https://github.com/sfborg/sf],
    [*Harvester*], [https://github.com/sfborg/harvester],
    [*GNdb*], [https://github.com/sfborg/gndb],
  ),
) <web-locations>


= Technical Specification

#figure(
  placement: none,
  caption: [SFBorg project specifications],
  table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    [*Programming language*], [Go (version TBA)],
    [*Archive format*], [SQLite 3],
    [*Interface*], [Command-line interface (all tools); Go library (sflib)],
    [*Standards*], [Darwin Core, Catalogue of Life Data Package],
    [*Operating system*], [Linux, macOS, Windows (cross-platform via Go)],
    [*Licence*], [MIT License],
    [*SFGA schema version*], [TBA],
    [*SF version*], [TBA],
    [*harvester version*], [TBA],
    [*gndb version*], [TBA],
    [*sflib version*], [TBA],
  ),
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


In contrast with traditional checklists that require transfer to a database to
be useful, an SFGA file _is_ the database — recipients can open it in any SQL
client, run queries, and modify records the moment they receive it, with no
import step and no risk of parsing errors.

=== Schema design

SFGA is a SQLite schema for biodiversity taxonomic and nomenclatural data,
published as `schema.sql`, a plain-text SQL dump @mozzherin_ower_2026_sfga. We
chose CoLDP as the starting point because its entity model is the closest
existing standard to a normalised relational design. Every CoLDP field is
present in SFGA and carries the same semantics, so a round-trip conversion
between the two formats is lossless for CoLDP-conformant data. The schema
extends CoLDP with fields required for lossless migration among the two SFG
projects: the Catalogue of Life, and Global Names.TaxonWorks, which models taxa
through rich ontologies, will require additional changes to the schema.

SFGA follows semantic versioning. The current release is v0.4.2. The leading
zero signals that the schema is still maturing: any minor-version increment
(e.g. v0.4 → v0.5) may introduce breaking changes. Once the schema has
stabilised across all production workflows it will be released as v1.0.0,
after which backward compatibility will be maintained.

=== Data tables

Version v0.4.2 contains the following data tables (controlled-vocabulary
tables are listed separately below):

#figure(
  placement: none,
  caption: [SFGA data tables in v0.4.2.],
  table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    [*Table*], [*Content*],
    [`version`], [Schema version of this archive],
    [`metadata`], [Dataset-level provenance and descriptive metadata],
    [`contact`], [Contact persons for the dataset],
    [`creator`], [Dataset creators (for citation)],
    [`editor`], [Dataset editors],
    [`publisher`], [Publishing organisation],
    [`contributor`], [Additional contributors],
    [`source`], [Source datasets referenced by this archive],
    [`author`], [Biographical records of nomenclatural authors],
    [`reference`], [Bibliographic references],
    [`name`], [Scientific names (parsed and unparsed fields)],
    [`taxon`], [Accepted taxa with full classification hierarchy],
    [`synonym`], [Synonyms linked to accepted taxa],
    [`vernacular`], [Vernacular (common) names],
    [`name_relation`], [Nomenclatural relationships between names],
    [`type_material`], [Type specimen records],
    [`distribution`], [Geographic distribution records],
    [`media`], [Images and other media linked to taxa],
    [`treatment`], [Taxon treatment documents],
    [`species_estimate`], [Estimated species counts per taxon],
    [`taxon_property`], [Arbitrary key–value properties for taxa],
    [`species_interaction`], [Ecological interactions between taxa],
    [`taxon_concept_relation`],
    [Set-theoretic relationships between taxon concepts],

    [`name_match`], [Pre-computed name-matching results],
  ),
) <sfga-tables>

=== Column namespaces

Every column name is prefixed with a namespace token that identifies the
vocabulary it belongs to. This makes the origin of each field explicit and
allows tools to process only the namespaces they understand while ignoring
the rest. The four current namespaces are:

#figure(
  placement: none,
  caption: [Column namespace prefixes used in SFGA.],
  table(
    columns: (auto, auto, 1fr),
    stroke: 0.5pt,
    [*Prefix*], [*Vocabulary*], [*Notes*],
    [`col__`],
    [Catalogue of Life Data Package],
    [Primary vocabulary; all CoLDP fields are present],

    [`gn__`], [Global Names], [Global Names-related fields],
    [`sf__`], [Species File], [Fields used by several SFG projects],
    [`tw__`], [TaxonWorks], [TaxonWorks-related fields],
  ),
) <sfga-namespaces>

Terms for the `gn__`, `sf__`, and `tw__` namespaces are defined at
`https://terms.sfg.org` (under active development). `col__` terms follow the
published CoLDP specification @coldp.

=== Controlled vocabularies

Controlled vocabularies are implemented as read-only tables with hardcoded
values, following CoLDP conventions where applicable. For example, the
`taxonomic_status` table defines the permitted values for the
`col__status_id` column in the `taxon` and `synonym` tables according to
CoLDP specification:

#figure(
  placement: none,
  caption: [The `taxonomic_status` controlled vocabulary table (v0.4.2).],
  table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    [*Value*], [*Meaning*],
    [`ACCEPTED`], [The taxon is accepted under the relevant code],
    [`PROVISIONALLY_ACCEPTED`], [Accepted pending further review],
    [`SYNONYM`], [A heterotypic or homotypic synonym],
    [`AMBIGUOUS_SYNONYM`],
    [A name that is a synonym of more than one accepted taxon],

    [`MISAPPLIED`],
    [A name used incorrectly in the literature for a different taxon],

    [`BARE_NAME`], [A name published without a formal description],
  ),
) <sfga-taxstatus>

Note that the terms are using botanical semantic, and would require signiicant
improvement to provide better semantic resolution.

Other vocabulary tables cover nomenclatural codes, ranks (150+ entries from
domain to strain), nomenclatural status, type-specimen status, name
relationships, species interactions (50+ ecological interaction types with
OBO references), geological time periods (200+ entries), and geographic
gazetteers.

== SFlib

Without a shared library, every tool in the ecosystem would re-implement
the same SFGA read/write logic, format parsers, and normalisation routines
independently — `sflib` eliminates that duplication and ensures that a bug
fix or schema change propagates to all tools at once.

=== Package structure

`sflib` is a pure-Go library @mozzherin_ower_2026_sflib that
requires no CGO and no system-level SQLite installation; all SQLite access
goes through the `modernc.org/sqlite` pure-Go driver. It means that applicatons
developed on the base of `sflib` are self-sufficient and do not require
SQLite to be present. The library is
organised around five format packages, each providing the same
`arch.Packager` interface:

#figure(
  placement: none,
  caption: [`sflib` format packages.],
  table(
    columns: (auto, auto, 1fr),
    stroke: 0.5pt,
    [*Package*], [*Format*], [*Description*],
    [`pkg/sfga`], [SFGA], [Read and write SQLite-based SFGA archives],
    [`pkg/coldp`],
    [CoLDP],
    [Read and write Catalogue of Life Data Package ZIP archives],

    [`pkg/dwca`], [DwCA], [Read and write Darwin Core Archive ZIP files],
    [`pkg/xsv`],
    [CSV / TSV / PSV],
    [Read and write delimited-value files with DwC or CoLDP column headers; delimiter auto-detected],

    [`pkg/text`],
    [Plain text],
    [Read and write files with one scientific name per line (UTF-8)],
  ),
) <sflib-packages>

=== Public API

All five format packages implement the `arch.Packager` interface:

#raw(
  block: true,
  lang: "go",
  "type Packager interface {
    Fetch(src, dst string) error // retrieve source into a cache directory
    Create(dir string) error // create an empty archive in a cache directory
    Export(out string, zip bool) error // write the cache to an output file
}",
)

Instances are created via package-level factory functions in the root
package:

#raw(
  block: true,
  lang: "go",
  "sflib.NewText(opts...)   // plain text: one name per line
sflib.NewXsv(opts...)    // CSV / TSV / PSV
sflib.NewColdp(opts...)  // CoLDP
sflib.NewDwca(opts...)   // DwCA
sflib.NewSfga(opts...)   // SFGA",
)

Key configuration options — passed to any factory — include `OptNomCode` (sets
the nomenclatural code of a dataset: zoological, botanical, bacterial, …),
`OptJobsNum` (sets the level of concurrency: default 5), `OptBatchSize`
(defines number of records processed in a batch: default 50,000),
`OptWithParents` (indicates an intention to create a parent/child hierarchy
from flat classificatios), and `OptLocalSchemaPath` (tells to use a local
`schema.sql` instead of fetching the latest one from GitHub).

Record data flows between packages through the `coldp.NameUsage` and
`coldp.Data` types defined in `pkg/coldp`, which serve as the canonical
in-memory representation regardless of the source or target format.

=== Usage

`sflib` is consumed as a standard Go module dependency:

#raw(block: true, lang: "sh", "go get github.com/sfborg/sflib")

The primary reference implementation of the library is `sf` (see below).

== SF — Universal Converter and Differ

Biodiversity data comes in multiple formats, and converting between them
is not a trivial task; `sf` automates the full round-trip — import any
supported format, query or transform it as SFGA, then export to any other
format — and also tells you exactly what changed between two versions of a
dataset. In addition `sf` package allows to prepare outdated SFGA files by
updating them to the latest available version.

#figure(
  placement: none,
  caption: [The functionality of `sf` subcommands.
*(A)* Universal converter allows to import and export various dataset
formats as SFGA.
*(B)* Calculation of differences between two SFGA files (currently
only scientific name strings and authorships are supported).
*(C)* Schema migration allows to upgrade older backward compatible
versions of SFGA to the current version.],
  sf-figure,
) <sf-figure>

=== Importing data into SFGA

`sf from` converts a source file into a pair of SFGA outputs: a plain-text SQL
dump (`.sql`) and a ready-to-use binary SQLite database (`.sqlite`) (@sf-figure
panel *A*). Supported input formats are Darwin Core Archive (DwCA), Catalogue of
Life Data Package (CoLDP), delimiter-separated files with DwC or CoLDP headers
(CSV, TSV, PSV), and plain-text name lists. The format is inferred from the
file extension and internal structure; the output path prefix is provided by
the user:

#raw(
  block: true,
  lang: "sh",
  "sf from coldp dataset.zip  output/dataset   # CoLDP → SFGA
sf from dwca  dataset.zip  output/dataset   # DwCA  → SFGA
sf from xsv   dataset.csv  output/dataset   # CSV   → SFGA
sf from text  names.txt    output/dataset   # names → SFGA",
)

Input can be a local file path or a remote URL; `sf` downloads and caches
remote files automatically. To keep smaller footprint of created SFGA files
there is also a flag to compress them by ZIP algorithm.

=== Exporting from SFGA

`sf to` exports an SFGA archive to any of the supported output formats
(@sf-figure panel *A*):

#raw(
  block: true,
  lang: "sh",
  "sf to coldp dataset.sqlite output    # SFGA → CoLDP
sf to dwca  dataset.sqlite output    # SFGA → DwCA
sf to xsv   dataset.sqlite output    # SFGA → CSV
sf to text  dataset.sqlite names     # SFGA → plain text",
)

=== Comparing datasets

`sf diff` computes a difference between two SFGA files and writes the
result as a third SFGA archive whose tables record which taxa, names, and
synonyms were added, modified, or removed. The comparison can optionally
be scoped to a named taxon in each file (@sf-figure panel *B*):

#raw(
  block: true,
  lang: "sh",
  "sf diff v1.sqlite v2.sqlite diff.sqlite
sf diff v1.sqlite v2.sqlite diff.sqlite \\
    --source-taxon Plantae --target-taxon Plantae",
)

Currently `sf diff` is limited to comparing scientific name strings between
datasets, however it is intelligent enough to be able to normalize canonical
forms and authorships to achieve accurate comparison of different lexical
varians of the same name.

=== Migrating schema versions

`sf update` migrates an SFGA file produced by an older schema version to
the current schema, preserving all data. An additional flag converts a
flat classification — a list of taxa without explicit parent identifiers —
into a proper parent/child hierarchy with generated identifiers (@sf-figure
panel *C*):

#raw(
  block: true,
  lang: "sh",
  "sf update old.sqlite output/updated
sf update flat.sqlite output/tree --add-parents",
)

`sf` can be installed via Homebrew (`brew install sf`), by downloading a
pre-built binary from the GitHub releases page, or with
`go install github.com/sfborg/sf@latest`.

=== Performance

// TODO: an example of converting CoL's CoLDP to SFGA

== Harvester

Not every biodiversity dataset is published in a standard format; many
sources distribute data as bespoke database dumps, proprietary spreadsheets,
or web-scraped content that `sf` cannot handle generically. `Harvester`
fills that gap with hand-written adapters for each such source.

#figure(
  placement: none,
  caption: [The `harvester get` subcommand converts idiosyncratic datasets
    to SFGA. Colored non-rectangular shapes represent heterogeneous
    non-standard datasets; the ellipsis indicates additional sources not
    shown.],
  harvester-figure,
) <harvester-figure>

=== Supported sources

Each source is implemented as a Go package under `internal/sources/` and
registered with a short label. The sources currently included are:

#figure(
  placement: none,
  caption: [Data sources supported by `harvester`.],
  table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    [*Label*], [*Source*],
    [`grin`],
    [GRIN (Germplasm Resources Information Network) — plant genetic resources],

    [`ioc`], [IOC World Bird List — ornithological checklist],
    [`itis`], [ITIS (Integrated Taxonomic Information System)],
    [`ncbi`], [NCBI Taxonomy],
    [`paleodb`], [Paleobiology Database],
    [`wikisp`], [Wikispecies],
    [`worldplants`], [World Plants],
  ),
) <harvester-sources>

=== Source adapter interface

Every adapter implements the `data.Convertor` interface and is registered
via a `data.DataSet` descriptor that carries a short label, a human-readable
name, usage notes, a download URL, and a `ManualSteps` flag for sources
whose conversion cannot be fully automated (the `Notes` field must then
document the manual steps). New sources are added by implementing the
interface and registering the descriptor; no changes to the core pipeline
are required.

=== CLI usage

The `harvester list` subcommand prints all registered sources with their labels
and IDs. The `harvester get` cubcommand fetches and converts a source by label
or list position (@harvester-figure):

#raw(
  block: true,
  lang: "sh",
  "harvester list                      # show registered sources
harvester get itis                   # fetch and convert ITIS
harvester get itis output/itis -z   # compress output as zip
harvester get ioc  -f local.zip     # use a pre-downloaded file",
)

=== Performance

// TODO: an example of converting a fairly large dataset like ITIS.

== gndb

GNverifier @mozzherin2024gnverifier is a high-throughput name-verification
service that resolves scientific names against hundreds of biodiversity data
sources. Running a local GNverifier instance requires loading those sources
into a PostgreSQL database; `gndb` automates that loading step, taking SFGA
archives as its sole input.

#figure(
  placement: none,
  caption: [Data-flow overview of `gndb populate`. Multiple SFGA archives are
    loaded into the `gnames` PostgreSQL database; GNverifier queries that
    database directly (dashed arrow).],
  gndb-figure,
) <gndb-figure>

=== Database lifecycle

`gndb` manages the full lifecycle of the GNverifier PostgreSQL database
through four subcommands:

#raw(
  block: true,
  lang: "sh",
  "gndb create    # create the database schema
gndb migrate   # apply schema migrations
gndb populate  # load SFGA sources into the database
gndb optimize  # build indexes for fast verification",
)

=== Populating from SFGA sources

Sources are declared in `~/.config/gndb/sources.yaml`. Each entry
specifies a numeric ID, a parent directory or URL where the SFGA file
lives, and optional metadata overrides. Source IDs below 1000 are reserved
for official GN data sources; IDs 1000 and above are for custom local
sources. `gndb populate` reads the YAML, downloads or opens each SFGA
file, and imports data in five ordered phases: dataset metadata, name
strings and canonical forms, vernacular names, taxonomic hierarchy, and
finally name-string indices. All five phases use batched inserts for
performance (@gndb-figure).

#raw(
  block: true,
  lang: "sh",
  "gndb populate                    # load all sources in sources.yaml
gndb populate --source-ids 1,11  # load specific sources only",
)

=== Fit within the broader pipeline

`gndb` sits at the downstream end of the SFBorg pipeline: `sf` or
`harvester` produce SFGA archives from external data, and `gndb` loads
those archives into the GNverifier database. Once `gndb optimize` has
built the indexes, the database is ready to serve verification requests.
The separation means that the same SFGA file produced by `sf` can be
examined interactively via SQL, archived to Zenodo, and loaded into
GNverifier — all without reprocessing the original source data.

=== Performance

// TODO: an example of ingesting CoL data.

== Conclusions

The four components described above form a coherent system unified by a
single design decision: SFGA, a SQLite database, serves simultaneously as
the exchange unit, the live queryable dataset, and the stable contract
between tools. Every claim made in the Introduction and Project Description
rests on a specific technical consequence of that decision.

The Introduction argued that conventional archive formats are effectively
inert — useful only after an import pipeline has processed them. SFGA
addresses this directly: because the archive _is_ a database, a recipient
with any SQL client can query, filter, and modify the dataset the moment
it arrives, with no intermediate step. The Introduction also noted that CSV
and XML archives are error-prone to produce and import; SFGA removes most
of those failure modes by replacing free-form text files with a schema that
enforces field types, controlled vocabularies, and referential structure at
write time.

The Introduction further noted the absence of a standard diff mechanism.
`sf diff` fills that gap at the semantic level: rather than a line-by-line
text diff, it records which taxa, names, and synonyms were added, modified,
or removed between two dataset versions, and writes the result as a
queryable SFGA archive in its own right.

The Project Description claimed that the ecosystem enables lossless
round-trips between formats. That property follows from `sflib`'s
architecture: all five format packages share the same `coldp.NameUsage`
in-memory representation, so a DwCA → SFGA → CoLDP conversion does not
pass through any lossy intermediate. The Project Description also described
`sflib` as the mechanism that prevents logic duplication across tools; the
single `arch.Packager` interface, with its `Fetch`, `Create`, and `Export`
methods, means that a new format can be added to the ecosystem by
implementing one interface, with no changes required to any existing tool.

The Project Description described `harvester` as handling sources that
cannot be processed generically. The adapter model confirms this: each
source is an independent Go package implementing the `data.Convertor`
interface, registered by label, with a `ManualSteps` flag for sources
whose conversion cannot be fully automated. The core pipeline is untouched
when a new source is added.

*Schema evolution and backward compatibility.* The most significant
trade-off of the SQLite approach compared with text-based formats is schema
compatibility. A new Darwin Core term or CoLDP field is invisible to
existing consumers — they simply encounter an extra column they do not
recognise and continue working. A new column in the SFGA schema, by
contrast, is a structural change: SQL queries that reference specific
columns or rely on schema introspection may fail against a newer file.
Before v1.0.0 this tension is managed by semantic versioning with explicit
breaking-change declarations; every SFGA file carries a `version` table
that records the schema version it was produced with, and `sf update`
migrates any older file to the current schema automatically. After v1.0.0
the schema commits to additive-only evolution: new columns and tables may
be added, but nothing will be renamed or removed. Under that regime `sf
update` provides the same automated forward migration, giving users
long-term backward compatibility through a single command. Notably, neither
DwCA nor CoLDP provide any equivalent migration mechanism; consumers of
those formats are expected to handle schema drift silently or fail.

Taken together, the SFBorg ecosystem demonstrates that representing a
biodiversity exchange standard as a SQLite schema is not merely
theoretically attractive but practically viable. The same file serves as
an archive, a live database, a diff target, and a direct backend for
production applications — roles that conventional text-bundle formats
require separate tooling to fulfil, if they can fulfil them at all.

*SFGA as a platform.* `gndb` represents a qualitative step beyond the
other tools in the ecosystem: where `sf` and `harvester` treat SFGA as
an exchange format to produce or consume, `gndb` uses it as the stable
contract on which a production application is built. It does not parse
SFGA and discard it; it reads SFGA directly into a live service, with the
schema defining the interface between data producers and data consumers.
This is only the beginning of what that role makes possible. Any team
that needs a queryable, citable, diff-aware biodiversity checklist can
adopt SFGA as their database backend without building format parsers or
import pipelines. A universal taxonomic editor could open any SFGA file
the way a word processor opens a document. A web-based viewer could make
a taxonomist's life work publicly accessible the moment the data are
converted. Diff-based peer review could let reviewers annotate semantic
changes between two SFGA versions as naturally as tracked changes work in
a manuscript. Offline field tools could carry a working checklist on a
tablet and synchronise edits back through the existing diff mechanism.
The SQL interface also makes SFGA-backed checklists immediately accessible
to AI-assisted workflows without custom integration. Each of these
directions is a straightforward extension of what the current ecosystem
already does. The SFGA schema, once stable, is not merely an exchange
format but a foundation — and the tools described in this paper are the
first layer built on it.

= Additional Information

== Dependencies

All tools are written in Go and manage dependencies via Go modules (`go.mod`).
Key shared dependencies across the ecosystem:

- *sflib* — internal shared library (all tools)
- List other major external Go packages used (e.g. for SQLite driver, name parsing,
  CLI framework), with links and brief roles

Tool-specific dependencies (e.g. gndb → PostgreSQL driver) should be noted per tool.
It is worth noting that all described above applicatios are stand alone binaries
compiled for CPUs and Operating Systems that cover wast majority of users.
These files to not require any additional libraries to run.

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

