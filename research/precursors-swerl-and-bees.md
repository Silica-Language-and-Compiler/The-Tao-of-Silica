# Precursors and siblings: SwErl and Project BEES

Research notes for *The Tao of Silica*. Compiled 2026-11-13.

**Sources read**

- SwErl: shallow clone of `https://github.com/inter-erlang/SwErl` (main, 102 commits), plus the remote branch
  `node_dev`. Files: `README.md`, `Sources/SwErl/SwErl.docc/SwErl.md`, `.../GettingStarted.md`,
  `.../resources/Contribute.md`, doc comments in `Sources/SwErl/*.swift`, `git log`. No code was run.
- Project BEES: `/Volumes/2T/project-bees` (54 commits, 2026-04-24 to 2026-11-10). README, the three `contract/` documents,
  the conformance kit, every `development-plan/*.md`, and the spike notes.
- Silica: `/Volumes/2T/silica`, checked out on branch `E2-transport-work` at `6e3f85e229` (2026-11-13), read with
  `git grep` and `git log`.
- Side discovery: `/Volumes/2T/BEAM_SEMP` (the SEMP/TRUST Erlang code, 2025-08-29 to 2025-10-09). It sits between SwErl and
  BEES, and both projects name it. I read only its README head and its git log.

Paths below are relative to each repository's root unless written in full. "SwErl:" means the clone of
`inter-erlang/SwErl`; "BEES:" means `/Volumes/2T/project-bees`; "Silica:" means `/Volumes/2T/silica`.

---

## 0. The timeline in one table

| Date | Event | Source |
| --- | --- | --- |
| 2023-02-24 | SwErl initial commit; "Added the ability to spawn throwing closures" the same day | SwErl `git log` |
| 2023-02-25 | "Removed the ability to spawn throwing functions or closures. Declared as alpha form." | SwErl `git log` |
| 2023-03-14 | PIDs switched from UUIDs to "the same behavior as local processes in the Erlang REPL" | SwErl `git log` |
| 2023-04-07 | README gains the "actor claim": SwErl "is an expression of the actor model" | SwErl commit `16f5bc0` |
| 2023-10 to 2023-11 | gen_statem, GenServer, EventManager (with student contributors: artable/Sylv, jonah) | SwErl `git log` |
| 2023-11-19 | "added concurrent write test which presently results in EXC_BAD_ACCESS" | SwErl `git log` |
| 2024-02-29 | Node code removed from main: "Still working on those in the node_dev branch" | SwErl `git log` |
| 2024-05-01 to 2024-06-27 | `node_dev`: working EPMD, accepting node connections, `REG_SEND`, ticks, `net_kernel:connect_node/1` | SwErl `node_dev` log |
| 2025-08-29 to 2025-10-09 | BEAM_SEMP (SEMP = TRUST + TEMPUS), an Erlang secure-distribution overlay | `/Volumes/2T/BEAM_SEMP` log |
| 2025-09-20 | SwErl drops node interoperability "since that is to be part of the Swift implementation of SEMP" | SwErl commit `0f76305` |
| 2025-10-09 | Last SwErl commit ("skipping Jekyll"), the same day as BEAM_SEMP's last merge | both logs |
| **2025-12-26** | **Silica first commit**: "first checkin of bootstrap silica compiler for AArch64" | Silica `git log` |
| 2026-04-24 / 04-27 | BEES repository and first `parallel-tracks.md` ("secure by default") | BEES `git log` |
| 2026-09-14 to 09-17 | BEES provisional plan, decisions D1 to D30, spikes S1 to S13, Silica defects SD-1 to SD-22 | BEES `git log` |
| 2026-10-22 | Silica: "the next development set is region safety for Project BEES" | Silica `docs/participate.md` |
| 2026-11-04 | BEES MVP proposed; compiler-author guide; D31 to D34; M1 wire codec | BEES `git log` |
| 2026-11-05 09:34 | Silica's transport design (`Transportable`, `WireFormat`, `Carrier`, ETF first) first committed | Silica `23c198f565` |
| 2026-11-05 | BEES D35 "leverage Silica's transport design"; BEES deletes its own ETF term codec | BEES `git log` |
| 2026-11-06 | BEES M0 to M5 done: two Silica nodes speak Erlang distribution v6 on 127.0.0.1 | BEES `development-plan/mvp.md` |
| 2026-11-10 | BEES ported to Silica's transport; TLS engine D40, D41 | BEES `git log` |
| 2026-11-12 | Silica stdlib fixes "BEES SD-42" (SIGPIPE on a write to a gone peer) | Silica `git log --grep=BEES` |

The arc: an Erlang-shaped library inside someone else's language (SwErl, Swift, 2023 to 2025), a secure overlay
written in Erlang itself (BEAM_SEMP, 2025), a new language with the Erlang ideas built into its core (Silica, from
December 2025), and then a project that tries to bring the BEAM languages themselves onto that new language
(BEES, 2026).

---

## 1. SwErl

### 1.1 What it is

SwErl is a Swift package that adds Erlang-style processes, message passing and three OTP behaviours
(`GenServer`, `GenStateM`, `EventManager`) to Swift on Apple platforms. It runs on Grand Central Dispatch. It began
under the author's personal account (`yenrab/SwErl`; the README's install line still says
`https://github.com/yenrab/SwErl.git`) and now lives in the `inter-erlang` organisation, beside `SwErlDemos`
(a local copy is at `/Volumes/2T/SwErlDemos`).

