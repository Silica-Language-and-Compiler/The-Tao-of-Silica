# Silica: a research history (for the HISTORY chapter, the "Why? / Why not?" chapter, and the author interview)

Compiled 2026-11-13 from the Silica repository at `/Volumes/2T/silica` (686 commits, 2025-12-26 to 2026-11-13). Nothing in that repository was modified.

## How to read this document

**Citation conventions.**
- `[c:abc1234]` is a commit hash in `/Volumes/2T/silica`. Read it with `git -C /Volumes/2T/silica show abc1234`.
- `[mem:name]` is `/Volumes/2T/silica/.claude-memory/name.md`.
- `[dd:file]` is `/Volumes/2T/silica/compiler/design_documents/file`.
- `[ROADMAP]`, `[AI_POLICY]` and `[README]` are files at the repository root. `[spec §x]` is `compiler/design_documents/silica-specification.md`.
- `[slides:intro n]` is slide n of `Silica_intro_FP_Erlang_Elixir_Gleam.pptx`. `[slides:ds]` is `Silica_standard_data_structures_single_slide.pptx`.

**Two cautions about sources.**
1. **The `.claude-memory` files were written by AI agents, not by the author.** They record the author's instructions as the agents understood them. Some lines are in quotation marks and look verbatim. Others are agent paraphrase, sometimes in capitals ("UNACCEPTABLE", "NO DEFAULTS"). Below, a quotation from a memory file is marked as *agent-recorded*. Check each one with the author before printing it as his words.
2. **"Phase" means three different things in this repository.** Keep them apart in the book:
   - **Bootstrapping phases (Dec 2025 to early 2026).** Phase 1 is the Rust/LLVM bootstrap compiler. Phase 2 is the compiler written in Silica. Phase 3 is ecosystem maturity. Source: `AArch64/bootstrapping.md` in the first commit [c:322710bd20].
   - **`Phase1_TODOs/` and `Phase2_TODO/`.** These are roadmap-stage to-do directories: data structures, self-host plan, actor stacks, sharded structures.
   - **`Phase2_notes.md` to `Phase6_notes.md`, `Phase3_*_analysis.md` and `Phase4_prep.md`.** These are the running notes of **phases 2 to 6 of ROADMAP chunk 15**, the stack-memory redesign, written 26 Oct to 1 Nov 2026. The header of each says "running notes (Fable)". They are not the early compiler phases.

**Who appears in the record.**
- The author commits as `yenrab` (431 commits) and as `Lee Barney` (239).
- One outside contributor, Chase Willden, has 16 commits from 2026-10-26: editor themes, GitHub Actions compiler builds, and publishing the spec with releases [c:26e3f027e6, c:dd539a2457, c:4a0c042e76].
- About 220 commits carry `Co-Authored-By: Claude ...` trailers. The first is on 2026-03-18 [c:85510ad55a]. The process section below covers this.

---

## 1. Timeline of eras and milestones

Commits per month show the rhythm:

| Month | Commits | Note |
|---|---|---|
| Dec 2025 | 20 | |
| Jan 2026 | 42 | |
| Feb 2026 | 69 | |
| Mar 2026 | 54 | |
| Apr 2026 | 84 | |
| May 2026 | 69 | |
| Jun 2026 | 21 | the quiet summer |
| Jul 2026 | 27 | the quiet summer |
| Aug 2026 | 20 | the quiet summer |
| Sep 2026 | 46 | |
| Oct 2026 | 117 | |
| Nov 2026 | 117 | 1 to 13 Nov only |

Commit counts understate the summer's work: self-hosting commits were few and large.

### Era 0: The bootstrap compiler in Rust (26 Dec 2025 to mid-Jan 2026)

- **2025-12-26.** "first checkin of bootstrap silica compiler for AArch64" [c:322710bd20].
  - It is a Rust crate (`lexer.rs`, `parser.rs`, `types.rs`, `effects.rs`, `codegen.rs`) emitting LLVM bitcode.
  - Beside it are AALang/GAB JSON-LD "agent graph" files (`gab.jsonld`, `silica-bootstrap-compiler-builder.jsonld`). These are executable prompts that tell an LLM to "Act as if you ARE the GAB agent".
  - The same day the boot compiler was renamed `silica-boot` [c:531c84dc28].
- **The founding strategy** (`AArch64/bootstrapping.md`, first commit): "The bootstrap compiler uses LLVM temporarily for development velocity. The complete compiler eliminates LLVM entirely to achieve Silica's architectural goals."
  - It budgeted "6-9 Months" for Phase 1. The bootstrap was effectively done within about three weeks of commits (see 2026-01-16/17 below). By April the README said: "The **bootstrap compiler** is complete" [c:1ba815585c README].
- **The founding design notes** (`AArch64/design_notes.md`, first commit):
  - "A functional systems language designed for AArch64 (baseline M4 / Apple Silicon possible extensions)"
  - "No C interop, no 'legacy baggage'"
  - "No loops. Recursion only."
  - "No raw pointers. No unsafe."
  - "Syntax optimized for structured readability and robustness for LLMs. Erlang-like instead of Lisp-like."
  - "Core model: processes as monads".
- **2025-12-27 to 31.** hello.silica runs. The experiment directories pass: basics, data types, patterns, memory [c:7e30893845 … c:051a378c06].
  - "added ideas for presentations" (12-30) [c:d272074605].
  - "Removed generics for now" (12-31) [c:fb7a553edd].
  - Functor, Monoid and Monad traits with compile-time law enforcement (12-31) [c:25c41ec9df].
- **2026-01-01 to 03.** Actor spawn with closures, then core-affinity tests [c:e4ad6b472d, c:892a9d2b78].
  - "added beam2.0 architecture plans as a shim" [c:d8a4f7544e]. This is the seed of what became Project BEES.
- **2026-01-06 to 15.** Types required on tuple decomposition, then strict compile-time type inference, then the first spawn/send (01-10) [c:d357199e32].
  - A "non-functional 'this is how it could work' scheduler example. There are missing parts in the Silica language that need to be implemented to allow actor stealing to work." [c:efa73829d5]
  - Strings and numerics follow.
- **2026-01-16/17. End of the bootstrap era.**
  - "All experiments that should compile do. All experiments that should fail do." [c:2b6ca1f99c]
  - The detailed language and compiler specification is produced, and "phase 2 compiler" planning begins [c:6440478e4c, c:277c55353c].
  - A lexer-generation tool appears for the phase 2 compiler [c:e12db892a9].

### Era 1: Writing the compiler in Silica (Jan to Jul 2026)

The "phase 2" compiler, later called `src/`, is compiled by the Rust bootstrap.

