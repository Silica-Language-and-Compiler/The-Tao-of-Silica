# Silica: Core Principles, "Why?" Moments, History Clues, Interview Leads

Research notes for *The Tao of Silica*. Source repository: `/Volumes/2T/silica` (read-only).
Compiled 2026-11-13.

**Citation convention.** `file:line` paths are relative to `/Volumes/2T/silica`. Abbreviations used below:

| Short | File |
|---|---|
| DP | `docs/design-principles.md` |
| IDX | `docs/index.md` |
| LS | `docs/learn-silica.md` ("Silica for Programmers") |
| LP | `docs/learn-programming.md` ("Learn to Program"; skimmed for philosophy) |
| PART | `docs/participate.md` (skimmed) |
| RM | `README.md` |
| ROAD | `ROADMAP.md` |
| AIP | `AI_POLICY.md` |
| CON | `CONTRIBUTING.md` |
| KISS | `silica_KISS_design.md` |
| DDR | `compiler/design_documents/README.md` |
| ADD | `compiler/design_documents/silica-specification-additional.md` |
| FV | `compiler/design_documents/silica-formal-verification-specification.md` |
| ONE | `compiler/design_documents/APPLICATION_IS_ONE_COMPILATION_UNIT.md` |
| EXEC | `compiler/design_documents/execution-environments-hosted-vs-bare-metal.md` |
| git | `git log` of the silica repo (commit hash and date given). This was read only to establish dates. |

**Source notes:**
- The normative list of principles is in the language specification, §1.2 and §1.3 (DP:11). That file (`silica-specification.md`) was not on the reading list, so I did not read it. DP calls itself "the reader-facing statement of the same list" (DP:11).
- `silica_KISS_design.md` is **not** a language document. It is the design for "Silica KISS", a small macOS IDE for working on the compiler, with OpenRouter AI built in. It matters to the book because it shows the author's general design temperament (non-goals, simplicity, a human approving every command) and because it records the Rust/cargo era of the compiler.
- The repo has 686 commits. The first is dated **2025-12-26** ("first checkin of bootstrap silica compiler for AArch64").

---

## 0. The one-paragraph thesis (author's own words)

> "Silica's target is to be the world's most intellectually honest, secure language and runtime—without asking you to fight the tools or the language to get there." (IDX:18)

> "Many other development stacks treat memory, concurrency, and observable behavior as separate concerns—each papered over with conventions, code reviews, and runtime luck. Silica weaves them into one model" (IDX:24–26)

> "You will recognize most of the pieces. The combination is the point. Silica puts effects, isolation, and memory into one model so the compiler can refuse programs that other languages would accept and then hope a review or a collector saves." (LS:23)

**Motto:** "Secure by default at compile time — fail soft, never fail silent" (RM:34; IDX:6, IDX:50; LS:45; LP:208).

---

## 1. Principles

The eight numbered principles in DP come first, with principle 8's sub-principles. After them come the principles that run through the other documents (honesty, compile-time rejection, fail soft, visible FFI, one compilation unit, self-hosting, and others). Most of those other principles are never listed formally, but the author states them repeatedly.

### 1.1 Explicit effects (DP §1)

**What it is.** Every side effect is declared on the `sequence` block that performs it, and the compiler checks the declaration. This covers mutation, I/O, concurrency, allocation, FFI, MMIO and transport. Effects are written on `sequence proc[...]` blocks and **never on function signatures**. They are also **local**: calling a function does not add the callee's effects to the caller. A sequence that declares an effect none of its own steps needs is also rejected (E3010).

**Rationale given.** Effects should be "checked, not guessed from names" (DP:21). Reviewers and tools should read the same contract. In the beginner book the author calls this honesty.

**Quotes.**
- "All side effects are tracked in type signatures." (DP:17)
- "Mutation, I/O, concurrency, and other observable behavior are not inferred from names or comments. They are declared on the sequence that performs them, checked, and visible where the work is written. Effects are local: calling a function does not add that function's effects to the caller, because the callee's own sequence declares and discharges them." (DP:19)
- "**Benefit:** Reviews and tools see the same contract. Observable behavior is checked, not guessed from names." (DP:21)
- "Function declarations do not carry effect declarations. Effects appear only on sequences, and each sequence declares exactly what its own steps do; one that declares more is refused." (DP:183)
- "That is the honesty rule. A helper that prints cannot print without a sequence that says so, and you see that sequence where the printing is written." (LS:185)
- "That is not bureaucracy for its own sake. It is honesty. When you read a program six months later, the word `device_io` tells you: this part talks to the world." (LP:572)
- The effect vocabulary is `device_io`, `network_io`, `concurrency`, `mem(Space)`, `atomic`, `hot_swap`, `register_rwr`, `external_danger`, `transport` (LS:189–199).

**Rejected / traded away.** The design rejects effects on function types, which Haskell and Koka effect rows both use. It also rejects *transitive* effect propagation. LS:29 contrasts this with Haskell `IO`/`ST`: "Effects live on sequences, never on `fn` signatures." The cost is that a function's type alone does not say whether calling it will print or allocate. (A note on wording: DP:17 says effects are "tracked in type signatures", while DP:183 says function declarations carry no effects. See interview lead Q3.)

### 1.2 Process monad (DP §2)

**What it is.** Sequential, effectful work is a monadic `proc[…]` computation, written as `sequence proc[ε] … produces pure e end`. Pure functions are ordinary functional code.

**Quotes.**
- "Sequential computations are represented as monadic processes." (DP:25)
- "Pure functions stay ordinary functional code. Effectful work is a `proc[…]` — a sequenced computation whose effects are part of its type, not hidden control flow." (DP:27)
- "**Benefit:** Pure code stays simple. Effectful work cannot hide inside an ordinary function type." (DP:29)
- "`<-` is a bind, not a mutation. `produces pure n` is the result of the sequence; `pure` means that expression does not start any new effect." (LS:66)

**Rejected.** Haskell `do`-notation spelled as `do`. DDR:242 says the sequence tutorial was "updated from older `do`-style tutorials", which suggests an earlier `do` syntax. Implicit sequencing of side effects in ordinary function bodies is also rejected.

### 1.3 Actor-based concurrency (DP §3)

**What it is.** Message passing is the primary concurrency mechanism. Actors are isolated and communicate by `call` (synchronous, gets a reply) and `cast` (asynchronous). Any sharing is a deliberate, typed exception. There is no `actor` keyword: an ordinary function becomes an actor when it is `spawn`ed. The runtime owns the receive loop (Erlang `gen_server` style), and the user's behavior runs once per message.

**Rationale.** Races and shared-memory bugs should not be the ordinary path. The architecture is meant to match human intuition about friends and messages, as the beginner book explains at length.