- **Dates:** 2023-02-24 (initial commit) to 2025-10-09 (last commit on main). Active work on processes ran through
  2023; the behaviours came in late 2023 and early 2024; Erlang node work ran on `node_dev` until 2024-06-27.
- **People:** mainly Lee Barney, with contributors listed as artable/Sylv and jonah in late 2023 and early 2024.
  Logo by Jenna Ray (README).

### 1.2 Thesis

> "SwErl is a general purpose concurrency library conforming to the design patterns and principles found in the
> Erlang Programming Language." (SwErl `README.md`, line 2)

> "Parallel and concurrent computing should not be hard! SwErl is a small package that reduces not only the
> difficulty of thinking about concurrency, but also how much code you have to write." (SwErl `README.md`,
> "Painless Concurrency")

Its argument against Swift's own model:

> "coroutines (async/await parallelism) and promises both attempt to linearize asynchronous code. As long as
> everything goes well, both of these approaches can make concurrent and parallel code seem easier to write and
> read. They do this by localizing code placement. But when something goes wrong, both still require deep and
> significant understanding of what is happening outside of the current thread. ... SwErl takes a different
> approach. It is designed embrace multi-core machines rather than hide those cores. It also eliminates the need for
> semaphores and locks, by negating the possibility of race conditions." (SwErl `README.md`)

The 2023-04-07 version adds a section later removed:

> "SwErl is an expression of the actor model. While Swift has items called actors, SwErl's' expression is simpler to
> use and avoids the over-proliferation of Swift's async/await syntax." (SwErl commit `16f5bc0`, README "Underpinnings")

The DocC overview widens the goal from concurrency to communication between devices:

> "Concurrency and cross-device communication for Swift made easy ... SwErl primatives also allows apps to communicate
> between devices of different types across networks." (SwErl `Sources/SwErl/SwErl.docc/SwErl.md`)

The README promised Erlang interoperability until 2025-09-20:

> "Though not presently implemented, SwErl will allow for seamless communication between Swift Apps and Erlang server
> code, simplifying client/server relationships and distributed applications." (SwErl README, removed in `0f76305`)

### 1.3 Principles

1. **Spawn long-lived processes, then send.** "SwErl uses a spawn-send pattern. You spawn long-lived processes. Then
   elsewhere in your code you send messages to these spawned processes. ... When processes aren't processing or
   receiving messages they do not use any threads or threading resources." (README)
2. **Short-lived processes cost as much as long-lived ones, so use them sparingly.** "Such short-lived processes
   should be used sparingly since they use the same amount of computational effort to create and destroy as do
   long-lived processes." (README)
3. **Processes are cheap.** "Each SwErl process is only 88 Bytes in size. ... it took less than 0.0005 milliseconds
   to spawn individual processes and less than 0.00083 milliseconds per message sent." (README)
4. **A handler runs once per message; the state is passed in and returned.** "Any time a message is sent to that
   process, the closure will execute. These closures have two arguments if they are stateless, three arguments if they
   are stateful." (`GettingStarted.md`)
5. **Synchronous and asynchronous are different kinds of process.** Four spawn functions:
   `spawnasysl`, `spawnasysf`, `spawnsysf`, `spawnsysl` (asynchronous or synchronous, stateless or stateful)
   (`SwErl.docc/SwErl.md`). "Message passing to asynchronous processes are unidirectional. ... There is no promise,
   handle, or anything of the sort required in SwErl." (`GettingStarted.md`)
6. **Failure is a value, not an exception.** "a `SwErlPassed` enumeration is used to indicate success or failure. This
   allows for easy detection of success or failure without throwing exceptions." (`GettingStarted.md`). The log shows
   the choice being made: throwing closures were added on 2023-02-24 and removed the next day.
7. **No process may hog the threads.** "Each stateful process and statem now has its own serial queue. These serial
   queues feed, by defualt, the global async queue. This way, no greedy stateful process or statem can hog the
   underlaying threads." (SwErl `git log`, 2023-10-09)
8. **Follow Erlang as closely as possible.** "remember that this library aims to emulate Erlang's OTP features as
   closely as possible. Review Erlang's documentation for differences as a starting point." (README, Contributing)
9. **Tests are documentation.** "Unit tests are written not only for quality control, but to demonstrate the usage
   and construction of SwErl code. Where possible, unit tests should be verbose and clear." (`Contribute.md`)

### 1.4 Erlang ideas SwErl brought to Swift

| Erlang idea | SwErl form | Source |
| --- | --- | --- |
| `spawn` and `!` | `spawnasysl{...}`, custom infix `!` on `Pid`, `String` and `SwErlAtom` | `SwErl.swift` lines 539-680 |
| Registered names | `"printProcess" ! "It's Me."`; the Registrar | `GettingStarted.md` |
| PIDs `<id.serial>` with a node creation number | `struct Pid { id: UInt32, serial: UInt32, creation }`; "creation ... is zero when the process is local, non-zero when the process is a remote node" | `SwErl.swift` lines 141-156 |
| `gen_server` | `GenServerBehavior` protocol; `startLink`, `call`, `cast`, `handleCall`, `handleCast`, `terminateCleanup` | `GenServer.swift`, `GettingStarted.md` |
| `gen_statem` | `GenStateM`; the ATM and DockSim examples | `GenStateM.swift`, `GettingStarted.md` |
| `gen_event` | `EventManager.link`, `EventManager.notify` | `EventManager.swift` |
| Distribution (EPMD, handshake, ticks, `REG_SEND`) | `node_dev` branch: `EPMD.swift`, `NetKernel.swift`, `Node.swift`, `ERPC.swift`, `ExternalToNative.swift`, `NativeToExternal.swift` | SwErl `node_dev` tree and log |
| External Term Format | the `ExternalToNative` / `NativeToExternal` codecs ("Fixed Big Num reads", 2024-02-28) | SwErl log |

