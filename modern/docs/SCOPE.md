# CardDemo → Java 21: scope, purpose, target and effort

Status: **agreed** (plan step `s1.1`, decisions `d-scope` = `core-only`, `d-purpose` = `reference-demo`).
This document fixes what "migrate CardDemo to Java 21" covers. Later phases build against it; changing it
means updating this file in a reviewed PR first.

## 1. Purpose and commitment

| Item | Decision |
|---|---|
| Purpose | **Reference demo** on this sample repo (a fork of the AWS CardDemo sample, no production deployment). |
| Customer | None. Not a rehearsal for a named customer pilot. |
| Source of truth | The Git repo as-is. No live z/OS, CICS or VSAM access; COBOL behaviour is reproduced with GnuCOBOL (golden master) and read from source. |
| Definition of done | Every in-scope online transaction and batch job runs on Java 21 with outputs matching the COBOL on the same data, plus a full E2E test with written report and video. |

**Commitment question.** Because this is a reference demo, the customer commitment question
("implement along this scope, validate as agreed, reduce time by X: can you commit?") does **not** apply and
Phase 2 is not gated on it. If the purpose changes to a customer pilot, this section must be updated, and the
question answered here, before Phase 2 starts, with these extra prerequisites recorded:
the customer's platform and runtime constraints, their source-control export (actual production COBOL/JCL/CSD),
and a test environment to deploy to.

## 2. Scope

### In scope: the core application (online CICS + batch on VSAM)

Counts are from the repo at the time of writing; `modern/docs/INVENTORY.md` (step `s1.2`) is the detailed, authoritative list.

| Area | Source | Count | Notes |
|---|---|---|---|
| COBOL programs | `app/cbl/` | **31** | 15,834 code lines excluding comments and blank lines (20,650 physical lines) |
| – online (CICS) | `app/cbl/CO*C.cbl` | 17 | 11,150 code lines; sign-on, menus, account, card, transaction, bill pay, reports, user admin |
| – batch / subroutines | `app/cbl/CB*`, `CSUTLDTC`, `COBSWAIT` | 14 | 4,684 code lines; includes subroutines `CBSTM03B` (called by `CBSTM03A`) and `CSUTLDTC` (date check, called by `CORPT00C`, `COTRN02C`) |
| BMS maps | `app/bms/` (+ `app/cpy-bms/`) | **17** | One per online screen |
| JCL jobs | `app/jcl/` | **38** | Business batch, data setup (IDCAMS/GDG) and platform ops jobs; see 2.3 |
| JCL procs | `app/proc/` | 2 | `REPROC`, `TRANREPT` |
| Copybooks | `app/cpy/` | 30 | 2,264 code lines; record layouts become Java records (step `s2.3`) |
| CICS definitions | `app/csd/CARDDEMO.CSD` | 18 transactions, 18 programs, 17 mapsets, 8 files | Transaction ids and file definitions |
| VSAM datasets | `app/jcl/*` IDCAMS | 15 clusters, 3 AIX (each with a path), GDG bases in `DEFGDGB`/`DEFGDGD` | Account, card, customer, xref, transaction, user security, category balance, reference tables |
| Sample data | `app/data/EBCDIC/`, `app/data/ASCII/` | 13 + 9 files | Seed and parity data |
| Assembler helpers | `app/asm/`, `app/maclib/` | 2 | `COBDATFT` (date format, used by `CBACT01C`), `MVSWAIT` (used by `COBSWAIT`); reimplemented as Java utilities |
| Batch schedules | `app/scheduler/` | 2 | Control-M and CA7 definitions give the batch-cycle order the Java batch runner follows |

Online transactions in scope (from the CSD and README):
`CC00` sign-on, `CM00` main menu, `CA00` admin menu, `CAVW`/`CAUP` account view/update,
`CCLI`/`CCDL`/`CCUP` card list/view/update, `CT00`/`CT01`/`CT02` transaction list/view/add,
`CB00` bill payment, `CR00` transaction reports, `CU00`–`CU03` user list/add/update/delete.

### Out of scope

| Item | Reason |
|---|---|
| `app/app-authorization-ims-db2-mq/` (IMS DB + DB2 + MQ pending authorisations; `CPVS`, `CPVD`, `CP00`, `CBPAUP0J`) | Scope decision `d-scope` = `core-only` |
| `app/app-transaction-type-db2/` (DB2 transaction-type admin; `CTTU`, `CTLI`, `CREADB21`) | Scope decision `d-scope` = `core-only` |
| `app/app-vsam-mq/` (MQ account/date inquiry) | Scope decision `d-scope` = `core-only` |
| `samples/m2/` (AWS Mainframe Modernization / UniKix runtime configs) | Reference only for platform behaviour; not migrated |
| Control-M / CA7 as products | Only the job order and dependencies are carried over; no scheduler integration |
| RACF, z/OS system services, 3270 terminal protocol | Replaced by application-level sign-on (`USRSEC`) and web screens |
| `CDV1` / `COCRDSEC` (developer transaction in the CSD) | No source in the repo; recorded here so the inventory does not count it as missing work |

### 2.3 How the 38 JCL jobs are treated

Every job is in scope, but not every job becomes a Java program. The inventory (`s1.2`) gives the per-job classification; the rule is:

