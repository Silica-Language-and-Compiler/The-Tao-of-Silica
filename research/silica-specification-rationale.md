# Research Notes: Rationale in the Silica Language Specification

**Source:** `/Volumes/2T/silica/compiler/design_documents/silica-specification.md` (16,718 lines, about 806 KB).
**Cited as:** `spec:L<line>`. Section numbers (§) are the spec's own.
**Scope:** the reasons behind the design (goals, philosophy, exclusions, superseded designs). Grammar details are left out.
**Prepared:** 2026-11-13.

---

## 1. Outline of the specification

The spec opens with a "Related Documents" table (L3–L19). It points to separate documents for compile-time failure rules, actor capabilities, **Fifi** (the FFI layer), macOS crash handling, the memory `Space` model for OS-free AArch64, OS-free porting, device actors, transport and links, and a "future development" document on quantum-safe TLS. The 30 numbered chapters follow:

| § | Title | Line |
|---|---|---|
| 1 | Introduction (Overview, **Design Principles**, **LLM-Friendly Design Principles**, Target, Compiler Interface, Error Messages) | 21 |
| 2 | Lexical Structure | 215 |
| 3 | Syntax (incl. 3.4.2 "Types are inline only", 3.4.6/3.4.7 superseded struct/enum, 3.3.5 "`if` only in case guards") | 419 |
| 4 | Built-in Types | 2998 |
| 5 | Built-in Functions and Primitives | 3468 |
| 6 | Language Features (incl. a legacy 6.2 "Exception Handling") | 3739 |
| 7 | Basic Expressions | 4032 |
| 8 | Type System (no structural subtyping, no inference) | 4118 |
| 9 | **Effect System** | 4749 |
| 10 | Type Checking | 5727 |
| 11 | Process Semantics and Execution (process monad) | 5972 |
| 12 | **Memory Model** (regions, OS-free vs OS-hosted) | 6105 |
| 13 | Operational Semantics | 7138 |
| 14 | Safety Properties | 7283 |
| 15 | **Actor Model Semantics** (lifecycle, stacks, pinning, supervision, crash containment, state machines) | 7412 |
| 16 | **Message Passing** (call/cast, mailboxes, backpressure, **Wire Transport**) | 9845 |
| 17 | Atomic Operations | 10892 |
| 18 | Synchronization Guarantees (incl. Deadlock Freedom) | 11371 |
| 19 | Module System | 12005 |
| 20 | Standard Library (20.4 Networking: "not part of the Silica language") | 12501 |
| 21 | Architecture-Specific Modules (SVE, NEON, MTE, PAC, Apple Silicon) | 12726 |
| 22 | Built-in Functions | 14836 |
| 23 | Runtime System (incl. Capability System) | 15365 |
| 24 | Implementation Requirements | 15493 |
| 25 | Error Handling | 15565 |
| 26 | Platform Integration (incl. 26.3 **Fifi**, 26.4 Performance claims) | 15682 |
| 27 | Compilation and Linking ("Chip-Centric Compilation Strategy") | 15998 |
| 28 | Compiler Infrastructure (multi-pass, constraint-propagation parser) | 16529 |
| 29 | IDE & Developer Experience | 16622 |
| 30 | Advanced Type System | 16697 |

**What the text is like.** Two layers of writing sit side by side.
1. **Newer, normative prose.** It is precise and dated, often tagged "Implementation status (YYYY-MM-DD)" or "Decided by Lee, YYYY-MM-DD", and it covers §12.1.2, most of §15, §16.4 and §17.1.
2. **Older, aspirational or legacy text.** Examples are §6.2 exception handling, the Result examples in §23.3.2 and §25, and the performance claims in §26.4. Some of it contradicts the newer principles (see §4 and the interview leads below). That contrast is useful for the HISTORY chapter, because it shows the design moving.

---

## 2. Principles embodied in the spec

The spec states eleven design principles at L26–L42, plus a "transport is a full and equal citizen" banner. Other principles appear by name further in: the "nothing-hidden rule", BEAM-style containment, and "decoding is validation". Each entry below gives the idea, the spec's reasoning, verbatim quotes and the alternatives it turned down.

### P1. Explicit effects: side effects belong in the program text

- **Idea.** Every side effect is declared with `proc[...]`. Declarations go on `sequence` blocks, never on function signatures.
- **Quotes.**
  - "**Explicit Effects**: All side effects are tracked in type signatures" (L30).
  - "**Critical Rule: Function signatures do NOT declare effects.** All effect declarations must appear on `sequence` blocks within the function body. This applies to **all** functions, including behavior functions." (L1625)
  - "**Benefit**: Makes side effects visible to both LLMs and humans, enabling better code analysis" (L88).