**Quotes.**
- "Actors are isolated. They communicate by `call` and `cast`, not by sharing mutable memory. Isolation is the default; sharing is a deliberate, typed exception." (DP:35)
- "**Benefit:** Races and shared-memory bugs are not the ordinary path." (DP:37)
- "A well-designed Silica application is a set of actors that pass messages. Functions still do the work *inside* a turn — they are not the shape of the program. If the architecture is only `main` calling helpers calling helpers, you have not yet designed the application." (LS:703)
- "There is no `actor` keyword. A handler is an ordinary function. `spawn` is what makes it an actor. This is not a thread, not `asyncio`, and not `multiprocessing.Queue`." (LS:705)
- "The runtime model is Erlang `gen_server`, not a user-level receive loop" (LS:748). ADD:163 adds: "The behavior is **not** defined as a user-level recursive receive loop."
- On preferring cast: "The preferred request/response shape between actors is asynchronous … Synchronous `call` is the fallback. This is how people text: few send a message and then do nothing until the reply comes" (LS:913).
- Beginner framing: "It is much easier to think about code when the code matches that experience. In Silica it does." (LP:23). The elephant-mother analogy for supervisors is at LP:27–29.

**Rejected / traded away.** Shared-memory threads, user-written receive loops, `asyncio`/goroutine styles, and a GIL. A known trade-off: `call` has **no timeout**, unlike `gen_server:call`'s default of 5000 ms (LS:927). Mailboxes are unbounded, so there is "no built-in backpressure" (LS:925).

#### 1.3a Supervision, "let it crash", and a small `main` (spread across LS, LP, RM)
- "The runtime is lightweight actors, message passing, and let-it-crash isolation (BEAM-like, native)" (RM:45).
- "Well designed Silica applications have a very small `main` function … That is an architectural rule, not a style preference" (LS:763–765). The reason: `main` is not an actor and nothing supervises it (LS:765–769).
- The compiler *enforces* that a FailureReporter is registered before any actor starts (E2236; LS:744, LS:1046).
- When to check versus when to crash: "do not pretend a failure is a success" (LP:1331). Check only when a failure would corrupt data or happens often. "In every other case, do not check. Let the calf fail." (LP:1335–1339)
- Expected failures are data and unexpected ones are restarted: "Prefer data over exceptions. There is no `try` / `except`, no `raise`" (LS:226).

### 1.4 Region-based memory, no GC (DP §4)

**What it is.** Memory is managed through regions and static lifetimes, with no garbage collector. Long-lived data has no shared heap. Storage follows actor stacks and region handles.

**Quotes.**
- "Memory is managed with regions, not a garbage collector." (DP:41)
- "Ownership and lifetimes are static. There is no shared heap for ordinary long-lived data. Storage follows actor stacks and region handles, so typical heap mistakes never become runnable code." (DP:43)
- "**Benefit:** Use-after-free, double-free, and leaks of that kind never become runnable code, and there is no garbage collector in the way." (DP:45)
- "Memory allocation happens in each actor's stack—storage is stack-shaped and flexibly sized, with no per-actor or shared heap for long-lived data." (IDX:73)
- "There is no refcounting, no cyclic-GC pause, and no `del`." (LS:658)
- On Rust: "No borrow-checker theatre. A lifetime is a value from `fresh_lifetime()`. Storage is the actor stack, not a heap the collector later walks." (LS:27)

**Rejected / traded away.** Garbage collection, reference counting, a shared heap, and Rust-style borrow checking ("theatre"). The **implementation has changed under this principle** (see §3). The current direction (chunk 15, decided 2026-10-24) is "structures and all escaping values on the actors' stacks, state at the stack base, deterministic compiler-proven release" (ROAD:143). Also: "`region(L, S)` is a lifetime-scoped stack area … there is no family arena" (ROAD:133). An earlier linear-ownership plan was *dropped*: "stack regions are not linear and safety is by lifetimes only" (ROAD:133, decisions 15–17).

#### 1.4a Actor stacks you configure explicitly
- "An actor's stack is reserved at spawn, committed only as it is used, and released after each message under one of five named policies the program picks per actor … An idle actor holds no stack memory at all." (IDX:79)
- "Silica requires this at every spawn so that nothing about an actor's memory is hidden." (LP:640)
- Later the state area also became the programmer's choice: a required `state_policy(:keep_state_area | :shrink_after_compaction | :compact_on_request)` (ROAD:143, decision 40).

### 1.5 References stay with their region (DP §5)

**What it is.** A `ref` or `buf` carries its region's lifetime in its type (`ref(L, Space, T)`). The type checker rejects any value that would separate a reference from its region or let it outlive the region. When a region moves (into a function, a `spawn`, or a message), its references move with it.

**Quotes.**
- "A memory reference is never separated from the region that contains the memory it refers to." (DP:49)
- "**Benefit:** A dangling pointer is not a representable value. If you have a reference, its region is still there." (DP:53)
- "a function that returns a reference into a region must return the region too (spec §12.1.4)" (LS:276)
- The E2100 example "reference outlives region" is at LS:675–685.

**Rejected.** Raw pointers and detached references, as in C.

### 1.6 Heap is an effect (DP §6)

**What it is.** Allocation is an effect, `mem(<space>)`, declared on a sequence just as `device_io` is. Pure functions do not allocate.

**Quotes.**
- "Allocating or growing region-backed storage is an effect, and it is treated like any other effect." (DP:57)
- "Constructing a region, a reference, a buffer, or a growing list is not an invisible runtime service. … The sequence that allocates carries the obligation; a caller of a function that allocates does not repeat it. Pure functions do not allocate." (DP:59)
- "**Benefit:** Allocation is visible in the type, so 'this just computes a value' cannot quietly grow memory." (DP:61)
- "Every list type names its memory space: `List[int64, mem(normal)]`, not `List[int64]`." (LS:222)

**Rejected.** Hidden allocation by a runtime service (the Python, Java and Go model). The rule has a cost: even a beginner's supervisor `init` must say `mem(normal)` (LP:568).

### 1.7 Designed for modern chips (DP §7)

**What it is.** The language exposes what current hardware actually provides: memory spaces, vector units, memory tagging and pointer authentication. It does not target a lowest-common-denominator abstract machine.

**Quotes.**
- "Silica is designed for the chips you can buy and program today — AArch64, RISC-V, x86-64, and the boards that follow — not for a portable 1970s machine model." (DP:67)
- "AArch64's NEON/SVE, MTE, and PAC are examples of that class of feature, not the limit of the model." (DP:67)
- "What you write maps to performance aligned with the hardware you can actually buy and use, not to a dangerously nostalgic picture of how chips and computers used to work." (IDX:36)
- "Real machines reward locality, parallelism without accidental sharing, and contained failure; the language and runtime are shaped so those ideas stay first-class, not bolted on after the fact or 'optimized in'." (IDX:34)
- The hardware shows up in the language: the 8-parameter limit is justified by AArch64's X0–X7 argument registers. "Arguments beyond the first 8 must be passed on the stack, which is less efficient than register passing." (FV:41)

**Rejected / traded away.** The "portable 1970s machine model", which is an implicit dig at C's abstract machine. The trade-off appears on hosted OSes, where the hardware guarantees weaken: "on OS-hosted targets, the same vocabulary often serves **discipline and API clarity** without promising the same per-space hardware behavior everywhere" (EXEC:5). See §1.17.