| Kind | Examples | Java 21 equivalent |
|---|---|---|
| Business batch (runs a COBOL program) | `POSTTRAN`, `INTCALC`, `TRANREPT`, `CREASTMT`, `CBEXPORT`, `CBIMPORT`, `READ*`, `WAITSTEP` | Migrated program run by the batch runner, parity-tested against GnuCOBOL goldens |
| Batch utilities (SORT, IDCAMS REPRO, GDG) | `COMBTRAN`, `TRANBKP`, `PRTCATBL`, `DALYREJS` | Runner steps with the same inputs/outputs (step `s4.1`) |
| Data definition / load (IDCAMS DEFINE + REPRO) | `ACCTFILE`, `CARDFILE`, `CUSTFILE`, `XREFFILE`, `TRANFILE`, `DUSRSECJ`, `DEFGDG*`, ... | Flyway schema + EBCDIC loader (steps `s3.1`, `s3.3`) |
| Platform ops | `OPENFIL`/`CLOSEFIL` (SDSF), `CBADMCDJ` (CSD), `FTPJCL`, `TXT2PDF1`, `INTRDRJ1/2` | Equivalent where meaningful in a container app, otherwise recorded with reason in `modern/docs/PARITY_EXCEPTIONS.md` |

Note: `CBTRN01C` is not referenced by any JCL in the repo; it is still migrated and its status is noted in the inventory.

## 3. Target

| Item | Target |
|---|---|
| Language / runtime | **Java 21 LTS** |
| Framework | Spring Boot 3, layered modules (controller / service / repository per CICS program family) |
| Build | Maven, run locally and in **GitHub Actions** (CI must be green on every PR) |
| Data store | **PostgreSQL** with Flyway migrations; VSAM KSDS/AIX semantics (keyed read, browse, rewrite, delete) kept in repositories |
| Online UI | 3270-style web screens that mirror the BMS maps (same fields, layout, PF keys, messages) |
| Batch | Java batch runner reproducing the JCL steps and the scheduler's batch-cycle order |
| Deployment (pilot) | Containerised app: **Docker Compose with app + PostgreSQL**, startable by anyone with `docker compose up` |
| Code location | `modern/` in this repo; COBOL in `app/` stays untouched as the reference |
| Parity validation | Golden set from GnuCOBOL for batch + automated UI tests for online (step `s1.3`) |
| Behaviour changes | None silently. Every intentional deviation goes to `modern/docs/PARITY_EXCEPTIONS.md` (COBOL behaviour, Java behaviour, reason) |

## 4. Value: expected manual vs AI effort

Estimate for the agreed scope only. Method: code-line counts from section 2, a manual rewrite rate of
~120 COBOL code lines per person-day for analysis + Java rewrite + unit tests (online and batch alike), plus
fixed allowances for framework, data, screens and verification work. These are planning estimates, not
measurements; the actuals are recorded in the E2E report (step `s6.5`).

| Work package (plan phase) | Size driver | Manual (person-days) | AI-assisted, human effort (person-days) |
|---|---|---:|---:|
| Scope and discovery (p1) | 31 programs, 38 jobs, 30 copybooks | 10 | 1 |
| Java 21 foundation: scaffold, CI, runtime library, copybook records, golden harness (p2) | 30 copybooks, COBOL numeric/EBCDIC semantics | 20 | 3 |
| Data layer: schema, VSAM repositories, EBCDIC loader/exporter (p3) | 15 clusters, 3 AIX, 13 EBCDIC files | 20 | 3 |
| Batch programs (p4) | 14 programs, 4,684 code lines | 40 | 4 |
| Batch utility / JCL equivalents (p4) | 38 jobs, 2 procs | 15 | 2 |
| Online programs (p5) | 17 programs, 11,150 code lines | 93 | 7 |
| Online screens (p5) | 17 BMS maps | 25 | 3 |
| Parity, regression, performance, security, E2E report (p6) | full batch cycle + 18 transactions | 45 | 5 |
| **Total** | | **≈ 268 person-days (≈ 13 person-months)** | **≈ 28 person-days** |

- **Manual**: ≈ 268 person-days; with a team of 4, about 3.5 months elapsed.
- **AI-assisted**: Devin sessions do the analysis, code, tests and evidence, one per board ticket (27 tickets), running in parallel where dependencies allow.
  Human effort is review of each PR, the plan decisions, and sign-off on parity exceptions: ≈ 28 person-days, about 2–3 weeks elapsed.
- **Expected reduction**: ≈ 90% of human effort for the same scope and the same validation bar.
- Compute cost is tracked as ACUs per ticket on the board and reported with the actuals in `s6.5`.

## 5. Phases that build on this scope

| Phase | Covers |
|---|---|
| p1 Scope and discovery | This document, inventory, parity approach |
| p2 Java 21 foundation | Project + CI, runtime library, copybook records, GnuCOBOL golden harness |
| p3 Data layer | Relational schema, VSAM-semantics repositories, EBCDIC loader/exporter |
| p4 Batch | Batch runner, read utilities, posting, interest, reports/statements, export/import |
| p5 Online | Transaction framework, sign-on/menus, account, card, transactions/bill pay, reports/user admin |
| p6 Parity end to end | Full batch-cycle parity, online regression, performance, security, E2E report and video |