### 1.5 What SwErl learned, or found lacking

These are inferred from the code and history, not stated as lessons by the author. Treat them as interview prompts.

- **The host language fought it.** "Swift Dictionaries are not-thread safe, even where thread-safety would be
  expected in other similar dictionary implementations. Reads concurrent with any write to the dictionary will cause
  unrecoverable memory errors, even to different keys" (`Contribute.md`, "The Registrar"). Log, 2023-11-19: "added
  concurrent write test which presently results in EXC_BAD_ACCESS". The Registrar's queue went concurrent, then serial,
  then wrapped in "safe calls" (2024-03-02).
- **No supervisors.** The message path checks state validity "to prevent silent cascading failures before Supervisors
  are implemented" (`Contribute.md`). A comment in `GenServer.swift` (about line 259) leaves a known race in place because
  the error "should error within the context of the process and result in erlang-style error handling. Bubbling up
  through the links until something is configured to trap exits." No such mechanism exists in SwErl.
- **Messages are untyped.** "Because messages can be any type, inside of the process the message must be cast message
  to expected types." (`GettingStarted.md`). Every handler starts with `guard let message = message as? Int`.
- **`!` does two jobs.** The same operator casts to asynchronous processes and returns a reply from synchronous
  ones, so the caller cannot see from the call site which it gets.
- **Platform lock-in.** "SwErl Node requires networking primitives available only on Apple platforms. SwErl will not
  compile on other platforms." (README, Compatibility)
- **Distribution was never finished, then handed to SEMP.** "SwErl Node, an as-of-yet incomplete library allowing native
  Swift to connect to a distributed Erlang system as a near-fully featured node" (README before `0f76305`), then
  "removed node interoperability since that is to be part of the Swift implementation of SEMP" (2025-09-20).
- **Processes ride on GCD, not on cores.** The README speaks of "embrac[ing] multi-core machines", but the process
  is a serial dispatch queue and the OS decides placement.

---

## 2. Project BEES

### 2.1 What it is

**BEES = "BEAM Elastic Execution Surface."** (BEES `README.md`, line 3)

> "Project BEES is the **shim that lets BEAM languages** (Erlang, Elixir, Gleam, LFE) **be compiled to Silica and its
> constructs**. It is not a reproduction of the BEAM's code API for Silica programmers. Each BEAM language is compiled
> to Silica by its own language-to-Silica compiler. ... BEAM processes become plain Silica actors, BEAM atoms are Silica
> atoms held in Silica's atom table, and OTP's supervisors, gen_servers, and state machines become Silica's own
> constructs. BEES supplies the rest of what compiled BEAM code needs and Silica lacks: the term model, BIFs, ETS,
> ports, and distribution" (BEES `README.md`, line 7)

> "The name nods to **Bogdan and Björn's Erlang Abstract Machine (BEAM)**. ... it is a **focused execution surface** and
> **shim** that carries that lineage forward in a new substrate." (BEES `README.md`, line 9)

- **Dates:** repository 2026-04-24; first plan 2026-04-27; real work from 2026-09-14; MVP done 2026-11-06; port to
  Silica's transport 2026-11-10. "Currently BEES is in its inception phase." (README, Status)
- **Licence:** Apache 2.0 (Silica's own licence file is separate).
- **Relationship:** "a **sibling** product and repository whose role is the **actor execution and distribution**
  story on top of Silica" (README, Scope out); "There are no common version numbers between Silica and BEES." (README)

**How the definition changed.** In April BEES was a "**compatibility and execution layer** consisting of a set of files
you can include in your Silica application. BEES presents a **BEAM-style surface** for BEAM-idiom programs" (BEES
`README.md` at commit `0fc9c89`). By September it was a compilation target for other people's compilers and
explicitly *not* an API for Silica programmers. The April scope also spoke of "policies for fairness, preemption, and
locality"; the current text says "fairness, yielding, and locality", because Silica never preempts a dispatch.

### 2.2 Thesis: "possible, not easy"

> "**Possible, not easy** (D19). BEES does not duplicate every BEAM type or behaviour. Its purpose is to make it
> *possible* to compile a BEAM language to Silica, not to make it easy.
> - Where Silica can already express a behaviour, however awkwardly, reproducing it is the language compiler's job.
> - BEES and Silica change only where something would otherwise be impossible.
> - How faithful a compiled program is to its behaviour on the BEAM is each compiler's business, not a BEES guarantee."
> (BEES `development-plan/roadmap.md` §1)

The BEAM is split in two and each half is replaced differently: "**The emulator** (the bytecode interpreter) is
replaced by **compilation**" and "**The runtime system (ERTS)** is replaced by **Silica constructs wherever they exist**
and by the **BEES shim wherever they do not.**" (roadmap §1)

### 2.3 Principles

1. **The ownership rule.** "BEES contains **only the portions of the BEAM that Silica lacks.** Every gap belongs to
   exactly one class" (roadmap §2): **U** upstream (belongs in Silica), **B** BEES shim, **C** each language's
   compiler, **E** native edge ("BEES, temporarily", every function with "a named retirement trigger").