### 1.8 LLM-friendly and human-readable (DP §8)

**What it is.** Syntax and semantics should be easy for people to read and easy for tools, including LLMs, to parse "without guesswork". The principle has eight sub-parts (below).

**Quotes.**
- "Syntax and semantics are meant to be easy for people to read and for tools — including large language models — to parse without guesswork." (DP:73)
- "That means one way to do each job at the language level, no type aliases, explicit type annotations, consistent naming, and clear structural patterns." (DP:75)
- "The language is intentionally readable and LLM-friendly without sacrificing rigor" (IDX:123)
- From the beginner book: "Silica writes types in the open. … That looks wordy at first, but your AI/LLM will generate it anyway. You don't have to type it. It is deliberate. You should never have to guess what kind of thing a name is." (LP:338)
- "**Do not type programs by hand. Have the LLM write them.** … This book teaches you to read and judge programs. The typing is the LLM's job." (LP:15)

**Rejected / traded away.** Terseness and inference. The author accepts verbosity, and in the beginner book explicitly hands it to the LLM. LS:549 shows how far this goes: a single binding whose type annotation runs to several hundred characters.

#### 1.8.1 One way at the language level
- "Each job has one language-level construct. Programs are built by putting those constructs together." (DP:79)
- "There is not a menu of loops, a menu of type-parameter styles, or a menu of operators that all mean 'bind.' … Composition is where variety lives" (DP:81)
- "**Benefit:** People and LLMs choose among compositions, not among competing primitives for the same job. Generation has fewer forks that all look almost right." (DP:83)
- Consequences: there is no standalone `if` ("You branch with `case`", LS:80). There is one way to take a list apart ("That sounds limiting. It is also simple.", LP:974).

#### 1.8.2 No loops
- "Source code uses recursion only. The runtime may loop internally." (DP:87)
- "**Benefit:** Control flow stays in one recursive form that people and tools can follow." (DP:91)
- "The mailbox 'infinite loop' is inside the runtime. Your actor behavior returns." (LS:320)
- "Write the stopping case first. That is the habit that keeps recursion honest." (LS:334)
- Rejected: `for`, `while`, `loop`, and comprehensions.

#### 1.8.3 No generics
- "Polymorphism is achieved through traits, not generic type parameters." (DP:95)
- "There is no `Option<T>` or `Result<T, E>`. Shared operations live on traits implemented for concrete, inline types. Every type occurrence in source is syntactically concrete." (DP:97)
- "**Benefit:** … There is no generic-inference puzzle for compilers, LLMs, or for readers." (DP:99)
- "No generics maze. Polymorphism through traits and concrete types keeps programs straightforward to navigate compared with heavy type-level programming." (IDX:127–129)
- **Tension.** The stdlib uses `OrderedMap[string, int64, mem(normal)]`, `ItemType`/`KeyType` placeholders, `prepend[int64, mem(normal)](0, xs)` (LS:219), and "**Generic modules follow the witness conventions.**" (LS:478). See interview Q1.
- **History.** The commit "Removed generics for now." (git fb7a553edd, 2025-12-31) deleted `generics.silica`, `complex_generics_test.silica` and related files. The words "for now" are worth asking about.

#### 1.8.4 Unambiguous syntax / one operator per job
- `<-` binds, `=` compares, `->` is for function types and case arms (DP:105–107).
- "**Benefit:** Structure is obvious. Parsers and readers do not have to disambiguate overloaded punctuation." (DP:113)
- `@` is reserved for module qualification and never ends an atom name (FV:33–37).

#### 1.8.5 Explicit type annotations
- "Catch-all patterns must declare a type: `_: int64 -> 0`, not `_ -> 0`." (DP:135)
- "Python `match` allows `_`; Silica will not, because the type of the leftover value still has to be written down." (LS:82)
- "The `-> type` is required (a literal without it is error E1071; the type is never inferred)." (LS:86)

#### 1.8.6 Consistent naming
- snake_case and lowercase keywords (DP:143–145). Note that DP:145 lists `struct` as a keyword, while LS:94 says "no `struct Foo { … }`". See Q2.

#### 1.8.7 Structured, exhaustive pattern matching
- "The compiler checks that every case is covered." (DP:171) "**Benefit:** Control flow is explicit enough to analyze, and complete enough to verify." (DP:173)
- "That is the feature: a forgotten arm is a compile error, not a runtime surprise." (LS:145)

#### 1.8.8 Explicit modules and imports
- "You export by name and arity; nothing is public by accident." (LS:340) "`use` plus `@` keeps the origin of a name visible." (LS:360)
- "The `@` is the module qualifier. It keeps names honest. You can see where a function lives." (LP:1397)

#### 1.8.9 No aliases / structural types only
- "There are no type aliases and no user-declared type names. You write the shape at the use site." (DP:199)
- "A reader or a model that sees `{ width: int64, height: int64 }` or `Some(int64) | None` is looking at the type, not at a name that has to be unfolded through a definition set." (DP:201)
- "**Benefit:** People and LLMs do not get lost in deep or circular alias graphs. The type in source is the type that is meant." (DP:203)
- "Silica does not let you introduce a new type name. There is no `type Foo = …`, no `struct Foo { … }`, and no user `enum`" (LS:94)
- Traded away: nominal types, newtype safety (two records with the same fields are the same type, LS:106), and short names for long shapes. The cost is visible in LS:549 and LS:798–815 (the Supervisor `init` contract "written once" but very long).

### 1.9 Intellectual honesty (meta-principle; IDX, LS, LP)

**What it is.** Most of the explicit principles are framed as honesty: the code should not hide its effects, allocation, foreign code, failures or names. This is probably the closest thing to a single "Tao" in the documents.

**Quotes.**
- "the world's most intellectually honest, secure language and runtime" (IDX:18)
- "That is the honesty rule." (LS:185); "It is honesty." (LP:572); "Write the stopping case first. That is the habit that keeps recursion honest." (LS:334); "It keeps names honest." (LP:1397)
- "Silica stays honest about FFI through Fifi" (IDX:38)
- "do not pretend a failure is a success." (LP:1331)
- "A compiler error is not a verdict on you. It is a fact about the text." (LP:1552)

### 1.10 Reject "almost right" code at compile time; no reliance on the optimizer (ADD; RM; IDX)

**What it is.** Some patterns are normally cleaned up by an optimizer: dead bindings, duplicate computation, redundant algebra, loop invariants, constant expressions, and multiplication by powers of two. Silica's rule is that these are *hard compile errors*, with no pragmas to turn them off.

**Rationale.** "Rather than optimizing away inefficient or redundant code, Silica enforces that programmers write efficient code by design. … This reduces reliance on optimizer heuristics and makes program behavior more predictable." (ADD:40)

