# Chapter map: *The Tao of Silica*

Which material belongs in which chapter. Used by the `ghostwriter` skill and for
drafting. Citations are to the research notes in this folder:

| Short | Note |
|---|---|
| CORE | `silica-core-principles.md` |
| SPEC | `silica-specification-rationale.md` |
| SUB | `silica-subsystem-principles.md` |
| HIST | `silica-history.md` |
| SEC | `precursors-security-article-and-semp.md` |
| SWB | `precursors-swerl-and-bees.md` |

The order puts the questions first, then the story, then the ten principles.
Changing the order only means changing the `\input` lines in `main.tex`.

## Cautions for drafting

- **Ideas and opportunities, not how-to (author's instruction).** The book is
  about the ideas behind the code and what the design opens up, not how to
  write Silica. Principle chapters follow: the idea → where it came from →
  what it costs → what it opens up. The technical facts in these notes are
  evidence, not content to teach.
- **The quotation rule (author's instruction).** The author is never quoted in
  chapter body text, whether from interviews or from their own documents.
  Paraphrase in the body; short quotes only in footnotes, with the source.
  Full statements stay in `interviews/`. See the `ghostwriter` skill.
- **Foreign-code crashes (author correction, 2026-11-13).** A recognised fault
  in C code running in a guarded dangerous actor ends *that actor only*; its
  supervisor restarts it, and the application carries on
  (`dangerous_ffi_security_model.md` 217, 243–244; implemented on macOS and
  Linux with trials). The whole process stops only for faults outside the
  guarded boundary or undetectable/runtime corruption. Don't describe a C
  crash as taking the whole program down.
- **Agent-recorded quotes.** Many quotes in HIST come from `.claude-memory`
  files that AI agents wrote while working with the author. Don't print them as
  the author's words until the author confirms them in interview. In the
  `.tex` files they carry a `% TODO-VERIFY` comment.
- **Designed is not built.** Many subsystem designs are not implemented yet:
  actor capabilities, brokered IPC, IPC_OS/RTOS, TLS, the crypto proposal, most
  of the anti-optimizer rules (only E1055 exists). See the appendix of SUB.
  Chapters must say so.
- **Two "phase" vocabularies.** Phase 1/2 of the *compiler* (the Rust bootstrap,
  then the compiler written in Silica) are different from Phases 2–8 of the
  October 2026 *memory redesign* (chunk 15). See HIST "How to read".
- **Open dates.** BEAM_SEMP's last commit is 2025-10-09 (SWB) or 2025-10-31
  (SEC). The additional-rules spec is dated 2025-02-12, possibly a typo.
  Settle these in interview.

---

## Part I — The Questions and the Story

### Chapter 1. Why? and Why Not?
The book's spine. The habit of asking *Why?* of accepted practice, and then
*Why not?* when it was time to build something different.
- 2024 "Unsafe Impedance" (Erlang '24): "memory safe" is "necessary but
  insufficient"; "there are no secure by default languages that have infinite
  unsafe impedance" (SEC §1).
- The catalogue of *Why?* questions: GC, loops, generics, type names,
  optimizer clean-up, 1970s machine models, exceptions, `if`, defaults (CORE §2;
  HIST §4; SUB Part 3).
- The *Why not?* turns: why not move the UAP into a compiler; why not stop
  patching the BEAM and own the runtime; why not build my own (SEC §4.2;
  SWB §4).
- The talk's closing questions: "What should the compiler refuse?" (HIST §4.22).
- *Why?* turned on Silica itself: the heap nobody decided on (HIST §2.5); the
  reversals as evidence that the questions keep being asked.

### Chapter 2. How We Got Here
The history, told as eras.
- Before Silica: SwErl 2023–2025 (SWB §1); "Unsafe Impedance" 2024 (SEC §1);
  BEAM_SEMP 2025 (SEC §2).
- Era 0: the Rust bootstrap and LLVM, 26 Dec 2025 (HIST Era 0).
- Era 1: the compiler written in Silica; `fn main(){ 42 }`, 16 Feb 2026;
  actors, going public, Fifi, data structures torn down (HIST Era 1).
- Era 2: self-hosting; fixed point 12 Sep 2026; Rust deleted 17 Sep (HIST Era 2).
- Era 3: many targets; carriers; 1,000,000 actors (HIST Era 3).
- Era 4: the memory reckoning, chunk 15 (HIST Era 4).
- Era 5: transport, boards, BEES (HIST Era 5; SWB §2).
- How the work was done: trials as the gate; AI assistants; the author
  deciding (HIST §3).

## Part II — The Principles

### Chapter 3. Honesty — *Hide Nothing*
The meta-principle: intellectual honesty.
- "the world's most intellectually honest, secure language" (CORE §0, §1.9).
- The named "nothing-hidden rule" (SPEC P9; SUB Part 2 #5).
- No defaults (HIST §4.9, agent-recorded).
- Honest limits: hosted `mem(Space)`, "not a sandbox", plain TCP, status
  blocks in every design doc (CORE §1.17; SUB Part 2 #7; SPEC P13).

### Chapter 4. Transparency — *Say What You Do*
- Explicit, local effects on `sequence` blocks (CORE §1.1; SPEC P1).
- Process monad (CORE §1.2).
- Heap is an effect (CORE §1.6; SPEC P2).
- History: effects moved from function types to sequences; 238 of 254
  annotations "decorative" (HIST §2.9, agent-recorded).

### Chapter 5. Independence — *Share Nothing*
- Isolation and messages; no `actor` keyword; the runtime owns the loop
  (CORE §1.3; SPEC P3, P7).
- Lineage: Erlang, and SwErl's lessons (SWB §1.5, §3).
- Cast and cast back; messages copy (HIST §2.6; SUB 1.2).
- Millions of actors; carriers; pinning; the runtime never moves an actor
  (HIST §2.8; SPEC P8).

### Chapter 6. Resilience — *Fail Gently, Never Silently*
- Let it crash; supervisors; the elephant mother (CORE §1.3a, §1.11).
- Check only when failure corrupts data or is frequent (HIST §4.11).
- "Crash to the supervisor" (SUB 1.5); reports can't be suppressed (SPEC P9).
- Unbounded growth; the program that chose the limit owns the failure (SPEC P10).
- The motto's evolution (CORE §3.3 #4).

### Chapter 7. Predictability — *Leave Nothing to Chance*
- Regions; references stay with their region; no GC (CORE §1.4–1.5; SPEC P2).
- The October reckoning: the heap nobody decided; the rejected alternatives
  (SUB 1.1; HIST §2.4–2.5).
- Everything on actor stacks; deterministic, compiler-proven release.

### Chapter 8. Simplicity — *One Way to Do Each Thing*
- One construct per job: no loops, no generics, no type names, no
  conversions, no bare `_`, no `if` (CORE §1.8; SPEC P4–P6; HIST §4.4–4.6).
- Written for people and LLMs; the AI as typist, the human as judge
  (CORE §1.8, §1.19).
- KISS as temperament (CORE §1.20).

### Chapter 9. Accountability — *Make Danger Visible*
- Unsafe impedance and the UAP (SEC §1).
- From process to compiler: Fifi, `dangerous_*`, `external_danger`, taint,
  install vs execute, no inbound FFI (CORE §1.12; SUB 1.3; SEC §3).
- SEMP's lessons: atoms fixed at build time; no code loading (SEC §2–3).
- Capabilities (designed, not built) (SUB 1.2).

### Chapter 10. Rigor — *Refuse the Almost Right*
- Reject "almost right" code; no escape hatches (CORE §1.10). **Design only
  except unused values (E1055); author flagged 2026-11-14 that the chapter must
  present it as not yet implemented.**
- The compiler writes the dangerous parts (SUB Part 2 #6).
- One compilation unit; libraries are source (CORE §1.13).
- Proof through types (CORE §1.14).
- Trials as truth; the fixed point (CORE §1.16; HIST §3.1).

### Chapter 11. Fidelity — *Respect the Machine*
- Not "a portable 1970s machine model"; the PDP-11 critique (CORE §1.7; SPEC P14).
- No LLVM: the compiler reasons about chip-shaped facts (HIST §2.1).
- Bare metal first: ESP32-S3, STM32, Pico (HIST §2.11).
- Hosted targets, honestly bounded; same rules on every port; measure first
  (CORE §1.17; SUB Part 2 #9, #11; SPEC P17).

### Chapter 12. Connection — *Speak Across Every Boundary*
- The long road to the network: SwErl Node, SEMP/TRUST (SWB §1; SEC §2).
- Networking in, out, and transport as language (HIST §2.3; SPEC P13).
- Closed sets; decoding is validation; ETF; speaking Erlang (SPEC P13).
- BEES: "possible, not easy"; TRUST rebuilt on Silica (SWB §2).