2. **No duplicated actor runtime.** "**A BEAM process is a plain Silica actor** (D1, decided). BEES does not wrap
   actors, ship a second actor runtime, or keep a process-object layer. A local pid *is* an `actor_ref`." (roadmap §2)
3. **Language-specific things belong to the language's compiler.** "**anything that could come out differently for
   Erlang, Elixir, Gleam or LFE belongs in that language's compiler, not in BEES.**" (roadmap §6, D24 notes)
4. **No OTP source.** "BEES holds no OTP source and never depends on the OTP code base." (roadmap §2)
5. **Nothing is caught.** "**Decided 2026-09-15: nothing is caught inside the actor.** ... **Compilers reject `catch`
   clauses, `after` clauses and Erlang's `catch Expr` at compile time**" (roadmap D2)
6. **Every actor has a supervisor.** (D18, revised 2026-11-04 so that the compiler, not BEES, guarantees it)
7. **BEES does not narrow Silica.** "Where Silica is more flexible than the BEAM, or can report more about a crash ...
   BEES exposes it and does not cut it down to what the BEAM offers. ... the contract describes BEAM-compatible
   behaviour as the floor, not a ceiling." (roadmap D32)
8. **Secure by default; BEAM security only on request.** "The BEAM was designed in an era when **inter-node
   interaction was not under continuous attack**. ... **BEES will be designed to be more secure than the BEAM by
   default.** ... in BEES, the secure path is the default path, and the insecure path is the one you have to ask for."
   (BEES `development-plan/parallel-tracks.md`, first version `0fc9c89`, lines 67-77). "The goal is parity *as a
   ceiling*, not as a baseline" (same, line 88).
9. **Existing atoms only.** "`list_to_atom/1` and `binary_to_atom/2` behave as `list_to_existing_atom/1` ... In BEAM
   mode, **every node allowed to connect must be named in the code**." Chosen "for security" (roadmap D16).
10. **Don't roll your own crypto.** "**BEES is written in Silica, and the native edge is kept small.** 'Don't roll your
    own crypto,'" (roadmap §2). BEES ships no TLS library; the user installs OpenSSL or Mbed TLS (BEES
    `contract/what-is-required-to-use.md` §1; D40).
11. **Silica is never patched from BEES.** "BEES never fixes them in Silica (AI_POLICY.md: a person files and lands each
    one)" (BEES `development-plan/silica-defects.md`, line 3). "If the generator concludes that Silica or BEES must
    change, it reports that as a proposal and does not work around it silently." (BEES
    `contract/so-you-want-to-write-a-compiler.md` §0)

### 2.4 The specification

BEES's specification has three parts.

**(a) The target contract** (`contract/so-you-want-to-write-a-compiler.md`, draft 2026-11-04). It is written for an
AI that generates a compiler: "**It assumes your compiler is generated by an AI.** ... **Do not invent.** ... A
symbol, function or option that this document does not list does not exist. Where a requirement says **open**, the
generator must stop and report the open point by identifier, not pick an answer. ... **The Silica compiler is the
authority on what is legal.** ... When Silica rejects generated code, fix the generator, not the test. ... **Keep a
person in the loop for security.**" (§0). Requirements are numbered (A1.1 to A10). Some that show Silica's shape:

- A2.1: "`main` must **register a failure reporter before it spawns anything.** ... Silica rejects any earlier spawn."
- A3.1: "Use a **cast-only** behaviour ... unless the actor is deliberately call-only. Do not mix the two".
- A3.3: "An actor holds **no stack between messages.** Code that would suspend in the middle of a function ... must be
  **split at the suspension point**".
- A3.4: "Silica never interrupts a dispatch, and a running dispatch **cannot be killed** ... Place **yield points**".
- A3.8: "Write each behaviour so that Silica can **prove the old state is released.**"

The eight points the contract fixes are listed in roadmap §1: term representation, process model, calling
convention, dynamic calls, OTP behaviours, memory and yielding, naming, and versioning.

**(b) The conformance kit** (`contract/conformance/`): eight reference programs, C01 selective receive to C08 exit-hub
counts, "stated in prose, each with the exact output it must produce and a hand-written Silica lowering that is known
to pass", plus a lowering-choices file and checker (`contract/conformance/README.md`).

**(c) The wire profile** (`contract/wire-v1.md`, 2026-11-06): "BEES nodes talk to each other with the wire of the
Erlang distribution protocol, latest handshake version (6), and carry typed messages as the External Term Format
(ETF). It is a **profile**: a strict subset of what OTP 28 speaks". It says what it is not: "It does **not** make a
BEES node interoperable with a stock Erlang node: the handshake has no cookie digest".