- **Effects are local, not transitive.** This choice is distinctive.
  - "**Effects Are Local**: A sequence block declares only the effects of its own operations. Calling a function never adds that function's effects to the caller: the callee's own sequence block declares and discharges them. A caller that declares an effect only because a callee uses it gets E3010 (unused effect declaration)" (L4908).
  - The one exception: "**Exception, `register_rwr`:** a function whose body holds a `register_rwr` sequence reaches a device, so every caller must also declare `register_rwr`. This keeps device access out of `main` and ordinary behaviours transitively" (L4916).
- **Alternatives rejected.**
  - Effect annotations on signatures (shown as "✗ WRONG", L1629–L1631).
  - Transitive effect propagation of the Koka or Java checked-exception kind. The spec rejects it for every effect except device register access.
  - Declaring effects "just in case" is itself a compile error (E3010).
- **Effect vocabulary as a picture of the hardware.** `mem(Space)` comes in cache-policy variants (write-back, write-through, non-cacheable, atomic, device). There are also `concurrency`, `atomic`, `device_io`, `network_io`, `hot_swap` ("On AArch64, requires `ISB` barrier", L4766), `register_rwr`, `external_danger` and `transport` (L4756–L4769). Effects name what the chip actually does.

### P2. Heap is an effect, and regions replace both GC and the implicit heap

- **Quotes.**
  - "**Region-Based Memory**: Safe memory management without garbage collection" (L32).
  - "**References Stay With Their Region**: A `ref` or `buf` is never separated from the region that contains the memory it refers to; the region's lifetime is part of the reference type" (L33).
  - "**Heap Is an Effect**: Allocating or growing region-backed storage is a `mem(<space>)` effect on a sequence, not an invisible runtime service" (L34).
  - "**Allocation Strategy:** A region is an area in the stack frame of the function that executes `alloc_region`, not a heap block (Lee, 2026-11-01; chunk 15 phase 4e; the implicit heap is removed on the hosted targets, while the Linux and ESP32-S3 targets keep the heap until chunk 15 phases 8 and 9)." (L6643)
- **Guarantees claimed** (§14.1, L7287–L7317): no null pointers ("No implicit null values", L7291), no dangling pointers, and no use-after-free ("Attempting to use a reference after its region is deallocated is a type error", L7309).
- **Alternatives rejected.**
  - Garbage collection ("**Garbage-Free**: No garbage collection - explicit region deallocation", L15399).
  - A hidden general heap, removed on 2026-11-01.
  - Rust-style per-value borrow lifetimes. Here the lifetime belongs to the *region*, and references carry it in their type: `ref(L, Space, T)`.

### P3. Ownership moves; no sharing between actors (with one named exception)

- **Quotes.**
  - "**No cross-actor sharing:** A region is **owned by at most one actor at a time**; actor communication transfers ownership by **message moves**, not by shared mutable heaps. The one named exception is the atomic region `region(L, atomic)`: application-lifetime and copyable, it holds only word-scalar atomic cells and may be shared by actors on every target (§17.2.4)." (L7033)
  - "**Spawner releases ownership**: The spawner no longer owns or can access the region after the `spawn` call." (L7012)
  - "**A buffer is not a message part.** A `buf(...)` value is created, used and deleted inside a dangerous actor ... it never crosses an actor message boundary" (L7029).
  - On replies: "the reply path is not a second, hidden copy" (L7031).
- **Alternatives rejected.** Shared mutable heaps, and copy-on-send as the only option (Erlang copies messages; Silica *moves* region ownership). The single exception, atomic cells, is named explicitly rather than allowed by accident.

### P4. One way at the language level (the LLM-friendly principle)

- **Idea.** Each job has exactly one construct. Variety comes from composing constructs, not from choosing among synonyms. The spec states two audiences outright: large language models and humans.
- **Quotes.**
  - "**LLM-Friendly and Human-Readable**: Syntax and semantics designed to be easily parseable by Large Language Models while remaining intuitive for human developers. This includes one way at the language level, no type aliases, explicit type annotations, unambiguous syntax patterns, consistent naming conventions, and clear structural patterns that reduce ambiguity in both automated analysis and human comprehension." (L37)
  - "**One Way at the Language Level**: Each job has one language-level construct; programs vary by composing those constructs. This keeps generation choices at the composition layer." (L38)
  - "One way at the language level is part of that: generators choose how to compose constructs, not which of several primitives to use for the same job." (L46)