- **2026-02-07.** The phase 2 lexer source checks in [c:87bfa5cd07].
- **2026-02-10/11.** The minimal parser [c:a5d6354136] and the SIR (Silica Intermediate Representation) spec plus the compiler creation order [c:5ac179aa76].
  - The creation order is lexer, parser, type checker, effect checker, SIR, optimization, codegen, assembler, linker [compiler/silica-compiler-creation-order.md].
  - A change "to align more closely with being a bridge between Silica and AArch64 chip behaviors" [c:f684a2cb88].
- **2026-02-11 to 12.** The first compiling type checker, IR generator and assembly emitter [c:8dd2e0e7f3, c:d69dcd6734, c:6022c4275f].
- **2026-02-16.** "first checkin of phase 2 compiler that generates working fn main(){ 42 } executable." [c:d1761ba0d3]. This is a direct-to-assembly milestone: no LLVM in the Silica-written compiler.
- **2026-02-19.** Initial CI tooling [c:e765fc6d1b]. This is the start of the "trials" culture: golden assembly (`.ascomp`) and golden output (`.scout`).
- **2026-02-21. A one-day burst.** int64, int32, int16, int8 and every unsigned width pass integration in a single day (about 20 commits).
  - The same day: "removed type casting from the silica specification" [c:e7782fa5c3].
- **Feb to Mar 2026.**
  - float64/float32, strings, Unicode.
  - "Moved the current compiler building into the Apple_Silicon directory as that is our first target. String concatenate exists but safe memory allocation isn't working yet." (02-28) [c:612545b86e]
  - Tuples, memory regions, `sequence … produces pure … end` effect blocks (03-11) [c:caf8e02017], user functions (03-14), cases (03-27), recursion (03-28).
- **2026-04-01 to 08.** Lists, then actors ("working actors", 04-07) [c:c2f020b1db], then structs.
  - The 04-07 actor runtime is the origin of the implicit per-actor heap that chunk 15 removed in October [mem:silica-chunk15-stack-direction].
- **2026-04-09. Going public.**
  - File layout is reorganised "to more readily support porting to various chips" [c:9524c5dac2].
  - README, icon and licensing [c:290d6e823d]. Many "wordsmithing" commits follow through 04-14 that sharpen the pitch.
  - Core pinning works (04-10) [c:cb5ef3f364].
- **2026-04-12.** The motto lands: "Secure by default at compile time — fail soft, never fail silent" [c:88cb979dc2; README].
- **2026-04-14 to 22.** Modules [c:1bbcbc4b3d], traits [c:1d8b73b4d4], and supervisors in lettered phases A to E [c:eaed6f44de … c:bbd2394d10].
- **2026-04-27.** CONTRIBUTING, CODE_OF_CONDUCT and **AI_POLICY.md** are added [c:fa5f048d01, c:5f7c7d269b].
- **2026-05-02 to 26. FFI ("Fifi") arrives**, reversing "No C interop".
  - FFI contract v1 [c:e69024a5cb] and the first FFI cut [c:bd80b9aa56].
  - The "Guarded FFI Runtime Boundary" [c:d299c20ee9].
  - `dangerous` actors and the `external_danger` effect [c:04a82d2e8f, c:91b044108f].
  - Mach crash handling, with supervisors restarting crashed dangerous actors [c:fe3097085f].
- **2026-05-18 to 26. The first public bug reports are fixed.** Numbered GitHub issues #1, #2, #5, #6, #7, #10, #11, #12, #18 to #21, #32 and #37 appear in commit messages, for example "fixed issue Compiler doesn't fail when no return type is on main #7" [c:84647f956d].
- **2026-05-27 to 06-24.** The first standard data structure implementation is built phase by phase (phases 3 to 9, heaps, B-trees, graphs). The bootstrap compiler now builds on Raspbian/Debian (06-01) [c:cadb5efd84].
- **2026-06-29. Reversal.** "removed existing data structures design and implementation. It was overly complicated for purpose. Added new design and implementation plan." [c:df118756e3]
- **2026-07-01 to 16.** The new layered plan (layer 1, then 8A.2 to 8A.10), then the OrderedMap and OrderedSet traits.
  - "OrderedSet now exists and passes integration tests. We're all set up to begin the conversion to remove the rust bootstrap compiler." [c:bd2cc56085]

### Era 2: Self-hosting (17 Jul to 17 Sep 2026)

- **2026-07-17.** "first check in of partially transformed src_selfhost that is being compiled by src compiler" [c:1de9f17199].
  - Three compilers now exist: the Rust **bootstrap** compiles `src/`, which yields the **seed**; the seed compiles `src_selfhost/`, which yields the **selfhost**.
  - The two Silica trees were in *different dialects* [mem:silica-three-dialects].
- **2026-07-23 to 29.** Repeated out-of-memory kills. The work focuses on "reduced RAM use to avoid OOM kill" [c:ce9d6f6e51, c:b06e44ede1, c:3bf7341932].
- **2026-07-31.** "silica-999991-macos-applesilicon is the first fully self-hosted Silica compiler binary. It passes all of the continuous integration tests and, of course, compiles itself." [c:25cc8c89e9]
  - Later documents date "self-hosting reached" to the September fixed point. The July binary compiled itself, but the selfhost-built-by-selfhost chain was not yet stable (see 09-02 and 09-11).
- **2026-08.**
  - The selfhost passes trial suite after suite [c:4ae4203247 … c:2a3c082ae0].
  - The GitHub Pages site goes up (08-26) [c:2979f6cda3].
  - Small "books" on programming and on writing Silica (08-31) [c:e3f66a37de].
  - Around 08-18 (file mtime) the Erlang Workshop 2026 talk deck was made [slides:intro 1].
- **2026-09-02.** "selfhost compiler passes all CI trials" [c:ccdb061050].
  - Root cause found the same day: the selfhost could not compile its own source because of a latent miscompilation, not slowness [mem:silica-selfhost-bootstrap-blocker].
  - The runtime was catching a fault and looping. A pointer into the compiler's own atom table decoded as the ASCII text "ciency\0:".
- **2026-09-03.** The selfhost tree links zero Rust libraries; the binary drops from 7,985,584 to 4,734,512 bytes [mem:silica-selfhost-rust-free].
- **2026-09-07.** A 7-step self-host plan is agreed, with the author's reporting rules: "announce every move from one step to the next explicitly; pause after step 5" [mem:silica-selfhost-plan-operating-rules].
- **2026-09-08/09.**
  - About 10,000 to 20,000 training trial pairs are added: 10,519 success/failure pairs "for LLM training" [mem:silica-train-trial-pairs; c:becd118f7b].
  - Generating them exposed 10 silent miscompilations and 14 diagnostic gaps, logged in [dd:HIGH_PRIORITY_compiler_defects_and_diagnostic_gaps_2026-09-08.md] and its 09-09 addendum.