**Two inter-node modes** (`development-plan/inter-nodal-modes.md`; roadmap D36): **SEMP/TRUST** (the default:
mutual TLS 1.3, ALPN `trust/1`, a SHA-512 certificate whitelist, one CALL or CAST per connection, "**cannot talk to a
regular BEAM node**") and **standard BEAM distribution** ("an explicit downgrade"). "SEMP/TRUST has no implementation
today: the Erlang code in `BEAM_SEMP` is the **design starting point**, and BEES is the implementation."

**Configuration:** `bees.config`, Erlang term text, one mode per node, default `trust`, "fail-fast validation, no
clamping" (roadmap D37; `development-plan/bees-config-file.md`, design only).

### 2.5 How BEES relates to Silica

**(i) BEES uses Silica's constructs as given.** Silica supplies processes, per-core scheduling, atoms, supervision,
gen_server-style behaviours, state machines, links, registries and crash containment (roadmap §1). The MVP's two
programs "are **ordinary Silica programs**: they use Silica's own actors, supervisors, spawn, `cast_registered`,
operators and types exactly as the Silica specification describes, and nothing in their source mentions the network"
(BEES `development-plan/mvp.md` §1).

**(ii) BEES found Silica defects, and Silica fixed many.** BEES keeps a ledger of numbered defects (SD-1 to SD-39 in the working tree; Silica commits cite SD-42),
each with a reproducer, in `development-plan/silica-defects.md`. Examples:

- SD-3 (2026-09-17): "**Atom tables are per compilation unit.**" Spike S2 "**Failed as first written**, which confirmed
  SD-3" (`spikes/S2-cross-unit-atoms.md`). It led to D30 (all atom literals in one generated unit) and Silica later
  added "a build-wide `silica.atoms`" (silica-defects.md, 2026-11-04 status).
- SD-7: "**A region moved into a message is never reclaimed** ... 100,000 casts each carrying a fresh two-cell region
  reach 550 MB". Closed by 2026-11-04 ("31 MB peak").
- SD-9: "**A `call` whose callee dies returns the zero value of the reply type**". "**Closed by design:** a `call` to
  a dead callee fails the caller with `(:explicit, :actor_not_found)`."
- SD-10: a supervised child's composite state passed wrongly; spike S1 "blocked" by it. Closed; "The cause was a SIR
  fallback that tagged every spawn in a supervisor module with the supervisor's trampoline."
- SD-12: "**Tail recursion is not compiled to a jump**". This matters for a language with "No Loops: Recursion only"
  (Silica spec §1.2). Closed.
- SD-27, SD-28: state replacement taking quadratic time when the compiler cannot prove release (W2300); "The BEES exit
  hub had it: 2,000 reports took 22 s and 20,000 never finished." Still open in the ledger.
- Spike S3 (2026-09-17): "Maximum live actors in one process: **4,093.** Every actor is a pthread with a 1 GiB stack
  reservation" (`spikes/S3-actor-ceiling.md`). The gap ledger now marks S-6, Silica's per-core scheduler, "delivered".

The traffic went into Silica's own plans. Silica's `docs/participate.md`: "Decided by Lee on 2026-10-22: the next
development set is region safety for Project BEES ... 0. **Port, check and fix the four BEES defect repros** in
`project-bees/trials/silica_defects/`" and "H4 ... BEES supervises every process and restarts constantly."
Silica's `region_memory_safety_design.md` (about line 1395): "it fixes BEES's SD-7". Silica commit of 2026-10-24:
"Design for chunk 15 which allows full closing of chunk 4 in perperation to do project BEES proof of concept". Silica's
monitor TODO starts with "**Note (BEES).** BEES, a library for compiling BEAM languages to Silica, needs the runtime
`link` only. It does not use monitors." (`compiler/design_documents/Phase2_TODO/actor_monitor_demonitor_todo.md`).

**(iii) Did BEES drive Silica's transport design?** The dates suggest it did, though the documents do not say so.

- Silica's specification used to put networking outside the language (spec §20.4: "networking is not part of the
  language and is reached through Fifi", quoted in `tls_quantum_safe_future.md`). BEES planned accordingly: gap-ledger
  S-22, "**Transport and DNS wrappers through Fifi, written by BEES.** Silica will not write a TCP/IP stack".
- 2026-11-04: BEES's M1 wire codec and D34 ("the underlying protocol matches the BEAM and Erlang").
- 2026-11-05, 09:34: Silica's transport design is committed (`23c198f565`), with ETF first and the BEAM distribution
  protocol named as the layer above it: "The distribution protocol is a later design ... built entirely above this
  one" (Silica `compiler/design_documents/transport_serialization_design.md` §7). BEES's alignment note: "**Silica's own
  distribution protocol is explicitly left to a later design built above this one** (their §7); BEES is that layer."
  (BEES `development-plan/silica-transport-alignment.md` §1)
- The same day the principle enters Silica's specification: "**Important: transport is a full and equal citizen of
  Silica.** ... it is not an add-on library." and "**Transport Is Language**" (Silica spec §1.2). BEES records it as
  "Transport becomes part of the language (Lee, 2026-11-05)" (alignment §1).
- BEES then dropped its own pieces: "Delete the bees_term/ETF term codec: any-type terms are the language transpiler's,
  not BEES's or Silica's" (BEES log, 2026-11-05); D35 "BEES leverages it"; the port on 2026-11-10 deleted BEES's C
  carrier.
- Influence also went from BEES to Silica in smaller ways. Silica's transport design lists "the keyed in-memory library
  over a replay; BEES's ETS and DETS substrate" as later work (§10). Silica's carriers carry a security note pointing to
  BEES: "Secure interchange is being built on top of this carrier in Project BEES ... SEMP/TRUST over mutual TLS 1.3"
  (Silica spec, about line 10673; also `transport_links_design.md`, `transport_serialization_design.md`). And the
  2026-11-12 Silica fix "(BEES SD-42)" for SIGPIPE.

Summary: BEES is the first heavy user of Silica's actors, supervisors, regions and transport, and the place where the
BEAM-compatibility requirements are worked out. It found defects that changed Silica's priorities (chunk 4, chunk 15,
the region-safety set). Silica's transport design appeared the day after BEES chose the Erlang wire and took the
same shape (ETF, 4-byte framing, `REG_SEND`-ready). BEES then gave up its own codec and carrier to use the language's.
Security (TLS, TRUST) and distribution are left above the language, in BEES.