- **What follows from it.**
  - "**No Loops**: Recursion only; runtime handles internal looping" (L39).
  - "**No Generics**: Polymorphism achieved through traits, not generic type parameters" (L40).
  - No `if`/`else`: "Silica has **no** standalone conditional expression or statement using `if` with `else` ... The keyword **`if`** appears **only** in **case branch guards**" (L2129–L2131). The spec shows the replacement: `case divisor == 0 of { true -> -1; false -> 100 / divisor }` (L2142–L2145).
  - No special actor syntax: "There is no special actor definition syntax (no `actor`, `handler`, or `impl Actor` keyword). Actors are created by passing ordinary functions to `spawn()`." (L7488) Also: "**No Actor Type**" (L7532).
  - No selective imports: "No selective imports - all exports are imported" (L12064).
  - No `sleep`: "There is no `sleep`. Nothing blocks a dispatch waiting for time to pass" (L15305).
- **Alternatives rejected.** Loops, generics, `if/else`, actor keywords, `sleep`, selective imports, and multiple synonyms for one job.

### P5. Types are concrete, inline and explicit: no aliases, no custom types, no inference

- **Quotes.**
  - "Silica **does not** provide **custom types**: declarations that introduce a **new user-defined type name** are absent. There is no `type Ping = …`, no `struct Ping { … }`, and no `enum` that binds a fresh type identifier for application code. **Composite types are always structural and written inline**" (L1681).
  - "**No Aliases**: No type aliases or user-declared type names; the shape is written at the use site so readers and models do not unwind alias definition sets" (L42).
  - "**Benefit**: LLMs and humans do not get lost in deep or circular alias definition sets; the type in source is the type that is meant" (L99).
  - "There is no type inference - every variable binding, function parameter, and return type must have an explicit type annotation." (L4728)
  - "Silica has **no generic type parameters** (§1.2): there is no `Option<T>` or `Result<T, E>` in the type system." (L71). Option and Result shapes are written inline as `Some(int64) | None` and `Ok(int64) | Error(string)` (L72).
  - "**Benefit**: Every type occurrence is syntactically concrete, which avoids generic-inference ambiguity and keeps parsing and reading straightforward for tools and humans." (L75)
  - "Silica has no structural subtyping - all types must match exactly." (L4150)
  - Even catch-alls carry a type: "`_: int64 -> 0` (not just `_ -> 0`)" (L52).
  - Function literals must declare a return type: "A literal without one is rejected (error E1071); its type is not inferred." (L2155–L2156)
- **Alternatives rejected.** `struct` and `enum` declarations, which survive only as "superseded" sections (L1716, L1735; see §4). Also type aliases, generics and type inference.

### P6. Exhaustiveness and "no silent fall-through"

- "Pattern matches over `boolean`, atom and sum types must be exhaustive ... a `case` over an integer type ... or `string` must **end with a catch-all arm** ... guards never replace the catch-all arm." (L2305–L2307)

### P7. Actors are the unit of concurrency, modeled on OTP but compiled native

- **Quotes.**
  - "**Actor-Based Concurrency**: Message passing as primary concurrency mechanism" (L31).
  - "Each actor follows a **gen_server-style** model (cf. Erlang `gen_server`): a **non-recursive** behavior function is invoked **once per message** by the runtime. The **infinite loop** lives only in the runtime, not as a user-written tail-recursive receive loop." (L7539)
  - On `recv()`: "they **never** call `recv()` directly. The `recv()` function is not user-callable and is an internal runtime operation." (L7576)
- **Rationale given for non-recursive behaviors** (L7582–L7586):
  > "- Each message invokes the behavior exactly once
  > - Recursion would complicate stack management and predictability
  > - The runtime owns the message loop; user code does not implement recursion over messages
  > - If recursive logic is needed, structure it as non-recursive message-driven state machines"
- **Call/cast discipline.** "A behavior function's return type **must not** be a union of `(:reply, ...)` and `(:no_reply, ...)` forms." (L7555)
- **OTP mapping, stated explicitly.**
  - State-machine actors are "Silica's counterpart of Erlang/OTP's `gen_statem`, as gen_server-style behaviors (§15.1.2) correspond to `gen_server` and the `Supervisor` trait (§15.4.13) to `supervisor`" (L9755).
  - `FailureReporter` is "analogous to OTP's Logger" (L9535).
  - `:add_child` is "the Silica analogue of Erlang/OTP's dynamic child-start operation ... There is no public `spawn_linked` path and no ad-hoc linked child that bypasses the child table." (L9529)
- **Alternatives rejected.** Erlang's hand-written `receive` loops, user-callable `recv`, a separate actor syntax, and ad-hoc process links. In the Erlang lineage, Silica keeps OTP's *behaviours* and drops the raw primitives.

### P8. Pinning and no runtime magic: the program decides where actors run