- **2026-09-12. First fixed point.** "first fixed point version of the compiler. It passes all 33,000+ CI trials" [c:9285f53308].
  - The roadmap is rewritten "by emitter path" [c:349fe0d6f2].
  - The ESP32-S3 port starts the same day [mem:silica-esp32s3-port].
- **2026-09-13.** "Apple Silicon fixed point 1: selfhost reproduces itself; all trials pass" [c:8aff9cdc5a].
- **2026-09-17.** "Linux aarch64 fixed point 1: selfhost reproduces itself on the Raspberry Pi; all 33,840 trials pass on both hosts" [c:8dcf493d49].
  - **The Rust bootstrap crate is deleted** in this commit [dd:Phase1_TODOs/bootstrap_retirement_and_self_host_plan.md, status table].

### Era 3: Many targets (18 Sep to 21 Oct 2026)

- **2026-09-18 to 20. Linux x86-64.**
  - Port phases 0 to 2 on the machine `nix` [mem:silica-linux-x86_64-port].
  - First fixed point 09-19/20: "Fixed points: Apple Silicon, Linux AArch64, Linux x86-64 (first); ESP32-S3 cross compiler rebuilt" [c:e8274292ee].
- **2026-09-19.** A release-planning day with many architectural rulings: the small-main rule, cast over call, check only when you have to, application equals one compilation unit, placement traits, fault 70 and abort 71 (all [mem:*] below).
  - Seven parallel worktree agents (batch 2) are launched; they merge 09-25 [mem:silica-release-plan-2026-09-19; c:fb87d4fd35 … c:9971703f60].
- **2026-09-24/25.** The tree is flattened: `compiler/silica-compiler/` becomes `compiler/`, and `src_selfhost` becomes `src` [mem:silica-tree-layout-move; c:8391f310f0].
- **2026-09-28/29. ESP32-S3 bare metal.**
  - Both Xtensa LX7 cores run actors.
  - Core pinning and cooperative multitasking on the board [c:8efd4f73b4].
  - Display bring-up on the BYU-I eBadge board [c:0edf74e1f2].
  - Roadmap pruning the same day: "removed inbound FFI from the roadmap" [c:269c870e4b]; "removed hotswapping from the roadmap." [c:e75e299ccf]
- **2026-10-07.** New fixed points on all three hosted platforms. The ESP32-S3 compiler drives the board's 24 LEDs and buzzer [c:eff040583d].
- **2026-10-10. "Item M".** 22,251 trials are converted to the supervisor-actor program shape [mem:silica-cast-exit-decision].
- **2026-10-17.** "1,000 actors can now be run on the 512K board." [c:146f34bf19]
- **2026-10-19 to 21. "Item N", the carriers.**
  - Hosted actors move from one OS thread per actor to one carrier thread per logical core, BEAM style.
  - "measured idle-actor capacity on carriers (1,000,000 actors, 630 MB RSS)" [c:7da327ec18].
  - "Item N: carriers are the only execution model" [c:87e0a61e2e].
  - Fixed points on carriers, gen3 == gen2, 10-21 [c:ff78f3578e].

### Era 4: The memory reckoning, chunks 4 and 15 (22 Oct to 4 Nov 2026)

- **2026-10-09.** The chunk 4 (region memory safety) design starts [dd:region_memory_safety_design.md].
- **2026-10-22 to 24.** About 40 numbered decisions by the author in about three days [dd:data_structure_redesign_requirements.md §2A].
  - Messages copy by default (Q18). There is no family arena. Data structures live on actor stacks. State lives at the stack base. Reclamation is deterministic and compiler-proven.
  - On 10-23 the author "is not happy with the design of the standard data structures"; ROADMAP chunk 15 is created [ROADMAP row 15].
  - The Silica-vs-Erlang benchmarks are added the same day [c:30d9a431fe].
- **2026-10-25.** The first merged GitHub pull request, #42, from the `Silica-Language-and-Compiler` organisation [c:82b9bad5c0]. Chunk 15 phase 0 is done [c:d8edd34f64].
- **2026-10-25 to 11-04. Chunk 15 phases 1 to 8.** Their running notes are the Phase*_notes files.

  | Phase | What | Date | Source |
  |---|---|---|---|
  | 1 | per-call lifetime substitution | 10-25 | [c:029adb3161] |
  | 2 | "values live in the frame that makes them, not in a heap the compiler had to guess about" | 10-27 | [c:19a7d19a48; dd:Phase2_notes.md] |
  | 3 | actor state at the stack base, rebuilt at dispatch end | closed by the author 10-31 | [c:a528a2ef0d; dd:Phase3_notes.md] |
  | 4 | mailbox buffers, replies into the caller's stack; implicit heap deleted | 10-31 | [dd:Phase4_notes.md §6b] |
  | 5 | region field removed from every stdlib record; `canonical_arena_*` removed | 10-31 | [dd:Phase5_notes.md §9] |
  | 6 | the region checker | 11-01 | [c:bf2f8c4630; dd:Phase6_notes.md] |
  | 7 | FFI retention, pinned buffers | 11-01 | [c:72e0c5e473] |
  | 8 | Linux close-out | 11-03/04 | x86-64: 35,073 trials pass, 0 fail [ROADMAP row 15] |

  Phases 3, 4 and 5 all record their gates on the same date, 2026-10-31.