**(iv) What BEES shows about Silica's character.** Silica's differences from the BEAM keep coming up as compiler
obligations: one behaviour is call-only *or* cast-only (D5: a `gen_server` "becomes **two Silica gen_server-style
actors**"); no user `recv()` (D1); no preemption (A3.4); no `trap_exit` (README: "supervisor-only exit trapping");
a cast to a dead actor ends the *sender* (D31, S-34); static receive types (transport principle 5); no type conversion
(gap ledger S-20 withdrawn: "Silica has no type conversion and BEES adds none").

---

## 3. Idea-lineage table

| Idea | SwErl (2023-25) | BEES (2026) | Silica (2025-26) | How it changed |
| --- | --- | --- | --- | --- |
| Handler runs once per message; the runtime owns the loop | Stateful closure `(pid, message, state) -> newState` runs on each send (`GettingStarted.md`) | D1: "processes are plain Silica actors" | "a **non-recursive** behavior function is invoked **once per message** by the runtime. The **infinite loop** lives only in the runtime" (spec §15.1.2, about line 7539) | From library convention to a language rule: Silica forbids user `recv()`, so an Erlang mid-function `receive` must be reshaped by the compiler (BEES A3.3) |
| Synchronous vs asynchronous processes are different kinds | Four spawn functions: `spawnsysf`, `spawnasysf`, ... | "Do not mix the two" (contract A3.1); split `gen_server` (D5) | Behaviour return type is call-only or cast-only (spec §16.2.6.1); E2237 for `cast` to a call-only actor (silica-defects SD-8 status) | SwErl's single `!` did both; Silica separates `call` from `cast` and checks the split at compile time and run time |
| Failure as a value, no exceptions | `SwErlPassed.ok/.fail` tuples; throwing closures removed 2023-02-25 | D2: "nothing is caught inside the actor"; compilers reject `catch` | `(:ok, T) \| (:rejected, atom)`; failure ends the actor with `(:explicit, atom)` (`docs/participate.md` item 5) | From "return a status" to "let it crash and return results where a result is expected" |
| Let it crash, supervision | Not implemented ("before Supervisors are implemented", `Contribute.md`) | D18: every actor has a supervisor; exit hub D23 | "BEAM-like actor crash containment in a compiled, native binary runtime ... 'Let it crash' semantics" (spec §15.4.1) | The missing piece in SwErl is central in Silica |
| PID = id + serial (+ creation) | `struct Pid { id, serial, creation }` (`SwErl.swift` line 154); REPL-style PIDs (2023-03-14) | D22: 32-bit position + 32-bit child number "maps directly onto the BEAM wire's 32-bit id and 32-bit serial"; remote form `{ node, creation, id, serial }` (alignment §4) | `actor_id` "conventionally printed as `<position.child_number>`. A distribution layer carries it as two 32-bit fields" (spec, about line 8604) | Same wire shape, but Silica gives the fields meaning (spawner position, child number) |
| Registered names | `"name" ! msg`; Registrar of three dictionaries | `REG_SEND` mapped to `cast_registered` | atom-keyed registry, `spawn_registered`, `cast_registered` (spec line 232; transport §7) | String names became atoms; thread-safety is the runtime's job, not a hand-guarded dictionary's |
| gen_server, gen_statem | `GenServerBehavior`, `GenStateM` protocols | D5: "OTP behaviours are Silica traits" | "Silica's counterpart of Erlang/OTP's `gen_statem`" (spec, about line 9755); `Supervisor` trait | Protocols in a library became language traits |
| gen_event | `EventManager` | Converted by each language compiler (D24) | No dedicated construct found | Dropped from the core |
| Untyped messages | `Any`, cast inside the handler | `bees_term` as the dynamic value type for BEAM code | "The receiving type is static" (transport principle 5) | Reversed: Silica refuses dynamic typing; any-type terms "are the language transpiler's" (BEES log 2026-11-05) |
| No thread hogging | Per-process serial queue feeding global queue (2023-10-09) | Yield points and dispatch budget (roadmap §1 item 6); balancing via `migrate_actor()` (D3) | Per-core carrier threads, switching only at yield points, never preempting (roadmap §1 summarising spec §15.1.2) | From GCD fairness to explicit cores; BEES does the balancing |
| Embrace multi-core | "embrace multi-core machines rather than hide those cores" (README) | "first-class support for running and balancing work across many cores" (BEES README) | "Designed for Modern Chips: ... not a portable 1970s machine model" (spec §1.2) | From a slogan to core IDs at spawn, pinning and bare-metal targets |
| Swift as Erlang node (EPMD, handshake, ticks, `REG_SEND`) | `node_dev`, 2024-05 to 2024-06 | M3 (2026-11-05): "Erlang distribution handshake v6, framing, ticks, REG_SEND, peer table, proxies" | Transport §7 lists exactly these as needs of the distribution layer | The same feature list, done again in Silica; this time it shipped (M4) |
| ETF codec | `ExternalToNative.swift`, `NativeToExternal.swift` | M1b ETF codec "checked against erl", later deleted | `encode((:etf), v)`, `decode((:etf), frame, limits)` built in (transport §0) | From a hand codec in a library to a compiler-derived validator |
| Secure distribution | Handed to "the Swift implementation of SEMP" (2025-09-20) | TRUST default, BEAM mode a downgrade (D7, D36) | `(:tcp)` carrier "provides no authentication"; points to BEES (spec, about line 10673) | Security stays above the language, in BEES |
| Cheap processes as a claim | "88 Bytes" per process (README) | S3: 4,093-actor ceiling, ~17 KB RSS per idle actor (2026-09-17) | Per-core scheduler delivered later (gap ledger S-6) | BEES measured the claim against Silica and reported a ceiling |
| Testing as documentation | "Unit tests ... demonstrate the usage" (`Contribute.md`) | Conformance kit; goldens; "fix the generator, not the test" | 33,824 trials at fixed point 1 (BEES roadmap, header) | From unit tests to trial goldens as the definition of correct |

---

## 4. "Why?" and "Why not?" questions visible in these projects

### Why?

1. **Why leave Swift?** SwErl had a working library with student contributors. The record shows Swift's dictionaries
   crashing under concurrent access (`Contribute.md`), no supervisors, untyped messages and Apple-only networking.
   Was Silica the answer to things a library could not fix inside a host language?
2. **Why put Erlang's runtime ideas into a compiled systems language instead of using the BEAM?** BEES says what it
   adds: "first-class support for running and balancing work across many cores and across a network" (README) and
   targets with no OS (ESP32-S3, NUCLEO-L476RG; D29, D40).
3. **Why "possible, not easy"?** D19 changed the definition of done: "1.0 is reached when every construct has a
   demonstrated route, not a published fidelity rate."
4. **Why write the target contract for an AI-generated compiler?** (`so-you-want-to-write-a-compiler.md` §0). It fits
   Silica's "LLM-Friendly and Human-Readable" principle (spec §1.2), but Silica's `AI_POLICY.md` bans AI co-authors on
   commits and allows "essentially" no LLM involvement in security reports.
5. **Why is transport "part of the language"?** (spec §1.2, 2026-11-05). Before, spec §20.4 had networking "reached
   through Fifi". What changed in those weeks, and how much was BEES?
6. **Why make security the default and BEAM compatibility a downgrade?** (`parallel-tracks.md` "Security posture").
   The idea appears first in BEAM_SEMP (2025), whose README says "No errors are sent to clients that malicious actors
   can leverage."
7. **Why existing atoms only, and every allowed peer named in the code?** (D16). It is a strong closed-world choice.
8. **Why two separate implementations for TRUST and BEAM mode** (D36), rather than security layered over Erlang
   distribution (D34 as first written)?

### Why not?

1. **Why not preemption?** Silica "never preempts a dispatch". Erlang's reductions are replaced by compiler-placed
   yield points and a "dispatch budget" (roadmap §1 item 6). A call-only actor "cannot yield; its work must fit one
   dispatch" (contract A3.4).
2. **Why not one actor that handles both calls and casts?** Gap ledger S-19 (a combined gen_server trait) was
   "Withdrawn 2026-09-15"; D5 splits every mixed `gen_server` in two.
3. **Why not monitors or `trap_exit`?** D20: "monitors are not part of BEES"; Silica keeps them "for Silica's own
   programs" but they were still "benign stubs in every runtime" on 2026-10-16 (monitor TODO).
4. **Why not dynamic types?** Silica's receiving type is static, so "any-type terms are the language transpiler's, not
   BEES's or Silica's" (BEES log 2026-11-05). What does that cost Erlang's untyped messages?
5. **Why not catch exceptions?** D2 forbids `catch` and `after` in compiled Erlang. Erlang code relies on `try ...
   after` a lot.
6. **Why not keep `Transportable` / `Recreatable` marker traits?** They were designed and dropped within the same day,
   2026-11-05 (Silica `31d648fd00`: "drop the Transportable and Recreatable marker traits; limits are a decode
   argument").
7. **Why not implement OTP's libraries in BEES?** D24: "BEES holds no OTP source".
8. **Why not ship a TLS library, and why not rustls?** D6 chose rustls; D40 (2026-11-10) replaced it with OpenSSL and
   Mbed TLS; D41 relaxed post-quantum key exchange on the boards.
9. **Why not finish SwErl Node in Swift?** EPMD, ticks and `REG_SEND` worked on `node_dev` in mid-2024 and were never
   merged.

---

## 5. Interview leads (20 questions)

1. **SwErl to Silica.** SwErl's last commit was 2025-10-09 and Silica's first was 2025-12-26. What happened in those
   eleven weeks, and was there a moment you decided a library could not do what you wanted? (SwErl `git log`; Silica
   `git log`)
2. **Swift's dictionaries.** `Contribute.md` says reads concurrent with a write "will cause unrecoverable memory
   errors". How did fighting the host's memory model shape Silica's regions and per-actor stacks? (SwErl
   `Sources/SwErl/SwErl.docc/resources/Contribute.md`; Silica `README.md` line 42)
3. **Throwing closures for one day.** You added throwing closures on 2023-02-24 and removed them on 2023-02-25. What
   convinced you, and is that the root of D2 and Silica's "let it crash"? (SwErl `git log`; BEES roadmap D2)
4. **Four spawn functions.** SwErl split processes into synchronous and asynchronous, stateful and stateless. Silica
   makes a behaviour call-only *or* cast-only. Is that the same idea? Did you ever want one actor to do both? (SwErl
   `SwErl.docc/SwErl.md`; Silica spec §16.2.6.1; BEES D5)
5. **The "actor claim".** In 2023 the README said SwErl was "an expression of the actor model" that "avoids the
   over-proliferation of Swift's async/await syntax". Why was that section later removed, and how do you now describe
   Silica against Swift actors and async/await? (SwErl commit `16f5bc0`)
6. **88 bytes against 4,093 threads.** SwErl advertised 88-byte processes; BEES's spike S3 found a ceiling of 4,093
   Silica actors because each was a pthread. What was that like, and how did it change Silica's scheduler work?
   (SwErl `README.md`; BEES `development-plan/spikes/S3-actor-ceiling.md`; gap ledger S-6)
7. **Untyped to typed.** SwErl messages were `Any`, cast inside the handler; Silica says "the receiving type is
   static". When did you change your mind about dynamic messages? (SwErl `GettingStarted.md`; Silica
   `transport_serialization_design.md` §2 item 5)