- **Quotes.**
  - "Every actor is **pinned** to a core from the moment it is spawned until it terminates." (L7590)
  - "**No runtime movement**: the runtime **never** moves an actor on its own: not for load balancing, thermal throttling, core parking, power management, NUMA locality, or region allocation. A program that wants any such policy implements it with `migrate_actor()`." (L7596)
  - "Between yield points an actor is never preempted. A program that wants long computation to share its core ends its dispatch early and continues the work by sending itself a message with `cast(self(), …)`" (L7601).
  - "`unpin_actor` is not part of the language: an actor has no unpinned state." (L15224)
- **Honesty about the host.** "Apple Silicon macOS offers no hard thread-to-core binding ... Exclusive or hard placement is therefore **not** guaranteed on an OS-hosted target. On such a target `migrate_actor()` transfers the actor between carrier threads, as the BEAM migrates processes between its scheduler threads." (L7607)
- **Alternatives rejected.** Preemptive scheduling, which the BEAM uses through reduction counting. Also work-stealing and load balancing done by the runtime. This is a sharp break from Erlang/BEAM: Silica gives placement policy to the programmer.

### P9. The "nothing-hidden rule"

The phrase appears by name twice in §15.1.2.2. It works as a meta-principle tying together P1, P2 and P8.
- "Every spawn form takes a stack policy as its last required argument ... There is no spawn without one: the program states, for every actor, how its stack is reserved and released, which is the nothing-hidden rule applied to memory." (L7658)
- "`main` is not an actor and does not receive a runtime-managed stack. It runs on the platform's ordinary program stack, with no growth and no release, which is the nothing-hidden rule applied to the program's entry: nothing is provisioned that the program cannot see." (L7668)
- It also shows up in diagnostics: "In both modes the report is always produced; there is no configuration to suppress it. A failure with no diagnostic output is a runtime defect." (L9057) And: "There is no separate 'runtime log' destination." (L9063)
- Five named stack-release algorithms (L7648–L7654). Each is described as "a memory-retention policy that allocators and language runtimes have long used" (L7646). The program chooses; the runtime does not guess.

### P10. Unbounded growth; the program that chose the limit owns the failure

- "**Unbounded**: A stack grows on demand. There is no per-actor maximum and no runtime-wide cap" (L7630).
- "Stack growth is never a failure and never a supervision event ... This is why `:oom` is not a `failure_reason`" (L7666). Also: "`:oom` is intentionally absent." (L9365)
- Responsibility follows from choice: "Address space runs out only in a program that has chosen its own reservation sizes, so the failure is that program's to handle." (L7634) The dangerous-thread case says the same: "A program that spawns many dangerous actors is the one that knows their number, so the failure is that program's to handle." (L9631)
- Mailboxes follow the same pattern: "**No Built-in Backpressure**: The runtime does not provide automatic backpressure mechanisms. Mailboxes are unbounded" (L10244). Backpressure is "Programmer Responsibility" (L10246), and the spec gives an acknowledgment-pattern example (L10256–L10282).
- **Alternatives rejected.** Fixed stack sizes and classical stack overflow ("there is no fixed limit that triggers a classical 'stack overflow' fault", L9073). Also bounded mailboxes and backpressure built into the runtime.

### P11. Let it crash, but only when the substrate is sound (BEAM philosophy, native binary)

- **Quotes.**
  - "Silica provides BEAM-like actor crash containment in a compiled, native binary runtime: ... "Let it crash" semantics apply at the actor level. ... No VM is involved: Silica compiles to native binaries. ... The language is functionally pure and memory-safe by construction." (L8708–L8714)
  - "This gate is the native-binary analogue of BEAM's "VM must be intact" rule: recovery is permitted only when the substrate needed to run other actors is known to be sound." (L8809)
  - "This is the same philosophy as BEAM: recovery is permitted only when the analogue of the VM/runtime is trustworthy; otherwise the whole system stops." (L9694)
  - "Because the language cannot express undefined behavior and MTE converts misuse to synchronous hardware exceptions, the set of possible faults is closed" (L8783).
  - "This converts memory misuse from silent corruption into deterministic, containable faults." (L8779)
- **Development vs production.** "Rationale: in development, crashing immediately and noisily reveals bugs faster than silently recovering." (L9708)
- **Bounds failures in actors.** These end the actor instead of aborting the process: "inside an actor an out-of-bounds index ... terminate the actor with `failure_reason` `(:explicit, :buf_bounds)` ... and the access is never performed. Only in `main`, which is not an actor, do they remain a runtime abort" (L7084, decided by Lee on 2026-10-23).
- **No exception handler.** "`actor_not_found` cannot be caught: Silica has no exception handler. A `call` or `cast` that raises it ends the sender." (L9979)
- **Layered summary table** at L9733–L9748: language (no undefined behavior), hardware (MTE), signal handler (containment gate), recovery (`siglongjmp`), supervision.
- **Alternatives rejected.** A VM; try/catch exceptions; silent recovery during development; and recovery when runtime invariants may be corrupted (L9684–L9692).