**Quotes.**
- "These patterns are anti-patterns that other languages allow (often with optimizer remediation); Silica rejects them outright." (ADD:34)
- "**No escape hatches**: These are hard errors. There are no pragmas or attributes to disable them." (ADD:175)
- "Dead bindings, duplicate work, redundant arithmetic, and similar 'the optimizer will fix it' patterns are compile-time errors." (RM:43)
- "Silica would rather stop you than 'optimize away' a mistake or wait for a test to notice it. These are hard errors, not warnings you can train yourself to ignore" (LS:1039)
- "The language would rather the program say what it means than hope an optimizer guesses." (LP:1554)
- "If the compiler finds a mistake, it stops and explains. That is a gift. A stopped program cannot quietly do the wrong thing." (LP:206)

**Rejected / traded away.** Optimizer-dependent performance and warnings. **Implementation gap:** only rule 3.1 (unused bindings, E1055) is implemented. "Rules 3.2 to 3.8 remain a specification of intent." (ADD:19–28). The public pages present the whole list as current behavior (RM:43, IDX:85). Rule 3.8 forbids `x * 8` even though there are no shift operators (ADD:143–151). See Q4.

**Related: the trials' assembly is a contract.** CON:36–38 says that a PR changing `.ascomp` golden assembly must show either that the new assembly is *better*, or that the change is required and that alternatives were evaluated. This puts code-generation quality under review.

### 1.11 Fail soft, never fail silent (motto; LS, LP, runtime docs)

**What it is.** Failures are contained (one actor, restarted by its supervisor) and always reported, never hidden. Expected failures are returned as data, and unexpected ones crash the actor, which is then restarted.

**Quotes.**
- "Motto: Secure by default at compile time — fail soft, never fail silent" (RM:34)
- "the compiler tries to catch problems before they become surprises, and when a running actor does fail, its supervisor is there — the failure is noticed and handled, never hidden." (LP:208)
- "A sloppy language might crash the whole program, or invent `0`, or keep running with a corrupt value. Silica does two better things." (LP:1251)
- Hardware support: "paired with hardware-assisted safety (e.g. MTE on AArch64) so faults become controlled events, not silent corruption." (IDX:113)
- In the roadmap: "enforced at compile time or halted at run time, never silent" (ROAD:133, the closing condition for chunk 4).
- Example decision (Lee, 2026-10-23, Q9 a): inside an actor, an out-of-bounds index "terminate[s] the actor with `(:explicit, :buf_bounds)` … the access is never performed" (PART:62).

### 1.12 Foreign code is visible and contagious: Fifi and `dangerous_` (RM, IDX, LS)

**What it is.** FFI is wrapper-first. Any module that wraps foreign code, or uses a module that does, must be named `dangerous_*`, and that naming obligation propagates "all the way to your application's root module". Foreign calls run only inside `spawn_dangerous` actors under the `external_danger` effect.

**Quotes.**
- "Think of Fifi as a cute, cuddly-looking poodle that will bite you when you try to pet it: non-Silica code loaded and run by Silica applications looks approachable, but it lives outside Silica's guarantees and can fail in ways pure Silica cannot." (IDX:40)
- "Fifi enforces a wrapper-first FFI contract and the `dangerous_` indicator that refuses to hide C-shaped boundaries behind ordinary Silica code" (IDX:42)
- "Silica does not hide language boundary crossings behind anonymous imports or reviewers memorizing transitive deps; pure Silica stays visibly pure at the module and artifact level" (IDX:44)
- "turns security audits, dependency reviews, release gates, and hand-offs … into grep-friendly, architectural signals" (IDX:46)
- "The audit story is `grep dangerous_`. Mixed artifacts advertise themselves. You should not need a linker map or tribal knowledge to see that a release is no longer pure Silica." (LS:1029)
- An alternative is offered: brokered IPC, where "no dangerous indicators are needed in your code" (IDX:105–107).
- "Calls from other languages into Silica are not planned." (ROAD:165)
- "Networking is not part of the language (spec §20.4): a program reaches the host's sockets … through the Foreign Function Interface … no TCP/IP stack is written." (ROAD:138)

**Rejected.** Transparent FFI (ctypes, cffi, Python C extensions: "in-process and silent", LS:1023), hiding foreign dependencies, and inbound FFI.

### 1.13 An application is one compilation unit (ONE)

**What it is.** The whole application, including all libraries and the stdlib, is conceptually one program with one atom table and whole-program checks. Libraries are source code, not binaries. Today's per-file build is a memory work-around that "nothing may rely on".

**Quotes.**
- "**Read this before designing anything in Silica** … Stated by Lee, the project owner, on 2026-09-19." (ONE:3–4)
- "This exists **only** to keep the compiler's memory down. It is not part of the language, and nothing may rely on it." (ONE:36)
- "**Libraries are source.** … Do not assume a separately compiled library format, a stable binary interface between separately built modules, or dynamic loading of Silica code." (ONE:62–64)
- "**Treat compile memory as the thing to fix.** When a design needs whole-program information that the split build makes expensive, the answer is to reduce and manage the compiler's memory, not to change the language to fit the work-around." (ONE:65–67)
- "At that point the work-around … go[es] away, and nothing in the language or the libraries has to change." (ONE:71–73)

**Rejected.** Separate compilation, binary library ABIs, dynamic loading, and per-file semantics. The principle is that the language model comes first and the implementation's limits must not shape it. (There is a tension with the `hot_swap` effect for "dynamic code load", LS:196. See Q12.)

### 1.14 Proof through types: Curry–Howard (FV)

- "Silica's type system corresponds to a logical calculus via the Curry–Howard isomorphism: Types ↔ Propositions; Terms ↔ Proofs; Type checking ↔ Proof verification" (FV:47–51).
- "The type system is aligned with a proof-oriented view of programs (Curry–Howard), with a path to richer verification as the toolchain matures." (IDX:97)
- Honest status note: "the compiler contains no mechanized proof checker or proof-term output." (FV:11)
- Recursive data uses `rec` with a `:none` base case: "the base case `:none` ensures termination … no infinite unfoldings at runtime." (FV:113)
- Related: named recursive ADTs are replaced by recursive tuples, which "are only for building non-naive data structures … inside the standard library. Application code does not hand-build linked lists or ad hoc trees" (LS:312).

### 1.15 Use first-class persistent data structures, not big ad hoc types (LS, LP)

- "Large types built from many items and layers are the naive design. Silica's standard library supplies persistent data structures instead" (LS:372).
- "Large types made of many items and layers are naive and inefficient." (LP:749). "keep the program's own records and tuples small … two, three, or four values that truly belong together" (LP:751).
- "Everything is persistent. An update returns a new root, the old root stays valid" (LS:406).
- "Compose before you build nodes." (LS:476)

### 1.16 Self-hosting, reproducibility and trials as truth (RM, ROAD, CON)

- "The compiler is written in Silica and builds itself. There is no bootstrap compiler to build and no separate seed source tree … the compiler that comes out compiles them again until the two agree byte for byte — the **fixed point**." (RM:82)
- "a chunk is closed by a new milestone, never by a build that merely compiles. Dates are deliberately absent." (ROAD:16)
- "A change is not finished until the trials pass on every platform it can affect." (CON:69)
- "Goldens are never regenerated automatically" (RM:213).
- An unusual identity rule: "The compiler takes no `--version` flag, and the strings inside the binary do not identify it. A build is identified by its file name" (RM:142). The generation counter "counts **down**: the lowest number is the newest build" (RM:140).