8. **SwErl Node, again.** `node_dev` had EPMD, ticks and `REG_SEND` working in Swift in 2024; BEES's M3 did the same in
   Silica in 2026. What did you reuse, and why did the Swift version never ship? (SwErl `node_dev` log; BEES log
   2026-11-05)
9. **SEMP's origin.** SwErl handed node interoperability to "the Swift implementation of SEMP" in September 2025.
   What was SEMP for, and what made you decide Erlang's distribution was not safe enough? (SwErl commit `0f76305`;
   `/Volumes/2T/BEAM_SEMP/README.md`; BEES `parallel-tracks.md` first version)
10. **BEES's turn.** In April 2026 BEES was a "BEAM-style surface" for Silica programmers; by September it was a target
    for other people's compilers. What caused the change? (BEES `README.md` at `0fc9c89` vs current)
11. **"Possible, not easy."** Who is that phrase for, and what would you say to an Elixir programmer who hears it as
    "not our problem"? (BEES roadmap §1, D19)
12. **An AI writes the compiler.** The contract "assumes your compiler is generated by an AI", but Silica's
    `AI_POLICY.md` allows no AI co-authors on commits. How do you hold both? (BEES
    `contract/so-you-want-to-write-a-compiler.md` §0; Silica `AI_POLICY.md`)