### P12. Danger is quarantined and named: Fifi, dangerous actors, taint

- **Quotes.**
  - "Think of Fifi as a cute, cuddly-looking poodle that will bite you when you try to pet it: **non-Silica code loaded and run by Silica applications** looks approachable from the outside, but it remains outside Silica's memory and type guarantees and can fail in ways pure Silica cannot. The language and compiler surface that risk through the wrapper-first contract below rather than pretending the boundary is safe to touch casually." (L15851)
  - "Inbound interop (C or another language calling into Silica) is not part of the language and is not planned: Silica programs call out through Fifi, and nothing outside calls in." (L15861)
  - On `external_danger`: "This effect authorizes **execution** of foreign calls inside the worker behavior installed by `spawn_dangerous`; it does **not** authorize callers at the `spawn_dangerous` install site." (L4765) This separation between installing and executing recurs.
  - "A dangerous actor ... runs on its own OS thread for its whole life; it is not scheduled on a carrier, so a foreign call that blocks suspends only that actor." (L9629)
  - Hardware containment for FFI: MPK on x86-64 (L9603–L9611) and thread isolation on AArch64. "AArch64 has no userspace memory-key primitive equivalent to MPK." (L9617)
  - Taint: "On external-danger-touched bytes `decode` is permitted exactly where `recreate` is ... remains barred from `hot_swap`, command execution and code loading. Every `decode` is a point where foreign bytes become values" (L10553–L10558).
- **Device access** gets the same treatment. Device registers are named by atom, never by offset. "There is no read-modify-write prim." (L4834) MMIO is allowed only in `spawn_device` behaviors (L4836).
- **Alternatives rejected.** Inline C FFI, inbound FFI, and raw pointer access to devices.

### P13. Transport is language, not library

- **Quotes.**
  - "**Important: transport is a full and equal citizen of Silica.** Data transport is a full behavior of modern computing devices, so it is built into the language and its compiler and checked by the effect system ... it is not an add-on library." (L28, repeated at L10475)
  - "**Transport Is Language**: ... a new protocol is an addition to the language, never a program library" (L35).
  - "The set is closed: `WireFormat` and `Carrier` are traits a program cannot implement (E2409)." (L10562–L10563)
  - "Decoding is validation: every received byte is untrusted input, and a decoder never answers partial data." (L10482–L10483)
  - A paradox the spec resolves explicitly: "Networking is not part of the Silica language. ... Transport is part of the language even though sockets are not" (L12720–L12722).
- **Erlang interop through the wire format.** ETF, the BEAM external term format, is the first wire protocol (L10564, L10571). "Records are maps, not Erlang records" (L10590).
- **Security honesty.** "The `(:tcp)` carrier is plain TCP. It provides no authentication, no encryption and no peer identity ... Secure interchange is being built on top of this carrier in Project BEES" (L10673).
- **Alternatives rejected.** User-extensible serialization traits ("marker traits `Transportable` and `Recreatable` are not part of the language", L10518), protocol libraries, and decoders that return partial data.

### P14. Designed for modern chips, not the PDP-11

- **Quotes.**
  - "**Designed for Modern Chips**: First-class support for what current hardware actually exposes (AArch64, RISC-V, x86-64, and later targets), not a portable 1970s machine model" (L36).
  - "OS-hosted systems ... present memory to applications using the **classic PDP-11–era model** carried forward into modern Unix and Windows: a **flat virtual address space** per process ... The **OS must arbitrate shared RAM**; portable user-space code therefore **cannot** rely on sidestepping that model" (L6133).
  - "Silica's compilation process is fundamentally different from traditional compilers, designed specifically for AArch64 chip architectures rather than retrofitted from x86-era tools." (L16002)
- **Honest limits.** Memory-space semantics are "**fully supported and guaranteed only on OS-free executions**" (L4771, L6131). On hosted OSes `mem(Space)` remains for "static discipline, documentation", "but **this specification does not guarantee**, at this time, that each memory space maps to **different hardware attributes**" (L4771).
- Hardware features as language: SVE, NEON, MTE, PAC and Apple Silicon (§21), plus write-back vs write-through guidance (L6123–L6127).

### P15. Machine-readable errors and spec-anchored diagnostics

- Every compile error carries `See specification: spec:[section]` and an HTML-comment metadata block for LLMs (L136–L160). "A plain `key: value` metadata block, one key per line, embedded in an HTML comment (not JSON)" (L171). "there are no extra per-kind keys" (L175).
- Crash reports are "Human-readable + LLM-parseable" (L9746).
- **Alternative rejected.** JSON diagnostics and per-error-kind schemas, both chosen against for uniformity.

### P16. Compiler architecture: separation of concerns and constraint propagation