### 1.17 Bare metal first, hosted honestly bounded (RM, EXEC, ROAD)

- "Silica is designed for bare metal systems development, but also supports applications hosted by operating systems." (RM:7)
- "Silica is a **systems language**: it is designed to expose strong, explicit control … **when the execution environment allows**. … **some of that control is necessarily held by the operating system**" (EXEC:3)
- On an OS, memory spaces are "a discipline without guaranteed attribute differentiation" (ROAD:72). "The OS still chooses the page attributes; Silica still makes you name the space you meant." (LS:205)
- The meaning of pinning differs by target. On hosted targets, "exclusive placement is **not** guaranteed" (ROAD:67).
- "Without a general-purpose OS … limits come from **hardware**, the **runtime and libraries you ship**, and **only the third-party code you choose to trust**" (EXEC:9).

### 1.18 Design around use cases; small, cohesive, human contributions (CON, AIP)

- "We are building something that needs to be cohesive and well thought out across all use cases. … make sure that discussions are centered around the *use case* for a feature, rather than the proposed feature itself." (CON:84–88)
- "make *the smallest reasonable pull request possible*." (AIP:67)
- "Prefer minimal, purposeful changes over large refactors" (CON:74).

### 1.19 Human responsibility in an AI-assisted project (AIP; KISS; PART)

**What it is.** AI help is welcome for code and documentation, but humans own every contribution. AI is never a co-author, and humans must write their own words in human conversations. Security reports must have no LLM involvement at all.

**Quotes.**
- "All work is the responsibility of the human who makes the PR. We do not accept AI as co-contributors on commits." (AIP:12)
- "It is *never acceptable* to copy the response of an LLM or AI tool and use it as if it were your own words. … *If we want to talk to an AI, we will ask them ourselves*. We expect all interactions to be human interactions." (AIP:24–27)
- "Remember that humans have to *read* what you are generating. Less is more." (AIP:53–54)
- "We simply do not allow there to be a machine-to-team pipeline for high-priority security-related issues." (AIP:62–63)
- "The Silica project contains many agent (.jsonld) files. Their presence does not explicitly condone or request AI usage." (AIP:15)
- The same attitude in the KISS IDE: "No AI-generated command should run automatically." (KISS:731); "The AI can suggest commands, but the app should require explicit user action before running anything." (KISS:717)
- How work is split in practice: compiler/runtime changes "are compiler work for Fable. The ports and runs …, builds, trial runs, golden refreshes and documentation are for lesser models." (PART:65, citing "the project's `silica-fable-use-reduction` rules")

### 1.20 KISS as a general temperament (KISS)

The KISS IDE doc shows how the author designs a tool: by stating what it will *not* be.
- "The app should feel like a small, purpose-built development cockpit rather than a full editor platform." (KISS:9)
- Its non-goals include "A full Cursor clone", "A full VS Code replacement", and "A general plugin platform" (KISS:30–32).
- "The app should favor simple, understandable native implementation over generality." (KISS:39)
- "The app should use direct HTTP calls rather than depending on a third-party SDK." (KISS:405)
- "This keeps the app small, native, understandable, and focused on Silica compiler development." (KISS:1343)
- Open question: "Should the syntax grammar use a TextMate subset permanently, or should the app eventually use Silica's compiler lexer?" (KISS:1323)

---

## 2. "Why?" / "Why not?" moments

Places where the author questions a convention or turns down an alternative. Each is quoted and cited.

### 2.1 Why does a language need a garbage collector? / Why not Rust's borrow checker?
- "Memory is managed with regions, not a garbage collector." (DP:41); "there is no garbage collector in the way" (DP:45).
- "No borrow-checker theatre." (LS:27). This is the sharpest comment on Rust in the documents.
- "There is no refcounting, no cyclic-GC pause, and no `del`." (LS:658)
- "Python objects are shared by default. Silica values are not." (LS:693)

### 2.2 Why does a language need loops?
- "Source code uses recursion only. The runtime may loop internally." (DP:87)
- "Many languages have loops … Silica does not." (LP:990). The beginner analogy is the stack of plates (LP:992).

### 2.3 Why do we need generics? / Why `Option<T>`?
- "There is no `Option<T>` or `Result<T, E>`." (DP:97, DP:153)
- "There is no generic-inference puzzle for compilers, LLMs, or for readers." (DP:99)
- History: "Removed generics for now." (git fb7a553edd, 2025-12-31).