- **2026-10-27.** GitHub Actions builds each compiler architecture and releases binaries on merge (PR #46 by Chase Willden) [c:dd539a2457].

### Era 5: Transport, more boards, more networks (5 to 13 Nov 2026)

- **2026-11-05.** Transport design: Transportable, WireFormat (ETF first) and Carrier traits [c:23c198f565].
  - Same day, after a reversal: "drop the Transportable and Recreatable marker traits … there is nothing to declare." [c:31d648fd00]
  - Phases 0 to 2 are built: derived encode and decode, TCP/UDP/serial, and a BEAM demo [c:9f103d161f, c:e9d44f0e64, c:137e1cac18].
- **2026-11-07.**
  - The ESP32-S3 is ported to the chunk 15 stack memory model, "green on the board" [c:029447ad31].
  - **A new bare-metal target**, the STM32 NUCLEO-L476RG (Cortex-M4F, Thumb-2): "base, int* and uint* trials green on the board" [c:e2fabdd3ef].
  - The hosted Linux compilers replace the Mac-built Linux cross compilers [c:9b0ed5af88].
- **2026-11-08.** The links design: `carried_on` declarations, a hardware link layer under carriers, "transport as a full citizen of the language" [c:3957b12114; mem:silica-transport-links-decisions].
- **2026-11-09/10.**
  - ESP32-S3 UART1 and USB-Serial-JTAG carriers [c:aac8b4e620].
  - The Nucleo actor runtime is ported [c:5abdf7e802].
  - Board-to-Mac transport pairs, with Silica and Erlang peers [c:0901cc309f].
  - Hosted Ethernet transport between Mac and Linux [c:3b0d647930].
- **2026-11-11.** "storage carriers (durable logs as transport through time)" are designed [c:eb464496f8]. GPIO pin builtins land on both boards [c:76fc49ef6e, c:dc56759273].
- **2026-11-12.**
  - New target directory `RP2350_raw` for the Raspberry Pi Pico 2 W [c:aff91a6cd7].
  - Nucleo flash execution, first run: "34 spawned, 34 answered" [c:72e99f8905].
  - A direct Mac-to-Linux link under mutual TLS 1.3 [c:00c787323c].
  - Storage carriers S0 and S1 are built [c:d11c763a1d].
- **2026-11-13.** UDP link binding and a strict IPv4 parser (the latest commit) [c:6e3f85e229].

**Where things stand** [ROADMAP]:
- Four emitter paths are formally tracked: Apple Silicon leads; Linux AArch64 and Linux x86-64 follow in lock-step; ESP32-S3 has board releases.
- A fifth (STM32-L476RG) and a sixth directory (RP2350) exist in the tree.
- Bare-metal AArch64 is "planned attention" next, then RISC-V. "Dates are deliberately absent."

---

## 2. Turning points and reversals

Each entry gives what changed, the rationale as recorded, and what was abandoned.

### 2.1 LLVM, then not LLVM
- **Change.** The Rust bootstrap emitted LLVM bitcode (12-27, ".bc files"). The Silica-written compiler emits AArch64 assembly text directly, from 2026-02-16.
- **Rationale.** "The bootstrap compiler uses LLVM temporarily for development velocity. The complete compiler eliminates LLVM entirely to achieve Silica's architectural goals." (`AArch64/bootstrapping.md` [c:322710bd20])
  - The future-direction document goes further: the compiler should own instruction encoding and object files, explicitly not "Using LLVM, Cranelift, or another backend/object library" [dd:direct_machine_object_emitter_future.md §3].
  - Its stated reason: "The goal is not merely faster compilation. The goal is a compiler architecture where Silica can reason about the chip-shaped facts it exposes" (§1).
- **Abandoned.** LLVM, and later Rust. The bootstrap crate was deleted 2026-09-17 [c:8dcf493d49].

### 2.2 "No C interop" becomes Fifi, the dangerous FFI
- **Change.** The founding notes say "No C interop, no 'legacy baggage'". In May 2026 an outbound FFI was built, wrapped in a vocabulary of danger: `dangerous_*` names that propagate to the app root, dedicated worker actors, and the `external_danger` effect.
- **Rationale, as told to an audience.** "Fifi does not make C safe. It makes the boundary hard to hide. … Audits should be grep-friendly." [slides:intro 8]
  - The README image: "Think of a cute poodle that bites" [README].
- **Kept as an alternative.** Brokered IPC, a separate process for untrusted C, is still "proposed" [README].
- **Abandoned.** Inbound FFI was removed from the roadmap 2026-09-29 [c:269c870e4b]. The roadmap now says "Calls from other languages into Silica are not planned." [ROADMAP, Runtime].

### 2.3 Networking: in, out, and then transport as language
This is the most visible flip-flop in the record.
1. **2026-09-14.** "added tcp/ip inclusion and plan" [c:89a03c6986]. Networking was made core language: spec §20.4 rewritten, built-ins §22.17 [mem:silica-networking-core-language].
2. **By 2026-09-17, reversed.** "Networking is not part of the Silica language" [spec §20.4]. Sockets are reached only through Fifi in dangerous actors (ROADMAP chunk 9, "no TCP/IP stack is written"). The memory file warns future agents: "Do not cite the core-language design."
   - The same position settled a conflict with Project BEES, which wanted Silica's own TCP/IP. The ruling, *agent-recorded* (2026-10-23): on any conflict, "Silica wins and BEES's plan is what changes" [mem:feedback-silica-wins-over-bees].
3. **2026-11-05 to 08.** A third position: sockets stay foreign, but **transport** becomes language.
   - Spec §1.2 now opens: "**Important: transport is a full and equal citizen of Silica.** Data transport is a full behavior of modern computing devices, so it is built into the language and its compiler and checked by the effect system".
   - §20.4 adds: "Transport is part of the language even though sockets are not … A new wire protocol or carrier is an addition to this specification and to the compiler, never a program library."
- **Interview value.** This is a three-step "Why? / Why not?" sequence: why not networking? Why not a library? Why is transport different from sockets?

### 2.4 The data structures, built twice and then moved onto the stack
1. **May to June 2026.** A first standard data structures implementation, nine phases.
2. **2026-06-29.** All of it is deleted: "It was overly complicated for purpose." [c:df118756e3] A trait-oriented redesign follows, with locked algorithms: Adams weight-balanced trees, Brodal–Okasaki heaps, skew binary random-access lists, CSR graph snapshots [dd:Phase1_TODOs/bootstrap_retirement_and_self_host_plan.md "Authority"; slides:ds].
3. **2026-09-29.** The compiler's own adoption of those structures is withdrawn: "the compiler's further adoption of the standard structures … is no longer planned. The compiler keeps its lists and its index-arena `Expr`/`SIRTerm`" (same plan doc).
4. **2026-10-23.** The data structure redesign requirements are written "at Lee's request, after he said he is not happy with the current design of the standard data structures and wants it deeply revised as a chunk" [dd:data_structure_redesign_requirements.md header].
5. **2026-10-24.** The direction is chosen. Structures and every escaping value live on the actors' stacks, with state at the stack base. The never-freed "family arena" (Q2 (a), decided only two days earlier) is superseded.
- **Abandoned in this arc:** the first design; the compiler-adopts-stdlib plan; `arena(L, S)` (Q1); per-family arenas (Q2a); owner lists (Q5); linear region checks (Q11, E2303 to E2309); biased reference counting (decided 10-09, dropped by 10-24); `copy_to` (Q15, decision 34).

### 2.5 The heap nobody decided on (chunk 15's origin story)
- **The discovery.** While designing chunk 15, the author learned the runtime had a per-actor implicit heap (`_silica_rt_region_alloc`, 64 MB block chains freed only at actor end). The project's public claim, since April, had been: "**Memory is allocated in actor stacks, not heaps.**" [README at c:1ba815585c].
- **The memory file, *agent-recorded*.** "Lee believed everything was already stack-based; the implicit heap turned out to be a leftover of the first actor runtime (acf44039a4, 2026-04-07; reshaped in chunk 1, 7deb300926), never decided." [mem:silica-chunk15-stack-direction]
- **What was wrong with the old way** (author's commit, phase 2, 2026-10-27): "Until now anything that had to outlive a call was copied to a process-wide implicit heap by about thirty 'promote' sites and released by heuristics that guessed when a region was dead. The guesses were wrong in both directions: they leaked, and they freed memory that was still live." [c:19a7d19a48]
  - Earlier memory files say the same in agent language: "Scope release is unsound — mark/release_to frees live memory" [mem:MEMORY.md index].
- **The constraint the author set.** *Agent-recorded quotation* (2026-10-24), rejecting a BEAM-style threshold sweep: "This can not be similar to garbage collection. It must be completely deterministic and predictable." [mem:feedback-deterministic-memory-no-gc]
- **What it cost in memory.** The new model first made the compiler too large to run on a small machine, so the author set a target, *agent-recorded* (2026-10-28):
  - "The compiler is much too big when it runs; it must come down to roughly its pre-stack-model size so it runs on a Pi 5." [mem:feedback-compiler-memory-pi5]
  - The concrete target: under 4 GB physical footprint with no swapping beyond 30 seconds, measured on the self-build [dd:Phase3_memory_analysis.md §6].
  - Measurements after phase 3 stage 2 showed per-unit memory down 2.3x to 5.9x [dd:Phase3_stage2_analysis.md §1].
  - Proposed but not yet done: "split the compiler into more granular actors" [dd:Phase3_memory_analysis.md §7].

### 2.6 Message semantics: move, then copy, then "move copies too"
- **2026-10-09.** "when a message carries a data structure it is a MOVE, not a copy (chunk 4 Q6)", with biased counting for shared nodes [mem:silica-cast-exit-decision, bulleted log].
- **2026-10-23.** Q18 reverses the default: messages copy by default and move only on request [ROADMAP row 4].
- **2026-10-24.** "an explicit `move` copies too" (design §18.7). Decision 38: nothing in a message is shared with the sender [dd:data_structure_redesign_requirements.md changelog].
- **Same-day reversal (2026-10-09).** "a NO-OP CHANGE IS AN ERROR" was revised the same day: first to "ALLOWED", then to returning `:unchanged`. All three versions are kept in the memory log [mem:silica-cast-exit-decision]. This is a good illustration of thinking aloud with an agent.

### 2.7 How a program ends
- **2026-10-07, *agent-recorded*.** "Quiescence-based ending is UNACCEPTABLE: an idle program waits."
  - `cast_exit(status: uint8)` was introduced, revised the next day to `cast_exit(value: int64)`, with `wait_for_exit()` returning it [mem:silica-cast-exit-decision].
- **Then a change of mind, same day.** The memory records "Lee 2026-10-07 (changed his mind): ALL trials take the supervisor-actor pattern … on every platform."
  - The result was 22,251 trials rewritten by agents in about three days (item M, done 2026-10-10).

### 2.8 Threads per actor, then carriers
- **Before October 2026, hosted actors were OS threads.**
- **2026-09-19.** An agent proposed downgrading the "millions of actors" promise to a library. The author rejected it, *agent-recorded*: "The language keeps its promise: many actors per carrier thread, thousands to millions … Do not re-propose downgrading it." [mem:silica-placement-traits-direction]
  - Efficiency bar, *agent-recorded*: "the design must be as efficient as the BEAM, preferably MORE efficient".
- **2026-10-19.** 1,000,000 idle actors in 630 MB [c:7da327ec18]. Carriers become "the only execution model" [c:87e0a61e2e].

### 2.9 Effects move from functions to sequences
- **Before.** The founding notes put effects in function types: `proc[Effects] Type`, with "Effect aliases allowed" and monadic `do … end`.
- **2026-03-11.** `sequence … produces pure … end` blocks [c:caf8e02017].
- **2026-09-30.** The author ruled that "functions never declare effects". Converting the compiler's own 254 function-level annotations showed that "16 needed their effect … 238 turned out pure (callback parameter types carry no effect, so the old annotations were decorative)" [mem:feedback-silica-effects-only-on-sequences].
- **2026-10-11.** "Effects are local". Spec §9.3.1 rule 4 was rewritten from "Effect Propagation" (same file).
- **Abandoned.** Effect aliases. Later, all type aliases (spec §1.2 "No Aliases").

### 2.10 Smaller deletions and reversals worth a sentence
| Date | Change | Source |
|---|---|---|
| 2025-12-31 | "Removed generics for now". The spec now states "No Generics: Polymorphism achieved through traits" | [c:fb7a553edd; spec §1.2] |
| 2026-02-21 | "removed type casting from the silica specification". Hardened 2026-10-01, quoted below | [c:e7782fa5c3; mem:silica-no-type-conversions] |
| 2026-09-29 | Hot-swapping removed from the roadmap | [c:e75e299ccf] |
| 2026-10-16 | The `move(ref, from, to)` builtin removed in favour of `migrate_actor` | [ROADMAP chunk 2] |
| 2026-11-04 | Chunk 12, state-machine actors, removed | [c:d8835559c6] |
| — | Segmented actor stacks: "The segmented design this row once described is withdrawn" | [ROADMAP row 1] |
| 2026-11-05 | Transportable/Recreatable marker traits dropped hours after being designed | [c:31d648fd00] |

### 2.11 Hardware choices, each against an easier path
- **ESP32-S3, 2026-09-12** [mem:silica-esp32s3-port]: native Xtensa code generation rather than translating AArch64 output; bare metal with no ESP-IDF and no FreeRTOS; testing on the author's own BYU-I eBadge board rather than QEMU.
  - *Agent-recorded:* "He accepted that it is weeks of work and would not finish in one session. Do not re-propose the translation approach."
- **Direct access to everything, 2026-10-01.** *Agent-recorded quotation*: "There is to be direct access to all parts of the device. Even if there is a convenience function that is part of the board's implementation." [mem:silica-efficient-board-apps-plan]
- **STM32 flash, 2026-11-10.** *Agent-recorded rule*: "flash is NEVER used when running trials: it wears the flash out." [mem:silica-stm32-flash-execution-reserved]

---

## 3. How the development process worked

### 3.1 Trials as the gate
- **Correctness is defined by "trials".** Each is a small Silica program with golden assembly (`.ascomp`), golden output (`.scout`) or golden failure (`.golden_fail`).
- **Growth.** CI begins 2026-02-19. By the first fixed point there are "33,000+" trials [c:9285f53308]. By November, 35,073 pass on Linux x86-64 [ROADMAP row 15].
- **The definition of done** is a *fixed point*: "a build of the self-hosted compiler that passes the whole trial tree when built by itself (gen2) and reproduces itself byte for byte (gen3 = gen2)". Boards, which cannot host a compiler, have *board releases* instead [ROADMAP].
- **Goldens are never regenerated automatically, by design** [mem:silica-goldens-not-auto-regenerated].
  - On 2026-09-07, 366 apparent codegen regressions turned out to be debug comments. Regenerating would have baked them in.
  - Later rules let agents refresh `.ascomp` goldens without asking only when program output matches its hand-derived expectation [mem:feedback-ascomp-update-rule; mem:feedback-golden-refresh-without-asking].
- **Validate before fixing.** The defect-resolution plan requires every reported defect to get a failing trial first: "that red run is the validation that the defect is real" [dd:compiler_defects_resolution_plan.md, Ground rules 3].

### 3.2 Generated training corpora as a bug-finding tool
- **What was asked for.** On 2026-09-08/09 the author asked for about 10,000 and then another 10,000 trial pairs "as success/failure pairs for LLM training" [mem:silica-train-trial-pairs].
- **What it found.** Generating them exposed 10 silent miscompilations. One example: "Second float parameter is lost" — `fn f(x: float64, y: float64)` called with `(1.5, 2.25)` printed `0.0`. Another: `20 + (x + 1)` returned 41 instead of 26 [dd:HIGH_PRIORITY_…_2026-09-08.md; addendum 2026-09-09].
- **Status.** All items except closure environments (A2) were fixed by 2026-10-16 (same doc, status table). A2 is still open: a returned capturing closure is rejected with E1067 rather than implemented.

### 3.3 Machines
- An Apple Silicon Mac (16 GB) leads.
- `pix` is a Raspberry Pi running Linux AArch64. The first Linux fixed point was "on the Raspberry Pi" [c:8dcf493d49].
- `nix` is an Ubuntu Ryzen box, the x86-64 host [mem:silica-linux-x86_64-port].
- Boards: the BYU-I eBadge v4.0 (ESP32-S3), an ST NUCLEO-L476RG, and next a Raspberry Pi Pico 2 W.
- Memory pressure is constant. Compiler units peaked at 6 to 8 GB on the 16 GB Mac [mem:MEMORY.md index "Build memory pressure"]. This drove the rule of one building agent at a time (below).

### 3.4 Use of AI assistants (factual account)

**What the public policy says** [AI_POLICY, added 2026-04-27]:
- AI-assisted contributions are welcome under "zero tolerance" rules.
- "It is never acceptable to directly copy AI responses as if they were your own words!"
- "All work is the responsibility of the human who makes the PR. We do not accept AI as co-contributors on commits."
- "*If we want to talk to an AI, we will ask them ourselves*. We expect all interactions to be human interactions."
- Security reports must involve no LLM "in essentially any way".
- The "your own voice" rule applies to comments, PRs and issues, and explicitly not to "Code", "Documentation" or "Commit Messages".

**What the repository shows about the author's own process:**
- **From the first commit.** The compiler was planned with LLM-executable JSON-LD agent graphs (AALang/GAB, "silica-bootstrap-compiler-builder.jsonld") [c:322710bd20]. Later tools include `silica-spec-updater.jsonld` and `silica-error-message-improvement-tool.jsonld` [c:6440478e4c].
  - The policy itself says "The Silica project contains many agent (.jsonld) files. Their presence does not explicitly condone or request AI usage."
- **Language design names LLMs as a design goal.**
  - "LLM-Friendly and Human-Readable … This includes one way at the language level, no type aliases, explicit type annotations" [spec §1.2].
  - "Explicit syntax and types reduce ambiguity for humans and LLMs." [slides:intro 9]
- **Commit trailers.** About 220 of 686 commits carry `Co-Authored-By: Claude …` trailers, from 2026-03-18 [c:85510ad55a]. By trailer: Sonnet 5.5 (152), Haiku 5.5 (16), Opus 5 (15), Fable 5.1 (14), Fable 5.2 (8), Opus 5.5 (8), and a few 4.x models.
  - Merges such as "merge worktree-agent-ae684c103739140b4: codegen defect fixes" [c:fb87d4fd35] show agents working in separate git worktrees.
  - This sits beside the policy line "We do not accept AI as co-contributors on commits", which is addressed to contributors' PRs. That is a natural interview question (Q18 below).
- **About 180 working-memory files** (`.claude-memory/`) record decisions, traps and the author's rules for agents. Read together, they describe a coordinator session that delegates to models by task. All of the following are *agent-recorded*:
  - **Model by language.** 2026-09-24: "Use Fable for writing Silica code. Use a lesser model (Sonnet, or Haiku for mechanical work) for code in every other language". Reason given: "Lee watches token spend" [mem:feedback-model-by-language].
    - Restated 2026-10-05: "be careful using Fable. use it only for the difficult stuff. I'm running out of Fable tokens."
    - Restated 2026-10-09: "fable is to be used for compiler code changes. all other activities are to use lesser models as appropriate." [mem:feedback-fable-for-compiler-code]
    - 2026-10-24: if Fable tokens run out, "switch the compiler work to Opus".
  - **One builder.** 2026-10-24: "there is only to be one agent doing builds. There is insufficient ram otherwise." [mem:feedback-one-building-agent]
  - **The author builds the compiler himself at times.** "I'm compiling selfhost using seed for you. Don't do that." From 2026-09-24 the multi-hour fixed-point chains are "his to run, not mine, because an agent watching a multi-hour build burns tokens for nothing" [mem:silica-lee-builds-the-compiler].
  - **Board runs are the author's.** "Board runs are Lee's: nothing here is verified on the board until he builds the board compiler and runs the trials." [ROADMAP, ESP32-S3 board gap]
  - **Autonomy granted per phase.** For chunk 15 (2026-10-24, *agent-recorded* quotation): "when phase 0 passes, begin the remaining phases. after each passes, do the next." [mem:silica-chunk15-phase-run] Stops were still required for "design departures, golden changes … and for anything irreversible" [mem:feedback-phase-gate-autonomy].
  - **Correcting agents.**
    - "I don't want workarounds. Long-term fixes is what you are to do." (2026-09-10) [mem:silica-no-workarounds]
    - When an agent bulk-renamed 19 call sites to fix one reported error: "a general replace will cause other failures. Only replace this one instance." (2026-09-09) [mem:silica-fix-only-the-reported-site]
    - The author also rejected an agent's reasons for when code should check errors: "my first version said 'comes from outside / cannot prevent / something sensible to do', which Lee rejected as the wrong reason" [mem:silica-check-only-when-you-have-to].
  - **Commit style.** "the first part of the message states the overall purpose of the change. Do not list every change." (2026-10-26) [mem:feedback-commit-message-purpose-first]
- **The beginner's book tells readers to use an LLM.** Rule added 2026-09-19: "near the front, the book tells the reader to have an AI/LLM generate every program and never type code by hand … Exercises are phrased as 'ask your LLM for a program that …, then read and check it'." [mem:silica-learn-programming-actors-first]
- **The author's own editor plan.** `silica_KISS_design.md` designs a personal macOS editor with OpenRouter model switching: "intended primarily for personal use … a small, purpose-built development cockpit".

---

## 4. "Why?" and "Why not?" moments

Each is an instance where a default was questioned ("Why do we do it this way?") or a refusal was chosen ("Why not X?" — and the answer was no, with a reason).

1. **Why does the compiler optimize "almost right" code instead of rejecting it?**
   - Silica rejects it: dead bindings, duplicate computation, redundant algebra, loop-invariant work.
   - "This is not optimizer worship. It is a demand that intent be visible." [slides:intro 7; README]
2. **Why have a garbage collector? Why a heap at all?**
   - "No heap-shaped nostalgia … No GC Region lifetime does the cleanup work. … Provocative claim: performance is easier to trust when allocation policy is not hidden." [slides:intro 6]
   - Then the October discovery that a heap had crept in, and the "Why is this here?" that started chunk 15 (§2.5).
3. **Why not something GC-like, just a little?** "This can not be similar to garbage collection. It must be completely deterministic and predictable." (*agent-recorded*, 2026-10-24) [mem:feedback-deterministic-memory-no-gc]
4. **Why not type conversions?** "silica is not to have any data type conversions. This part of the fundamental design." (*agent-recorded*, 2026-10-01). The rule: "the value should be produced in the needed type at its source" [mem:silica-no-type-conversions].
5. **Why not type aliases, even to tame huge signatures?**
   - "Structural types written out in full at each boundary is a deliberate design choice, not an accident to be optimised away." [mem:silica-no-type-aliases]
   - The public reason: "the shape is written at the use site so readers and models do not unwind alias definition sets" [spec §1.2].
6. **Why loops? Why generics?** "One Way at the Language Level: Each job has one language-level construct … No Loops … No Generics" [spec §1.2]. The founding note says "No loops. Recursion only." [design_notes.md, c:322710bd20]
7. **Why model 1970s machines?** "Designed for Modern Chips: First-class support for what current hardware actually exposes … not a portable 1970s machine model" [spec §1.2]. The April README says the same: "not to a nostalgic picture of how chips and computers used to work" [README at c:1ba815585c].
8. **Why should an idle program exit?** It should not. "Quiescence-based ending is UNACCEPTABLE: an idle program waits." (*agent-recorded*) [mem:silica-cast-exit-decision]
9. **Why have defaults?** For actor placement, *agent-recorded*: "NO DEFAULTS (Lee): the program always names its striping and moving options explicitly … docs give a decision table, never a default." The same holds for the required `stack_policy(...)` and `state_policy(...)` spawn arguments [mem:silica-placement-traits-direction; ROADMAP rows 1, 15].
10. **Why not shrink the promise of millions of actors to a library?** "Do not re-propose downgrading it." (*agent-recorded*). One month later: 1,000,000 actors in 630 MB [c:7da327ec18].
11. **Why check for errors?**
    - Only when "(1) the failure would corrupt data … (2) the failure happens frequently and the fail-and-restart cost slows the application. In every other case: no check; let the actor fail, the supervisor restarts it fresh" [mem:silica-check-only-when-you-have-to].
    - Spec rationale for debug mode: "crashing immediately and noisily reveals bugs faster than silently recovering." [spec §15.4.15.1]
12. **Why call when you can cast?** "Cast and cast back mimics texting / social media: few people send a text and wait idle for the answer" (*agent-recorded*) [mem:silica-cast-over-call].
13. **Why is `main` big?** "Well designed silica applications have a very small main function … The last line in main's sequence is almost always wait_for_exit()." (*agent-recorded* quotation, 2026-09-19) [mem:silica-small-main-rule]
14. **Why build big nested types?** "Large types composed of many items and layers are naive and inefficient. Instead, the first-class data structures are to be used." (*agent-recorded* quotation, 2026-09-19) [mem:silica-use-first-class-data-structures]
15. **Why should functions declare effects?** Converting showed 238 of 254 were "decorative". After that, "Effects are local" [mem:feedback-silica-effects-only-on-sequences].
16. **Why does this 9-phase data structure library exist?** "It was overly complicated for purpose." Deleted [c:df118756e3].
17. **Why does the compiler need the standard structures internally?** It does not. Withdrawn 2026-09-29 [dd:Phase1_TODOs/bootstrap_retirement_and_self_host_plan.md].
18. **Why work around a miscompile?** "I don't want workarounds. Long-term fixes is what you are to do." [mem:silica-no-workarounds]
19. **Why not just translate the ARM assembly to Xtensa? Why not use the vendor SDK? Why not QEMU?** No, no, and no: native code, bare metal, the real board [mem:silica-esp32s3-port].
20. **Why are sockets foreign but transport native?** Spec §20.4 and §1.2 (see §2.3 above). A further "why not": "Why does a carrier not name its hardware?" led to `carried_on` links, since "the host carriers hide interface choice in the OS, a board has none" [mem:silica-transport-links-decisions].
21. **Why not hot code swapping, the BEAM's signature feature?** Removed from the roadmap 2026-09-29 [c:e75e299ccf]. Rationale not recorded: ask.
22. **The talk's closing questions** are a ready-made "Why not?" manifesto: "Treat systems programming as a design problem again. What should the compiler refuse? Where should the runtime isolate failure? How should modern hardware and tools shape source language design?" [slides:intro 11]

---

## 5. Interview leads (24 questions)

1. The founding strategy budgeted "6-9 Months" for a Rust/LLVM bootstrap [`AArch64/bootstrapping.md`, c:322710bd20]. By mid-January you were planning the Silica-written compiler [c:6440478e4c]. What made it go so much faster than planned, and what did you skip?
2. Your first commit included AALang/GAB agent graphs that instruct an LLM to "Act as if you ARE the GAB agent" [c:322710bd20]. What role did those play in writing the Rust bootstrap, and why did you design the process that way from day one?
3. The original notes say "Syntax optimized for structured readability and robustness for LLMs. Erlang-like instead of Lisp-like." [design_notes.md]. Why was LLM-readability a founding goal in December 2025, and has that goal changed how you write the language?
4. On 2026-02-16 the Silica-written compiler produced a working `fn main(){ 42 }` [c:d1761ba0d3]. What did that day feel like, and why go straight to AArch64 assembly instead of keeping LLVM?
5. "No C interop" was a founding principle, yet by May you built Fifi and named everything around it `dangerous_*` [c:e69024a5cb; slides:intro 8]. What forced the change, and was the danger naming a way of keeping the original principle in spirit?
6. On 2026-06-29 you deleted the whole first data structure implementation: "overly complicated for purpose" [c:df118756e3]. What was the moment you knew, and how hard was it to throw away a month of work?
7. The commit for the first self-hosted binary ends "and, of course, compiles itself" (2026-07-31) [c:25cc8c89e9]. Later documents date self-hosting to the 2026-09-12 fixed point [dd:Phase1_TODOs/bootstrap_retirement_and_self_host_plan.md]. Which date do you consider the real one, and why?
8. The self-host blocker turned out to be a pointer into the compiler's own atom table that decoded as the text "ciency\0:" [mem:silica-selfhost-bootstrap-blocker]. Was there a lowest moment in the summer of out-of-memory kills, and what kept you going?
9. On 2026-09-17 the Rust crate was deleted in the same commit as the Raspberry Pi fixed point [c:8dcf493d49]. Was deleting it a celebration, a relief, or a risk you hesitated over?
10. You asked for about 20,000 trial pairs "for LLM training" [mem:silica-train-trial-pairs]. Generating them uncovered silent miscompilations such as `20 + (x + 1)` giving 41 [dd:HIGH_PRIORITY_…addendum_2026-09-09.md]. Was finding bugs part of the plan or a surprise? What is the training set for?
11. Networking went into the core language on 2026-09-14, out by 2026-09-17, and transport came back as "a full and equal citizen" in November [c:89a03c6986; mem:silica-networking-core-language; spec §1.2, §20.4]. Walk me through the three positions. What did you learn between each?
12. The README had promised since April that "Memory is allocated in actor stacks, not heaps" [README at c:1ba815585c]. Then you found an implicit heap that was "never decided" [mem:silica-chunk15-stack-direction]. How did you find out, and how did it feel to learn your own runtime contradicted your pitch?
13. You wrote that the old release heuristics "were wrong in both directions: they leaked, and they freed memory that was still live" [c:19a7d19a48]. Why replace heuristics entirely rather than fix them? And why is "nothing resembling garbage collection" non-negotiable [mem:feedback-deterministic-memory-no-gc]?
14. In about three days (22–24 Oct) you made roughly 40 numbered memory decisions, several reversing ones from two days earlier [dd:data_structure_redesign_requirements.md §2A]. What does decision-making at that speed look like from your chair? How do you know when a decision is final?
15. Messages went from move (10-09) to copy by default (10-23) to "move copies too" (10-24) [ROADMAP row 4; mem:silica-cast-exit-decision]. What argument finally convinced you that copying was right?
16. An agent proposed turning "millions of actors" into a library, and you refused [mem:silica-placement-traits-direction]. A month later carriers held 1,000,000 actors in 630 MB [c:7da327ec18]. Why did you hold that line, and why measure yourself against the BEAM specifically?
17. "There is to be direct access to all parts of the device. Even if there is a convenience function" [mem:silica-efficient-board-apps-plan]. Why does direct hardware access matter so much to you? And why bare metal on the ESP32-S3 instead of ESP-IDF, accepting "weeks of work" [mem:silica-esp32s3-port]?
18. AI_POLICY.md says "We do not accept AI as co-contributors on commits" and "If we want to talk to an AI, we will ask them ourselves" [AI_POLICY]. About 220 of your own commits carry Claude co-author trailers. How do you reconcile the policy for contributors with your own practice, and where do you draw the line between using a tool and sharing authorship?
19. The working memory records you rationing models: "use it only for the difficult stuff. I'm running out of Fable tokens." [mem:feedback-model-by-language]. Also "only one agent doing builds" [mem:feedback-one-building-agent]. What did directing a team of models teach you about management, and about your own role?
20. "I don't want workarounds. Long-term fixes is what you are to do." [mem:silica-no-workarounds] and "Only replace this one instance." [mem:silica-fix-only-the-reported-site]. Were these frustrations with AI behaviour specifically, or principles you would give any human contributor?
21. Your beginner book tells readers "to have an AI/LLM generate every program and never type code by hand" [mem:silica-learn-programming-actors-first]. Why teach programming that way, and what does a beginner still need to understand?
22. You removed hot-swapping, inbound FFI and state-machine actors from the roadmap [c:e75e299ccf, c:269c870e4b, c:d8835559c6]. What is your test for saying "no" to a feature, especially one the BEAM is famous for?
23. "Silica has no data type conversions … fundamental design" [mem:silica-no-type-conversions] and "no type aliases" [spec §1.2]. What is the oldest "Why not?" in Silica? Which refusal are you proudest of, and which one most often draws pushback?
24. The talk closes with "What should the compiler refuse?" [slides:intro 11]. If you could ask one "Why?" of the whole systems programming field, what would it be? Is there a "Why not?" about Silica itself that you are still sitting with (for example the open closure-environment decision, A2, in [dd:HIGH_PRIORITY_…_2026-09-08.md])?

---

## Appendix: quick reference of key artifacts

- First commit (Rust bootstrap, LLVM, agent graphs): `322710bd20` (2025-12-26).
- Silica-written compiler's first executable: `d1761ba0d3` (2026-02-16).
- Going public (README, licensing, motto): `290d6e823d` and `88cb979dc2` (2026-04-09/12).
- AI policy: `5f7c7d269b` (2026-04-27).
- First standard data structures deleted: `df118756e3` (2026-06-29).
- First self-hosted binary: `25cc8c89e9` (2026-07-31).
- First fixed point: `9285f53308` (2026-09-12). Apple FP1 `8aff9cdc5a`. Linux AArch64 FP1 plus Rust removed `8dcf493d49`. Linux x86-64 FP1 `e8274292ee`.
- Million actors: `7da327ec18` (2026-10-19).
- Chunk 15 phase 2 manifesto commit: `19a7d19a48` (2026-10-27).
- First merged PR #42: `82b9bad5c0` (2026-10-25).
- STM32 Nucleo target: `e2fabdd3ef` (2026-11-07). RP2350 directory: `aff91a6cd7` (2026-11-12).
- Talk deck: "Silica: A functional systems language for modern chips, modern tools, and honest boundaries — Erlang Workshop 2026" (pptx, file date 2026-08-18; not tracked in git).