- "The Silica compiler uses a **multiple-pass** architecture rather than a single-pass descent-based design." (L16581)
- Rationale (L16585–L16587): "Separation of concerns ... Cross-module analysis ... Optimization flexibility."
- "The parser does **not** use conventional recursive descent. It uses **constraint propagation**: Each token starts with a set of possible roles; grammar rules are expressed as constraints between adjacent tokens. ... This design supports incremental capability addition and strong modularity." (L16591–L16597)

### P17. "One program means one thing on every target"

- "On the ESP32-S3, 64-bit cells take the runtime spinlock, so one program means one thing on every target." (L10911)
- "every port checks these rules the same way" (L4838).
- The process-fatal statuses (70 and 71) are "the same on hosted and OS-free targets" (L9740).

---

## 3. "Why?" and "Why not?" moments

These passages either question a convention ("Why do we do it this way?") or remove a limit ("Why not let it grow?" "Why not put it in the language?").

1. **Why must a function declare effects it doesn't perform?** It doesn't have to. Effects stay local, and declaring a callee's effect is an *error* (E3010, L4908). This reverses the usual effect-system convention.
2. **Why have loops?** "No Loops: Recursion only; runtime handles internal looping" (L39). The actor loop itself is moved into the runtime (L7539, L7560–L7574).
3. **Why `if/else`?** Removed. `case` on a boolean replaces it (L2129–L2146).
4. **Why name types?** "the type in source is the type that is meant" (L99). Names are removed so that readers, human or model, never "unwind alias definition sets" (L42).
5. **Why not let the stack grow without limit?** "There is no per-actor maximum and no runtime-wide cap" (L7630). The default reservation is "the machine's physical memory plus its swap" (L7632). This is a direct "why not?" against the fixed-size stack convention.
6. **Why does the runtime move my actor?** It never does: "not for load balancing, thermal throttling, core parking, power management, NUMA locality" (L7596).
7. **Why is networking a library while transport is built in?** "Transport is part of the language even though sockets are not" (L12722). Transport is "a full behavior of modern computing devices" (L28).
8. **Why should C be able to call into us?** "Inbound interop ... is not part of the language and is not planned ... nothing outside calls in." (L15861)
9. **Why a 1970s machine model?** The spec asks this pointedly: "not a portable 1970s machine model" (L36), and it criticises the "PDP-11–era model" (L6133).
10. **Why recover silently in development?** "crashing immediately and noisily reveals bugs faster than silently recovering." (L9708)
11. **Why is `:oom` a failure reason?** It isn't: "`:oom` is intentionally absent." (L9365)
12. **Why can't an actor call itself?** "The reply can never come, resulting in permanent deadlock." (L10216) Here the compiler turns a runtime hazard into a compile error.
13. **Why recursive descent?** The parser uses constraint propagation instead (L16591).
14. **Why `sleep`?** "There is no `sleep`." (L15305) Timers send messages instead.
15. **Why an unbounded mailbox with no backpressure?** "Programmer Responsibility" (L10246). Compare Erlang, which also has unbounded mailboxes. The spec makes the responsibility explicit.
16. **Why Option and Result as generics?** "there is no `Option<T>` or `Result<T, E>` in the type system" (L71).
17. **Why trust a socket's bytes?** "every received byte is untrusted input" (L10482).

---

## 4. History clues

### 4.1 Dated decisions and implementation-status stamps

The spec has no formal changelog, but it holds many dated notes. Date frequency: 2026-10-12 (1), 10-15 (1), **10-16 (14)**, 10-17 (1), 10-20 (1), 10-21 (2), 10-22 (1), **10-23 (13)**, 10-24 (3), 11-01 (1), 11-09 (3), 11-10 (1), 11-12 (2). Most decision activity falls in **mid-to-late October 2026**. Transport and links were active in **November 2026**.

Decisions explicitly attributed to "Lee":
- **2026-10-22 and 2026-10-23.** Explicit failure reasons; "the access or allocation is never performed" (L9361).
- **2026-10-23.** Out-of-bounds, invalid buffer and list-index failures end the actor instead of aborting (L7084).
- **2026-10-23.** "Decided by Lee, 2026-10-23 (region memory safety design Q8, §9.2)": the atomic ordering model. "The function-level barriers formerly added by `mem(atomic)` are removed once each operation carries its ordering." (L10911) The text cites a numbered question list ("Q8"), so a separate design document exists: "region memory safety design".
- **2026-10-24.** The `:foreign_fault` failure reason (L9360).
- **2026-11-01.** Regions live in the stack frame; "the implicit heap is removed on the hosted targets" ("chunk 15 phase 4e", L6643).

### 4.2 Removed or superseded features