### 2.4 Why let programmers name types at all?
- "There is no `type UserId = int64` and no chain of synonyms that hide a record or a sum behind another name." (DP:201)
- "Python `class`, `dataclass`, `TypedDict`, and `TypeAlias` are the same kind of thing, and they are absent too." (LS:94)
- History: "aliasing structs now produces a parser error." (git 93bdae0d17, 2026-05-21, resolving issue #6). Structs were added and then pushed out.

### 2.5 Why let the optimizer clean up after the programmer?
- "Rather than optimizing away inefficient or redundant code, Silica enforces that programmers write efficient code by design." (ADD:40)
- "not warnings you can train yourself to ignore" (LS:1039)

### 2.6 Why design for a 1970s machine? (aimed at C)
- "not for a portable 1970s machine model" (DP:67); "not … a dangerously nostalgic picture of how chips and computers used to work" (IDX:36); "obsolete machine models or carry-over abstractions from another era" (IDX:32).

### 2.7 Why hide effects in names and docs?
- "effects on types make mutation and all possible kinds of I/O something the compiler checks, not something teams infer from names and docs." (IDX:26)
- "papered over with conventions, code reviews, and runtime luck" (IDX:24).

### 2.8 Why not Erlang/BEAM itself? (Borrowed and then made native.)
- "BEAM-inspired fault containment, native speed" (IDX:111).
- "Erlang/Elixir actors → … Native code. A behavior is `(Msg, State) -> …` and runs once per message." (LS:28)
- On the hosted path, the carrier scheduler "was the **BEAM pattern**: one carrier thread per logical core, many actors per carrier, cooperative switching at yield points" (ROAD:131).
- Where Silica deliberately differs from gen_server: "`gen_server:call` has a default timeout of 5000 ms, while Silica's `call` waits indefinitely" (LS:927).
- Interoperability rather than rejection: transport "phases 0-2: … the TCP/UDP/serial carriers, and the BEAM demo" (git e9d44f0e64, 2026-11-05). Wire format is ETF, Erlang's External Term Format (DDR:278).
- Early idea: "added beam2.0 architecture plans as a shim" (git d8a4f7544e, 2026-01-03; file `05_BEAM_shim_architecture_plans.md`).

### 2.9 Why should a bare `_` be allowed? Why `if`?
- "Python `match` allows `_`; Silica will not, because the type of the leftover value still has to be written down." (LS:82)
- "There is no standalone `if`. … Python `if` / `elif` / `else` and unguarded `match` do not exist here." (LS:80)

### 2.10 Why exceptions?
- "Prefer data over exceptions. There is no `try` / `except`, no `raise`, and no Python `None` meaning 'missing.'" (LS:226)

### 2.11 Why let foreign code look like Silica?
- "This is not `ctypes`, not `cffi`, and not `subprocess` dressed up as a function." (LS:1019)
- "Python C-API extensions are in-process and silent. Fifi is neither." (LS:1023)

### 2.12 Why compile libraries separately?
- "Do not assume a separately compiled library format, a stable binary interface …, or dynamic loading of Silica code." (ONE:62–64)
- "not to change the language to fit the work-around." (ONE:67)

### 2.13 Why keep a Rust bootstrap? / Why depend on LLVM?
- "Nothing in the build path is written in Rust and nothing needs `cargo`; the retired Rust bootstrap lives only in the repository's history." (RM:82)
- "Reaching it retired the Rust bootstrap for this path: nothing in the build path is Rust any more." (ROAD:111)
- Very early in the repo the compiler produced LLVM bitcode: "hello.silica and control_flow.silica compile to .bc files and run correctly" (git, 2025-12-27), followed by "removed compiled versions of the compiler along with llvm intermediate files." (git, 2025-12-27). Today the four backends emit assembly text, and a future plan replaces even that with "Silica-owned **chip instruction encoders** and **object writers**" (DDR:152).

### 2.14 Why should networking be part of the language? (No.) Why should transport be? (Yes.)
- "Networking is not part of the language (spec §20.4)" (ROAD:138).
- But: "Transport is part of the language, not a library, and the `transport` effect is how the compiler checks it." (LS:201)

### 2.15 Why should call be the default? (Asynchronous messaging, texting analogy)
- "This is how people text: few send a message and then do nothing until the reply comes" (LS:913).

### 2.16 Why should the beginner type code? / Why should AI speak for you?
- "**Do not type programs by hand. Have the LLM write them.**" (LP:15)
- Yet: "*If we want to talk to an AI, we will ask them ourselves*." (AIP:26)

### 2.17 Why build a full IDE? / Why depend on an SDK? (KISS)
- The non-goals "A full Cursor clone. A full VS Code replacement." (KISS:30–31); "direct HTTP calls rather than depending on a third-party SDK." (KISS:405)

### 2.18 Why argue about features? Argue about use cases.
- "discussions are centered around the *use case* for a feature, rather than the proposed feature itself." (CON:87–88)

### 2.19 Why put dates on a roadmap?
- "Dates are deliberately absent." (ROAD:16). The chunks are "**enhancement requests, not an ordered list**" (ROAD:118).

### 2.20 Why is `main` an actor? (It is not, by decision.)
- "`main` is not an actor (spec §15.1.2.2 …). It runs on the platform's ordinary program stack, with no growth and no release, and nothing supervises it." (LS:765). In chunk 1's description: "`main` not an actor" (ROAD:130).

---

## 3. History clues

### 3.1 Timeline (from documents and git dates)

| Date | Event | Source |
|---|---|---|
| 2025-02-12 | "Initial specification; anti-patterns elevated to compile-time failures" (ADD v1.0). **This is ten months before the first commit.** It may be a typo for 2026-02-12, which is the date the IR generator and assembly emitter first compiled. Ask the author. | ADD:185 |
| 2025-12-26 | First commit: "first checkin of bootstrap silica compiler for AArch64". The boot compiler is renamed `silica-boot` the same day. | git |
| 2025-12-27 | Bootstrap compiles to LLVM `.bc` and runs, then the LLVM intermediates are removed. | git |
| 2025-12-30 | "added ideas for presentations"; "added first cuts at a standard library" | git |
| 2025-12-31 | "**Removed generics for now.**" | git fb7a553edd |
| 2026-01-03 | "added beam2.0 architecture plans as a shim" | git d8a4f7544e |
| 2026-01-10 | "first successful compilation of spawn/send"; VS Code coloring files | git |
| 2026-01-17 | "first checkin on phase 2 compiler creation plan". This is the Silica-in-Silica compiler, built by the Rust bootstrap. | git |
| 2026-02-11 / 12 / 16 | Phase-2 type checker, IR generator and assembly emitter compile, then a working `fn main(){ 42 }` executable | git |
| 2026-02-18 | "first checkin of unchecked changes to support effects" | git |
| 2026-02-28 | Compiler moved into an Apple_Silicon directory, "as that is our first target" | git |
| 2026-03-10 → 13 | Memory regions added; "revised silica regions specification" | git |
| 2026-04-03 | ADD v1.1 adds the actor gen_server cross-reference | ADD:184 |
| 2026-04-06 / 15 / 19 | First actor support, first traits, first supervisor trial | git |
| 2026-04-12 | **Motto changed** from "Bad security practices should always be compiler errors!" to "Secure by default — fail soft, never fail silent". The words "at compile time" were added later. | git 88cb979dc2 |
| 2026-04-27 | AI policy and code of conduct added | git 5f7c7d269b |
| 2026-05-02 / 21 | First FFI contract (05-02); first FFI cut (05-21); "aliasing structs now produces a parser error" (05-21) | git |
| 2026-06-01 | Bootstrap compiler runs on Raspbian/Debian, the first non-Mac host | git |
| 2026-06-29 | "**removed existing data structures design and implementation. It was overly complicated for purpose.**" A new design is added. | git df118756e3 |
| 2026-07-16 | "We're all set up to begin the conversion to remove the rust bootstrap compiler." | git bd2cc56085 |
| 2026-07-17 → 20 | `src_selfhost`; a "dialect conversion" / "seed dialect" | git |
| 2026-08-31 | Design-principles page updated; the two small "books" added | git f528e9dfc0, e3f66a37de |
| 2026-09-02 | "selfhost compiler passes all CI trials." | git |
| 2026-09-08 | High-priority defect list and self-host plan | DDR:18; ROAD:111 |
| 2026-09-12 | **First fixed point** (self-hosting reached) | DDR:260 |
| 2026-09-17 | **Rust bootstrap crate removed.** The actor stack spec is revised: "The segmented design this row once described is withdrawn." | DDR:260; ROAD:130 |
| 2026-09-19 | Linux x86-64 first fixed point; runtime failure reporting on every target; ONE doc "Stated by Lee" | ROAD:24; DDR:128; ONE:4 |
| 2026-09-28/29 | ESP32-S3 per-core actor pinning delivered | ROAD:68 |
| 2026-10-09 | Chunk 4 "Premise corrected": the linear-records plan is withdrawn after measurement | ROAD:133 |
| 2026-10-16 | `move(ref, from, to)` builtin removed; chunk 1 delivered on hosted paths | ROAD:53, ROAD:130 |
| 2026-10-19 | Carriers: "measured idle-actor capacity on carriers (1,000,000 actors, 630 MB RSS)"; "carriers are the only execution model" | git 7da327ec18, 87e0a61e2e |
| 2026-10-21 | Fixed points on carriers for all three hosted platforms | ROAD:113, ROAD:131 |
| 2026-10-22 | "Decided by Lee …: the next development set is region safety for Project BEES" | PART:53 |
| 2026-10-23 | "Lee … is not happy with the design of the standard data structures" (chunk 15). Q18: messages copy by default, `move` on request. | ROAD:143; ROAD:133 |
| 2026-10-24 | The big memory pivot. Decisions 15–40: stack regions are not linear; no `arena(L,S)`; no family arena; everything lives on actor stacks; `copy_to` retired; `state_policy` added. | ROAD:133, ROAD:143 |
| 2026-11-04 | Chunk 15 phases 0–8 done on all hosted paths. x86-64: "35,073 pass, 0 fail". | ROAD:143 |
| 2026-11-05 / 08 | Transport as part of the language (ETF, BEAM demo); transport links design | DDR:278, DDR:284; git |

Commit volume by month: Dec-25 20, Jan 42, Feb 69, Mar 54, Apr 84, May 69, Jun 21, Jul 27, Aug 20, Sep 46, Oct 117, Nov (to 13th) 117. The sharp rise in Oct–Nov 2026 coincides with heavy agent-driven work. Commit messages from then on read like agent output ("Item N stage 1: …").

### 3.2 Phases and vocabulary of the project's own history
- **Bootstrap (Rust) → "phase 2 compiler" (Silica-in-Silica) → self-host → fixed points.** "the body below it is the 2026-09-08 plan, kept as history" (ROAD:111).
- **Emitter paths and milestones.** Apple Silicon leads, Linux AArch64 is "Lock-step", x86-64 was "copied from" AArch64, and the ESP32-S3 has board releases (ROAD:20–25).
- **Chunks 1–15** as enhancement requests (ROAD:116–143).
- **Upcoming paths:** "bare-metal AArch64 next; RISC-V after; Windows and other MCU classes later" (ROAD:151). "The BEES project lists raw AArch64 as a 1.0 platform" (ROAD:157).
- Mentioned boards: ESP32-S3 (a "byui board" in commit 146f34bf19, 2026-10-17, where "1,000 actors can now be run on the 512K…"), a Nucleo (git 3fef64a0ac, 2026-11-08), and QEMU `virt` planned (ROAD:153).

### 3.3 Reversals and withdrawals (good material for the HISTORY chapter)
1. **Generics removed** (2025-12-31, "for now"). Today the principle is "No generics".
2. **LLVM bitcode dropped** in favor of direct assembly emission (2025-12-27 onward). The future plan is direct object writers (DDR:152).
3. **Structs added and then pushed out.** Structs existed in Jan–May 2026 (e.g. "added the use of traits, structs, tuples, etc. across modules", git c97ace243c, 2026-01-31). Then came "aliasing structs now produces a parser error" (2026-05-21). Now there are "no user-declared type names" (DP:199).
4. **Motto** changed from "Bad security practices should always be compiler errors!" to "Secure by default — fail soft, never fail silent" (2026-04-12), and then gained "at compile time".
5. **Standard data structures redesigned twice.** First "overly complicated for purpose" (2026-06-29). Then chunk 15: "Lee … is not happy" (2026-10-23). A CHAMP placeholder (git c33d9dafe6, 2026-04-04) gave way to Adams WBT and Brodal–Okasaki.
6. **Rust bootstrap retired** (crate removed 2026-09-17).
7. **Segmented actor stacks withdrawn.** They were replaced by reserve-and-commit growable stacks (ROAD:130). An "older per-actor heap sketch" also existed (DDR:86).
8. **One thread per actor → carriers** (BEAM pattern). "Today an actor is its own operating-system thread; this chunk replaces that with the carriers" (ROAD:67).
9. **Region memory model, many decision reversals in two weeks** (ROAD:133). Linear stdlib records were withdrawn (2026-10-09). `arena(L,S)` was decided (10-22) and then superseded (10-24). The never-freed family arena was decided and then superseded. Owner lists were decided (Q5) and then dropped. Messages went from move-by-default (Q6) to copy-by-default (Q18). `copy_to` was retired. This chunk is the best single case study of how the author decides things.
10. **Supervision roadmap doc removed** and folded into the spec (DDR:104). The earlier "BEAM-like crash-containment notes" were removed and replaced (DDR:128).
11. **Earlier `do`-style sequence syntax** (DDR:242).

### 3.4 Influences named in the text
- **Erlang/BEAM/OTP**: gen_server, supervisors (`:one_for_one`, `:one_for_all`, `:rest_for_one`), let it crash, `call`/`cast` names, the BEAM carrier pattern, ETF wire format, Erlang-style immutable lists (DDR:158) (LS:28, LS:748, LS:927; RM:45; ROAD:131).
- **Elixir**: named only as something readers might know (LS:13, LS:28).
- **Rust**: ownership and lifetimes, used as a contrast ("No borrow-checker theatre", LS:27). It was also the bootstrap compiler's language.
- **Haskell**: `IO`/`ST`, monads (LS:29; DP:25).
- **ML/OCaml**: ADTs (LS:32). **C/C++/Java**: pointers and generics, as contrasts (LS:30, LS:33). **Go**: goroutines and channels (LS:31). **Python**: the main contrast language throughout LS.
- **Curry–Howard / type theory**: λΠ, sums and products (FV:47–55).
- **Okasaki / Brodal–Okasaki, Adams WBT, Hirai & Yamamoto (2011)**: data structures (LS:378–410).
- **Gleam**: **not mentioned** in any of the files read.
- **Hardware**: AArch64 NEON/SVE/MTE/PAC, Xtensa LX7, RISC-V (DP:67; ROAD:79).

### 3.5 People and roles
- Author: **Lee Scott Barney** ("Copyright © 2026 Lee Scott Barney", LS:11). GitHub `yenrab`. Referred to as "Lee, the project owner" (ONE:4).
- Many design decisions are logged as "Decided by Lee, YYYY-MM-DD" (PART:53, PART:61–62; ROAD:133, ROAD:143).
- Collaborators and tools: a volunteer drives the ESP32-S3 port ("A volunteer is driving it", PART:69, PART:73). AI agents do compiler work ("Fable" versus "lesser models", PART:65). There are JSON-LD agent graphs (RM:54; AIP:15).
- **Project BEES**: an external project that drives region-safety priorities and lists raw AArch64 as a 1.0 platform (PART:51–55; ROAD:157). It is not explained in the files read.

---

## 4. Interview leads

Each question comes from a gap, tension or striking statement, with its citation.

1. **"No generics", yet `OrderedMap[string, int64, mem(normal)]`, `ItemType`, `prepend[int64, mem(normal)]` and "Generic modules follow the witness conventions" (LS:219, LS:412, LS:478; DP:95–99).** Where exactly is the line between "a trait over concrete types" and generics? Is the stdlib allowed to be generic while user code is not? The 2025-12-31 commit says "Removed generics for now". Was that temporary, and when did "for now" become a principle?

2. **Structs.** DP:145 still lists `struct` as a keyword. LS:94 says there is "no `struct Foo { … }`". Git shows structs used heavily through May 2026, then "aliasing structs now produces a parser error" (2026-05-21). What made you decide that user-declared type names were themselves the problem? Was it the LLM argument (DP:201–203) or something you saw in practice?

3. **Effects are local, not transitive** (DP:19, DP:183; LS:183–185). Most effect systems propagate effects to callers. In Silica, a caller of a printing helper has no `device_io` anywhere. Doesn't that weaken "observable behavior is checked, not guessed"? Also, DP:17 says effects are "tracked in type signatures", while DP:183 says functions carry none. How do you reconcile the two?

4. **The anti-optimizer rules are mostly aspirational.** The public pages present dead code, duplicate work, redundant arithmetic and loop invariants as compile errors (RM:43; IDX:85; LS:1041–1044), but only E1055 exists (ADD:19–28). Is that gap deliberate, as a statement of intent? And rule 3.8 forbids `x * 8` "use a named constant" (ADD:147), but Silica has no shift operators and no named constants. What should a programmer write instead?

5. **Where did the "why" start?** ADD v1.0 is dated **2025-02-12** (ADD:185), ten months before the first commit (2025-12-26). Is that a typo, or was Silica on paper in early 2025? What was the first "Why does a language need X?" question you asked?

6. **The motto's evolution.** It went from "Bad security practices should always be compiler errors!" to "Secure by default — fail soft, never fail silent" (git 88cb979dc2, 2026-04-12), and then "at compile time" was added. What changed in your thinking between the two? "Fail soft" seems to give the runtime a role the first motto did not.

7. **"Intellectually honest"** (IDX:18) is an unusual goal for a language. What does dishonesty in a language look like to you? Which languages or experiences made you name honesty as the target? The word recurs throughout (LS:185, LS:334; LP:572, LP:1397).

8. **"No borrow-checker theatre"** (LS:27). What specifically is theatrical about Rust's borrow checker? Why write the bootstrap compiler in Rust anyway, then retire it (RM:82; DDR:260)?

9. **Region memory has changed a great deal.** The principle says "regions, not a garbage collector" (DP:41), but chunk 15 moved everything onto actor stacks, made `region(L,S)` "a lifetime-scoped stack area", and dropped linearity and owner lists within days (ROAD:133, ROAD:143; decisions 15–40, 2026-10-22→24). Walk us through those two weeks. What measurement or insight triggered "Premise corrected" (2026-10-09)? Is "region-based memory" still the right name for the principle?

10. **"Lee … is not happy with the design of the standard data structures"** (ROAD:143, 2026-10-23). That followed the earlier "overly complicated for purpose" teardown (git df118756e3, 2026-06-29) and a CHAMP placeholder. What did "not happy" mean? What did the first two designs teach you?

11. **Designed for LLMs, but AI must not speak for humans.** DP §8 designs the language for LLMs. LP:15 tells beginners "Do not type programs by hand. Have the LLM write them." Yet AIP:24–27 says "If we want to talk to an AI, we will ask them ourselves", and AI cannot be a co-author (AIP:12). PART:65 assigns compiler work to "Fable" and lesser models. How do you think about the line between AI as the typist and the human as the author and judge? Did the LLM-friendly principle exist before you started building Silica with agents, or did it grow out of that work?

12. **One compilation unit versus `hot_swap`.** ONE:62–64 rules out "dynamic loading of Silica code", but `hot_swap` is a built-in effect for "dynamic code load" (LS:196). Which wins? Is hot code loading, a BEAM hallmark, still part of the vision?

13. **The 8-parameter limit comes from AArch64's X0–X7** (FV:41). x86-64 System V passes only 6 integer arguments in registers. Should a language rule be tied to one chip? Does "designed for modern chips" (DP:67) mean designed around AArch64 in particular? Apple Silicon "leads" (ROAD:22).

14. **The hosted honesty problem.** On macOS and Linux, `mem(Space)` is "a discipline without guaranteed attribute differentiation" (ROAD:72; EXEC:5; LS:205), and pinning is not guaranteed (ROAD:67). Is a type that promises nothing at the hardware level on hosted targets fully "honest"? Why keep it there?

15. **Why not just use Erlang/Elixir (or Gleam)?** Silica borrows gen_server, supervisors, let it crash and the BEAM carrier pattern (LS:748; ROAD:131), and even ships a BEAM demo with ETF wire format (git e9d44f0e64). Gleam is never mentioned. What could the BEAM not give you? Was it native speed, bare metal, no GC, or effects? What was the "beam2.0 … shim" plan of 2026-01-03, and why was it abandoned?

16. **`call` has no timeout** (LS:917, LS:927), unlike gen_server's 5000 ms, and mailboxes are unbounded with no backpressure (LS:925). Is waiting forever a principled choice ("never fail silent"?) or simply not implemented yet? How does "prefer cast and cast back", the texting analogy (LS:913), relate to it?

17. **The elephant mother** (LP:27–29). Where did the supervisor-as-elephant-mother image come from? The beginner book bets that "code [that] matches that experience" (LP:23) is easier to learn. Was teaching beginners a design input from the start? The commit "added ideas for presentations" (2025-12-30) suggests a teaching context.

18. **Small oddities that may show the author's temperament.** The compiler has no `--version` flag, and its generation numbers count *down* (RM:140–142). "Dates are deliberately absent" from the roadmap (ROAD:16), yet nearly every line of it carries a date. What is the thinking behind each?

19. **Project BEES** (PART:51–55; ROAD:157). What is it? How much has a real downstream user shaped Silica's priorities, for example the decision of 2026-10-22 to make "region safety for Project BEES" the next development set?

20. **The "Why not?" half of the book.** Which "Why not?" decisions surprised you most once you had made them? Possible examples: dropping LLVM on day two (git, 2025-12-27), compiling the whole application as one unit (ONE), refusing inbound FFI (ROAD:165), keeping networking out of the language but putting transport in (ROAD:138 vs LS:201), and requiring a FailureReporter before any actor can start (LS:744).

---

## Appendix: a quick map of principle → beginner-book phrasing (useful for chapter voice)

| Principle | Beginner phrasing (LP) |
|---|---|
| Compile-time rejection | "If the compiler finds a mistake, it stops and explains. That is a gift." (LP:206) |
| Immutability | "a name that never changes is a name you can trust." (LP:309) |
| Explicit types | "You should never have to guess what kind of thing a name is." (LP:338) |
| Explicit effects | "It is honesty." (LP:572) |
| Small types / stdlib structures | "Large types made of many items and layers are naive and inefficient." (LP:749) |
| Fail soft | "do not pretend a failure is a success." (LP:1331) |
| Let it crash | "Let the calf fail. Its mother starts it again fresh" (LP:1339) |
| Anti-optimizer | "The language would rather the program say what it means than hope an optimizer guesses." (LP:1554) |
| Diagnostics | "A compiler error is not a verdict on you. It is a fact about the text." (LP:1552) |