13. **Transport becomes language.** On 2026-11-05 Silica's spec gained "transport is a full and equal citizen", the day
    after BEES chose the Erlang wire (D34). Did BEES cause that? What would Silica's transport look like without BEES?
    (Silica spec §1.2; Silica commit `23c198f565`; BEES `silica-transport-alignment.md` §1)
14. **Marker traits dropped the same day.** `Transportable` and `Recreatable` were designed and dropped within hours.
    What was wrong with them? (Silica `31d648fd00`; BEES alignment note, "Update 2026-11-05")
15. **The defect ledger.** BEES records 39 or more Silica defects and a rule that "BEES never fixes them in Silica". Which one
    surprised you most, and which changed the language rather than the compiler (for example SD-9's "closed by
    design")? (BEES `development-plan/silica-defects.md`)
16. **BEES setting Silica's priorities.** On 2026-10-22 you made "region safety for Project BEES" Silica's next
    development set. Is BEES the user that keeps Silica honest, or is there a risk of Silica becoming a BEAM back end?
    (Silica `docs/participate.md`)
17. **No preemption.** Erlang's fairness depends on reductions; Silica never interrupts a dispatch and "a running
    dispatch cannot be killed". Why was that a line you would not cross? (BEES contract A3.4; Silica spec §15.1.2)
18. **No monitors, no `trap_exit`, no `catch`.** BEES removes three things Erlang programmers use daily. Which removal
    was hardest, and what do you tell people who rely on `try ... after`? (BEES roadmap D2, D20; README "supervisor-only
    exit trapping")
19. **Existing atoms only.** D16 means every BEAM-mode peer must be named at build time. Is that closed world a security
    position, a consequence of Silica's atom table, or both? (BEES roadmap D16; spike S2)
20. **"Floor, not a ceiling."** D32 says BEES will not narrow Silica to the BEAM's limits, and early BEES wanted BEAM
    security as "parity *as a ceiling*". What does Silica do better than the BEAM, and what does it still do worse?
    (BEES roadmap D32; `parallel-tracks.md` first version, line 88)

---

## 6. Loose ends and cautions

- **Silica's ROADMAP.md is stale about BEES:** "The BEES project lists raw AArch64 as a 1.0 platform" (Silica
  `ROADMAP.md` line 157), but BEES dropped bare-metal AArch64 on 2026-09-17 (D29, S-27 withdrawn).
- **Silica's `tls_quantum_safe_future.md` still says BEES "wraps rustls"**; BEES moved to OpenSSL and Mbed TLS on
  2026-11-10 (D40).
- **I found no mention of SwErl anywhere in Silica's markdown** (`git grep -i swerl -- '*.md'` is empty). The SwErl to
  Silica line in section 3 is drawn from parallel features and the author's history, not from a stated link. Ask the
  author to confirm it (questions 1, 4, 8).
- **BEAM_SEMP** (`/Volumes/2T/BEAM_SEMP`, plus `/Volumes/2T/SEMP Design` and `/Volumes/2T/SEMP Erlang Version`) is a
  third precursor. It links SwErl's abandoned node work to BEES's TRUST mode and deserves its own research note.
- **Silica's checkout was on branch `E2-transport-work`**, not `main`. Line numbers in Silica's spec are approximate and
  belong to that branch at `6e3f85e229`.
- BEES documents change often and carry many dated "Update" banners. Quotes here are from the working tree on
  2026-11-13 unless a commit is named.