- **`struct` and `enum` declarations.** "§3.4.6 Struct Declarations (superseded by §3.4.2)", with "Example (historical only)" (L1716–L1733). §3.4.7 enum is likewise superseded (L1735–L1765). The grammar is kept in the document as a fossil.
- **The `move` builtin.** "The older three-argument builtin `move` was removed from the compilers on 2026-10-16; it is not part of the language" (L15104).
- **Failure reason tags.** "before 2026-10-23 the runtimes gave it tag 1 and no atom; tag 1 is no longer written" (L9396). "Before 2026-10-16 the breach ended with reason tag 0, which a `:transient` parent read as a normal exit and never restarted." (L9457) This is a concrete bug story.
- **The `mem(atomic)` function-level barriers.** Removed under Q8 (L10911).
- **User `recv()`.** "The one previously listed, an example in §16.2.8 that called `recv()` from user code, has been corrected." (L9723)
- **The implicit heap.** Removed 2026-11-01 on hosted targets (L6643).
- **§20.4 Networking.** "The section number is kept so that existing references resolve; it has no further content." (L12720) Networking moved out of the language and into Fifi.
- **§15.4 supervision.** "All previously deferred decisions have been resolved" (L9729). The section used to carry [DEFERRED] markers (L8702).

### 4.3 Development infrastructure revealed

- "chunk 1 of the [ROADMAP](../../ROADMAP.md)", "Phase1_TODOs/actor_stack_growth_plan.md" (L7624), "chunk 15 phase 4e" (L6643). The work is organized as roadmap chunks and phases.
- "trials" are the test suites cited throughout, for example `actors_addition/actor_message_capturing_fn_literal` (L2170), `supervisor_exit_reports_addition` (L9331).
- There are four targets: Apple Silicon macOS, Linux AArch64, Linux x86-64 and ESP32-S3 (L7609). The NUCLEO-L476RG and Raspberry Pi 5 are also mentioned (L10673, L7640).
- "The compiler itself is written this way" (L7668), meaning `main` waits in `wait_for_exit` while actors do the work. So the compiler is self-hosted or at least written in Silica. Worth confirming.
- Project BEES (Erlang-compatible BEAM mode, SEMP/TRUST over mutual TLS), "As of 2026-11-10" (L10673).
- `tls_quantum_safe_future.md` is labelled "**Future development**" (L16).

### 4.4 Legacy layers that contradict newer principles

These look like strata from an earlier design. They are good material for the HISTORY chapter and should be confirmed with the author.
- **§6.2 "Silica provides structured exception handling"**, written with a `type exception = ...` declaration (L3772–L3779). This conflicts with "Silica has no exception handler" (L9979) and with the ban on custom types (L1681). §6.2.3 says "exceptions not yet implemented" (L3795).
- **§23.3.2 and §25.3.2** use `Result<int, string>` and `Result<T, Error>` (L15485, L15674). §25.2.1 uses `result<int, string>`. All conflict with "No Generics" (L71).
- **§25.1** declares `type runtime_error = ...` (L15571). This also conflicts with §3.4.2.
- **§14.2.2 "Effect violations are caught at runtime"** (L7331–L7336). §14.4.4 and §23.2.1 speak of "Capability Tokens", "Stack Inspection" and "Dynamic Checking" (L15405–L15410). The rest of the spec describes compile-time effect checking with E30xx codes. These look like a pre-static-checking design.
- **§15.3.1** gives an example with `proc[concurrency]` on the signature (L8679). That breaks the "Critical Rule" at L1625.
- **§9.1.2 "Effect Aliases" and §9.1.3 "User-Defined Effects"** (L4778–L4798). These are allowed even though types have "No Aliases". Is the asymmetry deliberate?
- **§23.2.3** lists `network_io` as "core language, §20.4" (L15460). §20.4 says "Networking is not part of the Silica language" (L12720).
- **§1.4** says "Silica targets AArch64", while §1.2 lists "AArch64, RISC-V, x86-64" (L36, L102). The design widened from an ARM-only language.
- **§26.4** makes bold performance claims: "Silica applications typically outperform equivalent safe Rust code by 15-25% on AArch64" (L15760); "Memory Safety Overhead: ≤5%" (L15757). No data is cited. These may be early aspirations.
- **§6.1.2**: "Note: Sum types and variant patterns not yet implemented in experiments" (L3757). "experiments" may be the name of an earlier phase of the project.

---

## 5. Interview leads

1. **Effects are local (L4908, L1625).** Most effect systems make effects transitive, so a caller inherits its callees' effects. You made them local and made over-declaration an error. What problem were you avoiding? Why is `register_rwr` the only effect that propagates (L4916)?
2. **LLM-friendly as a first-class goal (L37–L46).** When did you decide Silica should be designed for language models as readers and writers? Did a particular experience with an LLM writing code lead to "one way at the language level"?
3. **No custom types, no aliases (L1681, L99).** Giving up `struct` and `enum` is radical. The superseded sections L1716 and L1735 show you once had them. What made you remove named types? What did you lose, and what did you find you didn't miss?
4. **No `if/else` (L2129).** Was removing `if/else` a "why do we need two ways to branch?" moment? How did people react?
5. **Regions in the stack frame and removal of the heap (L6643, 2026-11-01).** Tell the story of "chunk 15 phase 4e". What convinced you the implicit heap could go? What happened to code that relied on it?
6. **The nothing-hidden rule (L7658, L7668).** It is named only in the stack section. Is it the master principle behind Silica? Where else do you apply it?
7. **Unbounded stacks, no `:oom` (L7630, L9365).** "Why not let the stack grow until the machine runs out?" This rejects decades of fixed-size stacks. What was the first moment you asked that question?
8. **Pinning and no runtime migration (L7596).** The BEAM balances load across schedulers; Silica refuses to. Why trust the program over the runtime here? Did hardware like Apple Silicon's efficiency and performance cores shape this?
9. **BEAM philosophy without the BEAM (L8708, L8809, L9694).** What did Erlang teach you that you kept, and what did you deliberately leave behind (the VM, preemption, `receive` loops, links)? Why OTP behaviours rather than raw processes?
10. **No exception handler (L9979) vs. the legacy §6.2 (L3772).** Was there a period when Silica planned try/catch? What changed your mind?
11. **Fifi the poodle (L15851) and "nothing outside calls in" (L15861).** Where did the poodle metaphor come from? Why rule out inbound interop completely, even as a future plan?
12. **Transport is language (L28, L12722).** Why make wire protocols and carriers part of the language and compiler, yet leave sockets out? What failure in other ecosystems were you reacting to? How do ETF and Project BEES (L10673) fit your plans to interoperate with Erlang?
13. **"Not a portable 1970s machine model" (L36, L6133).** Is the PDP-11 critique central to Silica's identity? Which hardware experience made you see the flat-memory model as a limitation?
14. **The Q8 decision on atomics (L10911).** What were questions Q1–Q7 of the "region memory safety design"? Can we see that document? "One program means one thing on every target": how did the ESP32-S3 force that principle?
15. **The restart bug (L9457).** Before 2026-10-16, a restart-intensity breach used reason tag 0 and was misread as a normal exit. How was it found? Do bugs like this shape how you write the spec?
16. **Legacy layers (§4.4).** The spec still holds `Result<T,E>`, `type exception`, runtime capability tokens and the Rust-performance claim (L15760). Are these fossils of an earlier Silica? What did that earlier Silica look like, and when did the turn to "no generics, no custom types, compile-time effects" happen?
17. **Constraint-propagation parser (L16591).** Why reject recursive descent, the standard technique? Was that a "why?" moment too?
18. **Errors that cite the spec (L136–L175).** Each error points to a spec section and carries LLM-readable metadata. Is the spec meant as a teaching document for both humans and models?
19. **"The compiler itself is written this way" (L7668).** Is the Silica compiler written in Silica? When did it become self-hosting, if it has?
20. **Debug crashes noisily (L9708) and reports can't be suppressed (L9057).** Do these come from operations experience? Did a silent failure in some earlier system make you insist that "A failure with no diagnostic output is a runtime defect"?

---

## Appendix: useful anchors for drafting

| Theme | Lines |
|---|---|
| Design principles list | L26–L42 |
| LLM-friendly subsections | L44–L99 |
| Error message format | L132–L213 |
| Effects on sequences only | L1623–L1677 |
| No custom types | L1679–L1691 |
| Superseded struct/enum | L1716–L1765 |
| No if/else | L2127–L2148 |
| Effect list and hosted caveat | L4753–L4775 |
| Effects are local | L4908–L4916 |
| OS-free vs OS-hosted memory | L6129–L6135 |
| Region in stack frame (2026-11-01) | L6643 |
| Region moves between actors | L7003–L7033 |
| Safety properties | L7283–L7410 |
| gen_server model and rationale | L7539–L7586 |
| Pinning policy | L7588–L7609 |
| Actor stacks, nothing-hidden rule | L7622–L7670 |
| BEAM-like crash containment | L8706–L8811 |
| What containment doesn't guarantee | L9682–L9694 |
| Dev vs prod modes | L9698–L9719 |
| Summary table | L9733–L9748 |
| Self-call deadlock | L10204–L10220 |
| Backpressure | L10242–L10282 |
| Transport | L10473–L10690 |
| Networking not in language | L12718–L12724 |
| Fifi | L15849–L15876 |
| Performance claims | L15736–L15768 |
| Multi-pass and constraint parser | L16579–L16597 |
