# Silica subsystem design documents: principles, rationale, and interview leads

Research notes for *The Tao of Silica*. Compiled 2026-11-13 from the compiler's subsystem design documents. Nothing in the source tree was modified.

## How to read the citations

- `DD/` means `/Volumes/2T/silica/compiler/design_documents/`. `C/` means `/Volumes/2T/silica/compiler/`.
- Citations take the form `file:line`. The line numbers were checked against the files on 2026-11-13. The documents are living records that the agents revise often, so a line number may drift by a few lines. Search for the quoted phrase if a line does not match.
- Many documents are written in the voice of an implementing agent (often "Fable") and record Lee's decisions with dates, for example "Decided by Lee, 2026-10-23". Treat those dated decision lines as the author's own rulings. Treat everything else as the designers' explanation of those rulings.
- Most documents carry an "Implementation status" block. A design is not a shipped feature. Each section below notes the status, so the book does not present a design as if it were built.
- Two documents outside the assigned list are quoted because the assigned ones depend on them. `DD/APPLICATION_IS_ONE_COMPILATION_UNIT.md` is the source of the "one compilation unit" principle. `DD/silica-specification.md:7658` and `:7668` name the "nothing-hidden rule".

---

## Part 1. Subsystem by subsystem

### 1.1 Memory: no collector, one stack per actor, release decided by the compiler

**Documents:** region_memory_safety_design.md, data_structure_redesign_requirements.md, chunk15_stack_memory_design.md, actor_growable_stack_design.md, actor_memory_budget_plan.md, list_implementation_design.md, memory-effects-aarch64-implementation-plan.md.

**Problem.** Silica has immutable, persistent data structures, the way Erlang does. The BEAM relies on a per-process garbage collector to learn when a shared node is dead. Silica refuses a collector, so it must answer the same question another way. The memory story in these documents is the search for that answer. It ran from linear owned regions, to a never-freed arena for each structure family, to the current design: everything lives on the actor's own stack, and the compiler decides when memory is released.

**Principles embodied.**

1. **No garbage collector, and nothing that behaves like one.** This is stated as a binding decision, not a preference:
   > "**Reclamation is completely deterministic and predictable. Nothing similar to garbage collection**: no thresholds, no sweeps, nothing done 'every so often'." (DD/data_structure_redesign_requirements.md:66, decision 4, Lee 2026-10-24)

   The non-goals list of the redesign is one line long: "A garbage collector." (DD/data_structure_redesign_requirements.md:194). The detailed design repeats the rule as an operating rule for every section: "Reclamation is deterministic everywhere: there is no threshold, no sweep and nothing done 'every so often' (decision 4); every cost below is stated in operations proportional to a quantity the program controls." (DD/chunk15_stack_memory_design.md:6). Even the fallback path is chosen at compile time: "Which path is taken is decided at compile time, not at run time." (DD/region_memory_safety_design.md:1232).

2. **An actor owns one stack, and everything it computes lives there.** "An actor owns one stack. Everything the actor computes lives in that stack" (DD/chunk15_stack_memory_design.md:27). Escaping values are delivered by destination-passing or evacuated when the frame returns. Actor state sits at the base of the stack. "Nothing in a frame is freed individually; the frame's pop frees all of it (Lee's cleanup-on-pop rule)." (DD/chunk15_stack_memory_design.md:29).

3. **Isolation is the floor.** "**Fundamental rule**: Actors never share mutable data." (DD/actor_growable_stack_design.md:68). The one named exception is shared atomic regions. Even that is narrowed to word-sized scalars, so that it is "the one place actors share mutable memory, and only through atomic operations" (DD/region_memory_safety_design.md:644, Q7, Lee 2026-10-23). A lock-free stack that stored a pointer into normal memory inside an atomic cell was rejected and removed from the specification on the same line.

4. **Messages copy, as on the BEAM, but sharing inside a message is preserved.** The requirements compare Silica with the BEAM directly:
   > "So the BEAM gets reuse through sharing inside one process and isolation through copying between processes, and it never moves. It needs a garbage collector to know when a shared node is dead. Silica has no garbage collector. ... Unlike the BEAM, a Silica copy preserves sharing inside a message" (DD/data_structure_redesign_requirements.md:115)

   Decision 38 closes the last gap: "**Nothing in a message is shared with the sender**" (DD/data_structure_redesign_requirements.md:100).

5. **Persistence is not negotiable.** "**R2. Functional design stays.**" and "**R3. Reuse, and the old version survives.** An update or addition REUSES the elements (nodes) of the old structure in the new one; it does not copy them. The old structure is NOT destroyed by the update." (DD/data_structure_redesign_requirements.md:45, :47).

6. **When the proof fails, the compiler says so.** Where the compiler cannot prove that the old state is dead, it falls back to copying the whole state, and it tells the programmer. "The fallback is reported" (DD/data_structure_redesign_requirements.md:81, decision 19). The detailed design proposes a strict mode that turns the warning into an error. It cites "Lee's nothing-hidden rule" as the reason to put that switch in the source (`strict state_release;`) rather than in an environment variable. Lee confirmed this on 2026-10-24 (DD/chunk15_stack_memory_design.md:421).

7. **The programmer chooses, and every choice is deterministic.** Decision 40 gives three state-area policies (`:keep_state_area`, `:shrink_after_compaction`, `:compact_on_request`), "all deterministic" (DD/data_structure_redesign_requirements.md:102). At the specification level, every spawn must name a stack policy. That requirement is "the nothing-hidden rule applied to memory" (DD/silica-specification.md:7658).

8. **Failures carry their real cause.** "Stacks grow, so 'stack exhausted' is the wrong name." The single reason was split into `:reservation_exceeded`, `:out_of_memory` and `:state_too_large` (DD/data_structure_redesign_requirements.md:101, decision 39).

9. **The priority order is correctness, then size, then scale.** "**Goal, in priority order:** no corruption; as small as possible; as many actors as possible; feasible with the runtime as it is." (DD/actor_memory_budget_plan.md:45). The board and the cloud want the same things: "The two targets differ in what binds, not in what is wanted" (DD/actor_memory_budget_plan.md:54). The targets are 1,000 actors on an ESP32-S3 and "millions" hosted.

**Rationale and the arc of decisions (good narrative material).**

- *The measured premise was wrong.* The region chunk started out to make 1,152 stdlib records linear. When the code was measured, the records turned out to hold no owned regions at all. Making them linear "would buy no safety, because an arena that is never freed cannot dangle." (DD/region_memory_safety_design.md:47).
- *Safe is not the same as usable.* "The arena is safe, but it only grows. A 1,000-key map exhausts the ESP32-S3 heap in about 740 updates" (DD/region_memory_safety_design.md:49). In §17 the cost is worked out: about 48 MB/s, "about 170 GB an hour" on a busy host. The section closes with "The arena is safe (leaks are not a §12 safety violation) but unusable for a long-running program" (DD/region_memory_safety_design.md:1042).
- *Lee's dissatisfaction drove the redesign.* "Lee is dissatisfied with the model as a whole" (DD/data_structure_redesign_requirements.md:63, decision 1). A downstream user, Project BEES, set the bar: "A long-running process's memory stays flat under load." The same passage notes that "BEES's substitute for garbage collection is evacuation" (DD/data_structure_redesign_requirements.md:185).
- *Linearity was adopted and then dropped.* Owned regions were linear (move-only) in the 2026-10-22 model. On 2026-10-24 the stack direction made that unnecessary: "Stack regions are not linear; safety is by lifetimes only" (DD/data_structure_redesign_requirements.md:78, decision 16). This is a large reversal and a good interview topic.
- *No piecemeal fixes.* "Lee decided (2026-10-12) not to patch these case by case in the emitters: reclaiming them needs to know when the last reference is gone, which is this chunk's ownership model." (DD/region_memory_safety_design.md:1524).
- *Why the new release mechanism is sound when the old one was not:* "a `drop` is placed only where the checker proved the value is owned and every later path neither names nor moves it. Scope release freed by allocation time, not by ownership, and freed moved values" (DD/region_memory_safety_design.md:574).
- *Lee's test for what deserves a check.* Buffer accesses stay checked because "an out-of-bounds write corrupts data, and an out-of-bounds read hands a wrong value onward, so both meet Lee's first criterion" (DD/region_memory_safety_design.md:193). Elsewhere the criterion is quoted as "check when the error corrupts data" (DD/data_structure_redesign_requirements.md:86, decision 24). The criterion is never written out in one place. Ask Lee to state it.
- *Honesty about silent failure.* The region survey defines its worst category plainly: "Silent means the program runs on and computes with freed, shared or garbage memory." (DD/region_memory_safety_design.md:120). Before the chunk: "No move, use-after-move or linearity diagnostic exists anywhere." (DD/region_memory_safety_design.md:100).

**Alternatives rejected.**

| Alternative | Where | Why rejected |
| --- | --- | --- |
| Tracing GC (the BEAM's per-process copying collector) | data_structure_redesign_requirements.md:109–115, :194 | Non-deterministic. Excluded as a non-goal. |
| Reference counting, or counted storage per node ("biased counting") | region_memory_safety_design.md:1046–1048; data_structure_redesign_requirements.md:135 | "tried counting and was rejected and removed"; it costs space and time on every update. |
| Tracing GC or reference counting for list spines | list_implementation_design.md:19 | "reclamation follows region semantics only" |
| A never-freed arena per structure family (Q2 a) | data_structure_redesign_requirements.md:21, :63 | Chosen 2026-10-22 and superseded 2026-10-24. It only grows, and it cannot hold the freeable copies that supervised children need. |
| (A) Move the whole family of versions | data_structure_redesign_requirements.md:129 | The sender loses every version, and memory grows without reclamation. |
| (B) Exclusive ownership at send | data_structure_redesign_requirements.md:133–135 | Needs counting. |
| (C) Consume the old version on update | data_structure_redesign_requirements.md:137 | "contradicts a stated requirement" (persistence, R3). |
| A runtime layout header per cell (+8 bytes) | data_structure_redesign_requirements.md:39 (Q19) | Lee rejected it. The layout has to be in the type instead. |
| Segmented stacks; a fixed 1 GB stack | actor_growable_stack_design.md:11 | Replaced by one contiguous reservation per actor, defaulting to machine memory plus swap, with nothing committed at spawn. |
| Manual C/C++ memory management | actor_growable_stack_design.md:1977–1984 | "Manual discipline" leads to "Common (use-after-free)" bugs. |
| Lifetime value parameters (`L: lifetime`) | region_memory_safety_design.md:519 | A runtime argument that "means nothing at run time". Implicit per-signature quantification was chosen instead (Q10). |
| O(1) cross-actor moves | data_structure_redesign_requirements.md:68 (decision 6) | `move(x)` still copies. It only ends the sender's use of x. |

**Status.** The stack model is implemented through phase 7 on Apple Silicon and phase 8 on Linux x86-64. Linux AArch64 is in progress. The ESP32-S3 has not started (DD/chunk15_stack_memory_design.md:4). The per-space hardware behaviour of memory spaces is "mostly NOT implemented". The documents also state that distinct hardware behaviour per space is guaranteed only on OS-free systems (DD/memory-effects-aarch64-implementation-plan.md:3, :13).

---

### 1.2 Actors, isolation, and messaging

**Documents:** silica_actor_capabilities_specification.md, brokered_ipc_isolation_architecture.md, IPC_Bare.md, IPC_OS.md, IPC_RTOS.md, pid_registry_process_global_actor_gate.md, atom_actor_registry_direct_index_design.md, actor_spawn_core_affinity_os_semantics.md, actor_memory_budget_plan.md (carriers).

**Problem.** Silica takes Erlang's model (private state, mailboxes, supervision) and adds static typing. It then has to place that model on three very different substrates: bare-metal microcontrollers, RTOS kernels, and full operating systems.

**Principles embodied.**

1. **The same model on every substrate.** The three IPC sketches share their design goals almost word for word: "No shared mutable state", "Message-oriented communication", "Deterministic execution", "Automatic supervision", "Automatic restart" (DD/IPC_Bare.md:24–37; DD/IPC_RTOS.md:22–30; DD/IPC_OS.md:18–33). Each one ends on the same sentence: "Every actor belongs to a supervisor." (DD/IPC_Bare.md:469; also the IPC_RTOS summary). The bare-metal version goes further, with "Zero dynamic allocation" (DD/IPC_Bare.md:35) and a send that "must not grow storage" (DD/IPC_Bare.md:254). These three documents are design sketches. Only the bare-metal one is partly realised, by the ESP32-S3 runtime.

2. **Interrupts do not run application logic.** "Interrupt handlers never execute application logic." (DD/IPC_Bare.md:387). An interrupt handler creates a message, queues it, and returns. The device specification repeats this as the IRQ contract (§1.4 below).

3. **Capabilities belong in the reference type.** The actor capability draft makes every actor reference carry a mode (`call` or `cast`) and a protocol:
   > "The goal is to statically prevent a class of actor bugs where messages arrive at a valid actor in an invalid lifecycle phase. Examples include sending `commit` before `begin`, `close` before `open`" (DD/silica_actor_capabilities_specification.md:29)

   The draft's acknowledged research basis is Colin S. Gordon, *Actor Capabilities for Message Ordering* (DD/silica_actor_capabilities_specification.md:20). Its rationale for putting the mode on the reference: "Silica already requires every behavior to be call-only or cast-only. Placing that distinction on the reference turns the existing behavior-side rule into an explicit capability held by callers." (DD/silica_actor_capabilities_specification.md:801).

4. **Opting out must be explicit.** "Unrestricted protocol behavior is an explicit choice, not implicit or hidden." (DD/silica_actor_capabilities_specification.md:796). The unrestricted protocol `:dynamic` and the exhausted protocol `epsilon` "must never be conflated" (DD/silica_actor_capabilities_specification.md:112).

5. **Syntax readable by people and by LLMs.** The draft's goals include "Fit Silica's no-generics, explicit-type, LLM-friendly design philosophy" (DD/silica_actor_capabilities_specification.md:38). Protocol syntax is "intentionally verbose and keyword-based ... preferred over symbolic regex-like notation for readability and machine parsing" (DD/silica_actor_capabilities_specification.md:693–703). The "no-generics" phrase dates the draft: Silica has since gained bracket generics and traits (for example `List[T, S]` and `wbt_map[K, V]`). Worth asking about.

6. **Global state goes behind an actor.** The registry is "process-global" but "actor-gated": the table lives only in the registry actor's state (DD/pid_registry_process_global_actor_gate.md:3–6). The document is candid about the limits: "Silica does not enforce 'no direct memory' at the language level. **Actor gating** is enforced by **not exporting** table primitives ... this design is about **supported** API and clear ownership of global state." (DD/pid_registry_process_global_actor_gate.md:27).

7. **Separate kinds stay separate.** There are three registries (ordinary, dangerous, device), "so a keyed cast can never reach a worker of another kind" (DD/pid_registry_process_global_actor_gate.md:18).

8. **Use whole-program facts.** Atoms get dense ids, and density "—not the order in which the compiler/linker discovers or reads literals—is what permits a **simple direct index**" (DD/atom_actor_registry_direct_index_design.md:22). The application is one compilation unit, so the atom table is fixed at build time and the registry "is allocated once and never grows or overflows" (DD/atom_actor_registry_direct_index_design.md:7). Atoms "are **not** garbage-collected in the Erlang sense" (DD/atom_actor_registry_direct_index_design.md:40).

9. **Placement belongs to the program, and the runtime does not second-guess it.** "The runtime never moves an actor on its own, and only `migrate_actor()` changes the core" (DD/actor_spawn_core_affinity_os_semantics.md:19). Hosted carriers follow the board's rule "so a program places the same way on every target" (DD/actor_memory_budget_plan.md:763). "The hosted runtime does no BEAM-style balancing of its own: a program that wants it moves actors itself" (DD/actor_memory_budget_plan.md:934). The affinity document is honest about what an operating system can promise: "No mainstream OS gives user space a perfect, eternal 'this **actor** owns core3' invariant" (DD/actor_spawn_core_affinity_os_semantics.md:13).

10. **Carriers adopt the BEAM's scheduling pattern.** Item N "replaces the thread per actor with the BEAM pattern the board already uses per core": one carrier thread per logical core, with cooperative switching only at the specification's yield points (DD/actor_memory_budget_plan.md:565–568).

**Alternatives rejected.**

- *Mixed call/cast protocol actors* are forbidden (DD/silica_actor_capabilities_specification.md:394–402).
- *A dangerous call capability* is rejected: "A dangerous call capability would blur the FFI security model and encourage request/reply FFI flows that bypass explicit reply actors." (DD/silica_actor_capabilities_specification.md:806).
- *Runtime reordering of messages to enforce protocols* is rejected. Protocols "do not introduce runtime mailbox deferral, reordering, or phase-blocking semantics" (DD/silica_actor_capabilities_specification.md:454).
- *Full multiparty session types* are a non-goal (DD/silica_actor_capabilities_specification.md:43).
- *A general hash map or Map[K,V]* is a non-goal of the registry design (DD/atom_actor_registry_direct_index_design.md:27–28).
- *Runtime load balancing in the style of the BEAM* is rejected on hosted targets (DD/actor_memory_budget_plan.md:934).

**Status.** The capability specification is "Not implemented, and still a draft". Only a simpler mode check exists today, through errors E2237 and E2238 (DD/silica_actor_capabilities_specification.md:5). The brokered IPC, IPC_OS and IPC_RTOS documents are design only. Carriers are the only model on the Mac since 2026-10-19.

---

### 1.3 Security and FFI: danger made visible, not hidden

**Documents:** dangerous_ffi_security_model.md, silica_ffi_wrapper_specification.md (the FFI is called "Fifi"), brokered_ipc_isolation_architecture.md, crypto-proposal-introduction.md, tls_quantum_safe_future.md.

**Problem.** Real programs must call C libraries for sockets, crypto and operating system services. Silica's guarantees end at the foreign boundary. The design question is how to make that boundary visible, narrow, auditable and survivable, without claiming more than it delivers.

**Principles embodied.**

1. **Honesty about what the boundary does.** "It is not a sandbox. A `dangerous_*` module name does not stop malicious or memory-unsafe C from corrupting process state." (DD/dangerous_ffi_security_model.md:11). The document's guidance for adversarial code is: "For untrusted native code, the stronger isolation choice is a helper process or brokered IPC architecture, not same-process FFI." (DD/dangerous_ffi_security_model.md:53). It ends with a three-tier risk ladder that stops at "untrusted, adversarial, parser-heavy, plugin-style, or high-risk library -> use brokered IPC or a helper process" (DD/dangerous_ffi_security_model.md:296–304).

2. **Danger is named, and the name spreads.** Any module that touches FFI, and every module that depends on one, up to the root binary, must carry the `dangerous_` prefix. "Security consequence: reviewers can identify mixed Silica/native programs without reverse-engineering link maps ... This is a visibility and enforcement mechanism, not memory isolation." (DD/dangerous_ffi_security_model.md:67). Dangerous registry keys must also start with `dangerous_` "even when the key is unique across tables, so that source code visibly marks dangerous registry use" (DD/silica_ffi_wrapper_specification.md:518).

3. **Installing a worker is separate from executing foreign code.** "Installing the worker is not the dangerous operation." (DD/dangerous_ffi_security_model.md:103). `spawn_dangerous` needs only `concurrency`. The `external_danger` effect is allowed only inside the worker's behaviour. The split exists so that an audit can answer five questions, starting with "Who is allowed to create the worker?" (DD/dangerous_ffi_security_model.md:111–117).

4. **Foreign calls go through actors, by cast only.** Application actors never call foreign wrappers directly. They `cast` to an FFI worker actor and receive the result by `cast` (DD/silica_ffi_wrapper_specification.md:33–50).

5. **Every foreign API goes through a wrapper.** "Silica does not call arbitrary external APIs directly." There are no raw pointers, no `void *`, no opaque structs, no recursive structs, no variadics, and no callbacks (DD/silica_ffi_wrapper_specification.md:31, :46–49).

6. **Calls go out only.** "Calls from C or from another language into Silica are not part of the language and are not planned." (DD/silica_ffi_wrapper_specification.md:907).

7. **Structural taint, cleared only by a validator the compiler writes.** Anything returned from foreign code is "external-danger-touched" at every depth. "User code cannot clear taint." The only way out is `recreate`, a validator the compiler derives, that takes explicit limits: "it is written by the compiler, never by the program" (DD/silica_ffi_wrapper_specification.md:44, :1051). Each call site is an audit point: "Every `recreate` call (and every transport `decode` call) is a visible de-taint point." (DD/silica_ffi_wrapper_specification.md:1109). The security model adds a caution: taint "does not mean the bytes are semantically trustworthy." (DD/dangerous_ffi_security_model.md:169).

8. **Commands are structured, not strings.** "Command execution APIs must not accept raw string commands. They must accept structured command values, such as an allowlisted program identifier plus an argument list." (DD/silica_ffi_wrapper_specification.md:929). Re-created data is still barred from code loading and command execution.

9. **When corrupted, fail closed and do not resume.** Invariant 10: "Same-process guarded FFI may fail closed by terminating the current dangerous actor/task or process; it must not resume silently after untrusted corruption." (DD/dangerous_ffi_security_model.md:243).

10. **The broker: no shared memory, no pointers across, a disposable worker.** The brokered IPC architecture states its core principle as "The unsafe library must never be reachable through an in-process FFI boundary from the safe application." (DD/brokered_ipc_isolation_architecture.md:41). Its ten rules include "No pointers cross any boundary" and "The unsafe worker is disposable and restartable" (DD/brokered_ipc_isolation_architecture.md:93–104). The broker must copy, validate and re-encode every message, and "must never translate by aliasing" (DD/brokered_ipc_isolation_architecture.md:230). Its one-sentence summary: "Unsafe functionality is placed behind a broker process, never behind an FFI boundary." (DD/brokered_ipc_isolation_architecture.md:590). Note that this document recommends Rust or Erlang for the safe side and the broker (DD/brokered_ipc_isolation_architecture.md:349). It reads as a general architecture written before Silica could fill those roles.

11. **Crypto: the compiler should be the seatbelt.** "Instead of relying on guidelines and audits, the compiler enforces safety rules." (DD/crypto-proposal-introduction.md:20). "It's like a seatbelt: you can't forget to use it because it's built into the system." (DD/crypto-proposal-introduction.md:83). Silica has no `if` and no loops, so the proposal carries constant-time discipline over to recursion: "secrets can be *data* inside a recursive computation, but must not *control* how many steps run or which path is taken" (DD/crypto-proposal-introduction.md:35).

12. **TLS: secure defaults, locked in advance.** "It locks the types, actor tree, taint rules, and algorithm profile so later work does not invent 'encrypt some bytes and `net.tcp.write`.'" (DD/tls_quantum_safe_future.md:30). Hybrid post-quantum key exchange is the default, with the reason given: "if ML-KEM were broken, hybrid still has X25519" (DD/tls_quantum_safe_future.md:59). Each connection gets exactly one supervised session actor (DD/tls_quantum_safe_future.md:184). The document explains what "first-class" does not mean: "First-class does **not** mean 'looks pure.'" (DD/tls_quantum_safe_future.md:42). It refuses shortcuts: "Do not weaken taint in any other way to make HTTPS easier." (DD/tls_quantum_safe_future.md:215). It refuses silent behaviour on the clock: "No silent skip." (DD/tls_quantum_safe_future.md:86). Mutual TLS is the server default.

**Alternatives rejected.**

| Alternative | Where | Why |
| --- | --- | --- |
| Direct, unchecked FFI from application code | silica_ffi_wrapper_specification.md:439–445 | The parser rejects it. Authority is confined to the worker. |
| Inbound callbacks from C into Silica | silica_ffi_wrapper_specification.md:903–907 | "not planned" |
| Validators written by users that clear taint | silica_ffi_wrapper_specification.md:1051 | Only the compiler-derived `recreate` clears taint. |
| A marker trait for re-creation (`impl Recreatable`) | silica_ffi_wrapper_specification.md:1055; transport_serialization_design.md:221 | "Why no declaration": it added nothing and could be forgotten. A leftover declaration is now error E2411. |
| Treating guarded FFI as a sandbox | dangerous_ffi_security_model.md:40–53 | Out of scope. Use a broker. |
| Classical-only TLS key exchange, TLS ≤1.2, 0-RTT | tls_quantum_safe_future.md:57–70 | Forbidden in the locked profile. |
| Using TLS to authenticate a local broker | tls_quantum_safe_future.md:52 | A non-goal. Local identity stays OS or MPU identity. |

**Status.** The Fifi naming, worker placement and taint rules are implemented. `recreate` exists for scalars only (DD/silica_ffi_wrapper_specification.md:1074). The crypto proposal, the TLS design and the broker are not implemented. Networking is not part of the language and is reached through Fifi.

---

### 1.4 Hardware: device workers, board packs, registers by name

**Documents:** silica_device_actor_specification.md, board_pin_builtins_design.md, porting_for_os_free_targets.md, stm32_flash_execution_design.md, memory-effects-aarch64-implementation-plan.md.

**Problem.** A systems language must let a program drive real registers. Silica must also keep hardware access inside its actor, effect and supervision discipline, and keep a program that compiles for a Mac from silently doing nothing with registers.

**Principles embodied.**

1. **Hardware access mirrors FFI access.** "This specification is the device-register counterpart to [the FFI wrapper specification]. Ordinary actors never poke MMIO." (DD/silica_device_actor_specification.md:15). The pattern carries over: install vs. execute, a typed `device_actor_ref`, a `device_` prefix that propagates to the root, cast-only access, and a third registry.

2. **One owner per window.** "Each board-legal MMIO range is owned by at most one actor." The requirements give the reason: "Two actors driving one device register block corrupts it" (DD/data_structure_redesign_requirements.md:86).

3. **Registers have names, not addresses.** "Registers are reached by name, never by address or offset, and every name, width, and access mode is checked against the device's description" (DD/silica_device_actor_specification.md:36). The port document says what this rules out: each `peek` is exactly one load. "None is invented, removed (including a `peek` whose result is unused ...), merged, split, or moved" (DD/porting_for_os_free_targets.md:140).

4. **Named exceptions, and no others.** "Reset, early panic, and IRQ **enqueue** may touch hardware **outside** any actor. No other path may." (DD/silica_device_actor_specification.md:39).

5. **Device code and foreign code do not mix.** "A compilation unit must not `use` both a `device_*` poke module and a `dangerous_*` FFI module." (DD/silica_device_actor_specification.md:38).

6. **Reject explicitly; never compile into nothing.** A hosted emitter rejects every `map_device`, `peek` or `poke` with a compile error, "including in a function nothing calls" (DD/silica_device_actor_specification.md:356–357). "`malloc` is not a device window." (DD/silica_device_actor_specification.md:359). The port document names the risk this guards against: "A hosted emitter that lets a poke prim reach its catch-all compiles the access into nothing" (DD/porting_for_os_free_targets.md:319). It also warns: "**do not** pretend `malloc` is MMIO" (DD/porting_for_os_free_targets.md:123).

7. **One front end; the targets differ only in their emitters.** "The rules ... are checked by the shared compiler, so a program is accepted or rejected for the same language reasons on every port." (DD/silica_device_actor_specification.md:354).

8. **A restart does not reset the hardware.** "A supervisor may restart a device worker. Restart does **not** reset the peripheral. The replacement behavior's first work ... must run a documented **hardware `init` / `recover`**." (DD/silica_device_actor_specification.md:333). This is "let it crash" with a physical caveat.

9. **Board capabilities stay board-specific.** "Reading and writing the GPIO pins of a board is a **capability of the two boards' compilers, not a generic one.**" (DD/board_pin_builtins_design.md:8). The signatures are identical so that "one program source compiles for either board". Flat pin numbers keep the program "free of conversions", following the "spec design rule 'no data type conversions'" (DD/board_pin_builtins_design.md:16–18).

10. **Measure, and mark what is unverified.** The STM32 flash design: "Everything not read from a file or measured is marked **unverified**." (DD/stm32_flash_execution_design.md:5). Its first rule of change: "RAM images are byte-identical to before." (:12).

**Alternatives rejected.**

- *Reusing `read_ref`/`write_ref` on the `device` memory space for MMIO* was dropped in favour of dedicated prims. Dedicated prims let a hosted emitter reject device access by name, and they keep `read_ref` RAM-only on every target (DD/porting_for_os_free_targets.md:136).
- *`call` to a device worker* is forbidden. "Rationale: a driver that also handles IRQs can deadlock if a client `call`s it on the same core." (DD/silica_device_actor_specification.md:126).
- *A vendor HAL, and user syntax for CPU registers or a general assembler* are non-goals (DD/porting_for_os_free_targets.md:306–312).
- *Pin overrides from programs* are rejected. Pins come only from the board pack (DD/transport_links_design.md, decision 12).

**Status.** Device workers are implemented on ESP32-S3_raw and STM32-L476RG_raw. The move-only rule for `device_window` and the IRQ contract are not yet enforced (DD/silica_device_actor_specification.md:12).

---

### 1.5 Failure: crash to the supervisor, one report everywhere

**Documents:** runtime_failure_reporting.md, macos_crash_handling_for_silica.md, region_memory_safety_design.md §8, porting_for_os_free_targets.md §9.1.

**Problem.** Silica follows Erlang's supervision model. Some failures (bounds checks, failed allocations, faults inside foreign code) would normally kill the whole process. The design question is which failures end one actor and which end the program, and how to report both the same way on every target.

**Principles embodied.**

1. **Crash to the supervisor.** Out-of-bounds buffer accesses, invalid sizes, list-index failures and failed allocations inside an actor "**terminate the actor** ... handled by its supervisor. Only in `main` do they remain runtime abort 71. The access is never performed, so no data is corrupted. ... This is Lee's 'crash to the supervisor'." (DD/region_memory_safety_design.md:621). The failure document states the same rule as the contract (DD/runtime_failure_reporting.md:34).

2. **`main` is not an actor.** Nothing supervises `main`, so its failures are process-fatal. This is the "nothing-hidden rule applied to the program's entry" (DD/silica-specification.md:7668).

3. **One report on every target.** The document exists "so that a program that ends abnormally reports it the same way whether it runs on macOS, Linux (AArch64 or x86-64) or bare metal on the ESP32-S3" (DD/runtime_failure_reporting.md:20). Exit statuses are fixed: 70 for a fault, 71 for a runtime abort.

4. **No foreign exit paths.** "Nothing ends a Silica process through C `abort()` (SIGABRT, status 134) or a default signal action (status 139)." (DD/runtime_failure_reporting.md:36).

5. **Leave out what you cannot supply.** "Fields a target cannot supply are left out, not made up." (DD/runtime_failure_reporting.md:44).

6. **A reporter must exist before any actor starts.** `main` must register the reporter before it starts anything, "so a death during start-up, the root supervisor's own included, always has a destination" (DD/runtime_failure_reporting.md:405).

7. **Treat a recognised foreign fault as task death, and never resume.** The macOS note: "The guarantee should be 'task death,' not 'ordinary exception from arbitrary C.'" (DD/macos_crash_handling_for_silica.md:265). "signal handler = records and escapes; it does not supervise" (:237). When runtime state may be corrupted, "the process should abort instead of pretending supervision can repair it" (:268). It lays out three FFI tiers: unsafe, guarded, and "isolated = helper process" (:279–283). The same rule holds on bare metal without signals: "A fault in foreign code ends only the FFI worker." (DD/porting_for_os_free_targets.md:218).

8. **Prefer handlers that keep no state.** The nested-fault check uses the stack pointer, not a flag: "the stack pointer test keeps no state, so nothing can go stale" (DD/runtime_failure_reporting.md:121–126).

**Why / why not.**

- *Why not keep the process-wide abort for a bounds failure?* Because inside an actor the supervisor can recover, and the bad access never happens (DD/region_memory_safety_design.md:621).
- *Why not resume after a guarded FFI fault?* "For arbitrary C FFI, you usually do **not** know that. The C code may already have corrupted valid memory before the fault occurred." (DD/macos_crash_handling_for_silica.md:130).
- *Early design vs. implementation.* The early growable-stack design recommended "Option A (send message, let actor decide)" for stack overflow (DD/actor_growable_stack_design.md:2034). The implementation ends the actor with an `(:explicit, ...)` reason and leaves the response to the supervisor. This is a clean example of the language moving toward "let it crash".

---

### 1.6 Distribution and transport: the same code from board to cloud

**Documents:** transport_serialization_design.md, transport_links_design.md, transport_hosted_status.md, porting_to_linux_x86_64_hosted.md.

**Problem.** Silica actors need to talk to other machines: another Silica program, an Erlang node, or a board over USB. They also need to treat every received byte as hostile.

**Principles embodied.**

1. **Transport is part of the language.** "**Transport is part of the language.** ... A program declares what it transports; it does not define how bytes are spelled or how a link behaves." (DD/transport_serialization_design.md:105). Formats and carriers are fixed sets of tags supplied by the language. A program cannot add its own.

2. **Decoding is validation.** "**Decoding is validation.** Every received byte is untrusted input ... The derived `decode` is the only path from wire bytes to a Silica value, it is written by the compiler and never by the program ... A type that can be decoded without a size bound is rejected at compile time." (DD/transport_serialization_design.md:120). `decode` and `recreate` are "one mechanism".

3. **Types are static, even on the wire.** "Silica never discovers a type at run time: `decode` builds the type the binding names, and anything else is `(:rejected, _)`." (DD/transport_serialization_design.md:124).

4. **Interoperate with the BEAM.** "A Silica program must be able to exchange terms with an Erlang or Elixir node: `term_to_binary` output decodes in Silica" (DD/transport_serialization_design.md:87). The full Erlang distribution protocol is planned as pure Silica on top of this layer (DD/transport_serialization_design.md:1082). This has been demonstrated end to end: a board talks to both a Silica peer and an Erlang peer over USB.

5. **Hardware stays behind device workers; sockets stay behind dangerous actors.** (DD/transport_serialization_design.md:133).

6. **Same syntax on hosts and boards.** "The link syntax is identical on hosted targets and boards." (DD/transport_links_design.md:83–84). The programmer is trusted: "Programmers are expected to know their boards." (DD/transport_links_design.md:57).

7. **A failed link is a supervised failure, not a return value.** "A link failure is a supervised actor failure, restarted under the normal supervisor policy, and is not a value the sender checks" (DD/transport_links_design.md:59–61). "No polling on hosted targets ... the supervisor's default restart policy provides the retry" (DD/transport_links_design.md:113).

8. **No sharing of hardware instances.** "**Any sharing of a UART instance is rejected at compile time**" (DD/transport_links_design.md:107).

9. **Honest status wording.** The hosted status note gives agents approved phrasings and forbids two common overstatements: "Do not write 'Linux AArch64 is not done' (stale) or 'AArch64 works' (unproven)." (DD/transport_hosted_status.md:60). It also states plainly: "No authentication, no encryption, no peer identity." (DD/transport_hosted_status.md:28).

10. **The compiler is self-hosting and reproducible.** "The Rust bootstrap and the `src/` seed tree are retired. Every Silica compiler is now built from `src/` by a published Silica compiler" (DD/porting_to_linux_x86_64_hosted.md:9). Ports are judged by a byte-identical fixed point: "gen3 byte-identical to gen2" (:352). The first native build emitted assembly byte-identical to the Mac cross compiler's (:353).

**Alternatives rejected.** A per-type `impl Transportable` declaration was dropped ("Why no declaration", DD/transport_serialization_design.md:221). So was passing the link as an extra `spawn_dangerous` argument, in favour of a declared `carried_on` form (DD/transport_links_design.md decision 8). Link-specific backoff and send-and-receive trials on boards were rejected (decisions 14, 15).

---

### 1.7 The compiler's own shape: SIR and SIMD

**Documents:** C/sir_design_spec.md, C/vectorizable_trait_description_spec.md (introduction and rationale only).

**Principles.** SIR is "Functional-design friendly", "LLM-friendly", and carries "Explicit types on every term" and "Explicit effects on every call". It uses "Named identifiers" rather than numeric SSA ids, and a "Small, fixed term vocabulary" (C/sir_design_spec.md:17–43). "LLVM is not used in the pipeline except possibly as the assembler" (C/sir_design_spec.md:24). Its non-goals include a "**Flat memory model**: SIR uses region-based memory (regions, spaces), not a PDP-11-style uniform address space." (C/sir_design_spec.md:54).

**A historical tension worth raising.** In February 2025 the SIR specification said "Cross-chip support is not a goal; Silica targets AArch64 and its derivatives" (C/sir_design_spec.md:22, v1.1 2025-02-11). Silica now ships x86-64 and Xtensa (ESP32-S3) backends, and an STM32 (Cortex-M) board target. Ask what changed.

**SIMD.** Vectorization is opt-in ("Users explicitly opt-in by declaring types/functions vectorizable", C/vectorizable_trait_description_spec.md:11). Source code has no loops ("iteration via recursion"); the compiler "is allowed to lower recursion into loop-shaped machine code". Automatic multiversioning is "Not Supported": "the user MUST select the backend explicitly" (C/vectorizable_trait_description_spec.md:102–103). Generated code "does not perform out-of-bounds memory access". These are the explicit, nothing-hidden principles again, applied to performance.

---

## Part 2. Cross-cutting principles

Each principle below lists the documents where it appears. They are candidates for chapter spines.

**1. Isolation: no shared mutable state.**
actor_growable_stack_design.md:68; data_structure_redesign_requirements.md:100 (decision 38), :115; region_memory_safety_design.md:644 (the one atomic exception); IPC_Bare.md:20, :24–37; IPC_OS.md:14, :306–312; IPC_RTOS.md:22–30; brokered_ipc_isolation_architecture.md:93–104; silica_device_actor_specification.md (one owner per window); transport_links_design.md:107 (no UART sharing); tls_quantum_safe_future.md:184.

**2. Capabilities and authority confined to typed actors.** Install is separate from execute. Distinct reference types are never coerced into one another.
silica_actor_capabilities_specification.md (whole); dangerous_ffi_security_model.md:99–130; silica_ffi_wrapper_specification.md:33–50; silica_device_actor_specification.md:28–41; board_pin_builtins_design.md §3; tls_quantum_safe_future.md:171–195; pid_registry_process_global_actor_gate.md:18; transport_serialization_design.md:133.

**3. Let it crash, or "crash to the supervisor".**
region_memory_safety_design.md:621; runtime_failure_reporting.md:30–34, §7; macos_crash_handling_for_silica.md:230–268; dangerous_ffi_security_model.md:243–244; porting_for_os_free_targets.md:218; transport_links_design.md:59–61, :113; tls_quantum_safe_future.md:189; silica_device_actor_specification.md:333; IPC_Bare/OS/RTOS supervision sections; data_structure_redesign_requirements.md:101 (failure reasons by cause).

**4. Determinism and predictability, with no hidden runtime behaviour.**
data_structure_redesign_requirements.md:66; chunk15_stack_memory_design.md:6; region_memory_safety_design.md:1232; actor_growable_stack_design.md §12.1; IPC_Bare.md ("Deterministic execution", "Zero dynamic allocation"); IPC_RTOS.md:26; actor_memory_budget_plan.md:763–770 (deterministic carrier placement at every core count); actor_spawn_core_affinity_os_semantics.md:19 (the runtime never moves an actor); transport_links_design.md:113 (no polling constant).

**5. Nothing hidden: explicit over implicit.**
chunk15_stack_memory_design.md:421 ("Lee's nothing-hidden rule"); region_memory_safety_design.md:519, :863; silica-specification.md:7658, :7668; silica_actor_capabilities_specification.md:796 (explicit opt-out), :38; dangerous_ffi_security_model.md:55–67 (danger named in module names); silica_ffi_wrapper_specification.md:518; vectorizable_trait_description_spec.md:11, :102; transport_serialization_design.md:124 (static receiving type); board_pin_builtins_design.md:17 ("no data type conversions"); sir_design_spec.md:35–43.

**6. The compiler, not the programmer, writes the dangerous parts.**
`recreate` (silica_ffi_wrapper_specification.md:1051); `decode` (transport_serialization_design.md:120); compiler-proven release (data_structure_redesign_requirements.md:66, :80); the type-directed message copier (data_structure_redesign_requirements.md R4.1); crypto (crypto-proposal-introduction.md:20, :83); zeroization "the compiler enforces this behind the scenes".

**7. Honesty: report, don't pretend.**
dangerous_ffi_security_model.md:11 ("not a sandbox"), :277–304; runtime_failure_reporting.md:44; chunk15_stack_memory_design.md W2300 / E2321; transport_hosted_status.md:28, :60; stm32_flash_execution_design.md:5; porting_for_os_free_targets.md:123, :319; silica_device_actor_specification.md:359; macos_crash_handling_for_silica.md:268; region_memory_safety_design.md:120 ("silent" hazards catalogued); actor_spawn_core_affinity_os_semantics.md:13. Nearly every document opens with an "Implementation status" block that separates built from designed. That is itself a cultural principle of the project.

**8. One compilation unit: the application is the program.**
APPLICATION_IS_ONE_COMPILATION_UNIT.md (whole: "Read this before designing anything in Silica", line 3; the split build "exists **only** to keep the compiler's memory down", line 36; "Treat compile memory as the thing to fix", line 65); atom_actor_registry_direct_index_design.md:7, :33–43; silica_ffi_wrapper_specification.md:1838 (link manifest over the whole program closure); transport_links_design.md (E2415 across the modules of a compile); "Libraries are source" (APPLICATION_IS_ONE_COMPILATION_UNIT.md rule 4).

**9. The same code from bare metal to the cloud.**
silica_device_actor_specification.md:354 ("accepted or rejected for the same language reasons on every port"); transport_serialization_design.md:136; transport_links_design.md:83–84; tls_quantum_safe_future.md:234 ("Same types and actor tree. Only the backend changes."); board_pin_builtins_design.md:8–11; runtime_failure_reporting.md:20; actor_memory_budget_plan.md:54, :763; IPC_Bare/IPC_RTOS/IPC_OS (one model on three substrates); porting_for_os_free_targets.md:156. This principle has a counterweight. Each target *rejects* what it cannot do, explicitly and at compile time: a hosted build rejects `peek`, and a board build rejects JSON.

**10. Erlang's model, made static and without a collector.**
data_structure_redesign_requirements.md:104–115; list_implementation_design.md:5, :45; IPC_Bare.md:9; IPC_OS.md:14; IPC_RTOS.md:9; actor_memory_budget_plan.md:565; transport_serialization_design.md:87, :1082; atom_actor_registry_direct_index_design.md:40; region_memory_safety_design.md:1215 ("as in BEAM"). Where Silica *departs* from the BEAM, the documents say so: it has no collector, it preserves sharing in copies, the runtime does no load balancing, and atoms are fixed at build time.

**11. Measure first.**
region_memory_safety_design.md:74 ("Current state, measured"), :1030–1042; chunk15_stack_memory_design.md:37; actor_memory_budget_plan.md §7, §14, §16 ("Counts are only given where verified"); stm32_flash_execution_design.md:5, §5 "What must be measured first".

**12. LLM-friendliness as a design input.**
silica_actor_capabilities_specification.md:38, :692–703; sir_design_spec.md:19, :24. The documents themselves are written for agent implementers ("status note for agents", transport_hosted_status.md:1). The workflow of Lee deciding while models implement is visible throughout (region_memory_safety_design.md:4).

---

## Part 3. "Why?" and "Why not?" moments

Short, quotable passages for chapter openings and sidebars.

1. **Why no GC?** "Silica has no garbage collector." The BEAM "needs a garbage collector to know when a shared node is dead." (DD/data_structure_redesign_requirements.md:115)
2. **Why not just never free?** "The arena is safe, but it only grows." (DD/region_memory_safety_design.md:49). About 170 GB an hour on a busy host (§17, :1039).
3. **Why not linear types for the standard library?** "an arena that is never freed cannot dangle" (DD/region_memory_safety_design.md:47). Later: "Stack regions are not linear; safety is by lifetimes only" (DD/data_structure_redesign_requirements.md:78).
4. **Why not reference counting?** It "was rejected and removed"; "the dynamic form costs space and time on every update" (DD/data_structure_redesign_requirements.md:135).
5. **Why not patch the leaks one by one?** "reclaiming them needs to know when the last reference is gone, which is this chunk's ownership model." (DD/region_memory_safety_design.md:1524)
6. **Why does `move` still copy?** "There is no O(1) cross-actor transfer." The sender's frame "can release it at once" (DD/data_structure_redesign_requirements.md:68).
7. **Why one owner for a device window?** "Two actors driving one device register block corrupts it ('check when the error corrupts data')" (DD/data_structure_redesign_requirements.md:86).
8. **Why no `call` to a device worker?** "a driver that also handles IRQs can deadlock if a client `call`s it on the same core." (DD/silica_device_actor_specification.md:126)
9. **Why no dangerous `call`?** It "would blur the FFI security model and encourage request/reply FFI flows that bypass explicit reply actors." (DD/silica_actor_capabilities_specification.md:806)
10. **Why separate install from execute?** "Installing the worker is not the dangerous operation." (DD/dangerous_ffi_security_model.md:103)
11. **Why the `dangerous_` prefix all the way up?** "reviewers can identify mixed Silica/native programs without reverse-engineering link maps" (DD/dangerous_ffi_security_model.md:67)
12. **Why not resume after a C crash?** "The C code may already have corrupted valid memory before the fault occurred." (DD/macos_crash_handling_for_silica.md:130)
13. **Why kill the actor, not the process?** "The access is never performed, so no data is corrupted. ... This is Lee's 'crash to the supervisor'." (DD/region_memory_safety_design.md:621)
14. **Why no marker trait for transportable types?** "The declaration gave the derivation nothing it could not read from the call ... and it could be forgotten" (DD/transport_serialization_design.md:221–225)
15. **Why are formats built into the language?** "A new protocol or carrier is a change to the language" (DD/transport_serialization_design.md:105)
16. **Why hybrid post-quantum TLS?** "if ML-KEM were broken, hybrid still has X25519" (DD/tls_quantum_safe_future.md:59)
17. **Why dedicated `peek`/`poke` prims?** "Dedicated prims let a hosted emitter reject device access by prim name ... and they keep `read_ref` and friends RAM-only on every target." (DD/porting_for_os_free_targets.md:136)
18. **Why round-robin carrier placement?** "it is the board's rule ... so a program places the same way on every target" (DD/actor_memory_budget_plan.md:763–766)
19. **Why a stack-pointer test in the fault handler?** "the stack pointer test keeps no state, so nothing can go stale." (DD/runtime_failure_reporting.md:121–124)
20. **Why `strict state_release;` in source, not an environment variable?** "(b) is the form consistent with 'nothing hidden'." Lee confirmed it on 2026-10-24 (DD/chunk15_stack_memory_design.md:421).
21. **Why one compilation unit?** "Whole-program facts are therefore facts of the application, decided once, over all of it" (DD/APPLICATION_IS_ONE_COMPILATION_UNIT.md:16). The split build "is not part of the language, and nothing may rely on it" (:36).
22. **Why not trust the registry to the type system?** "A determined program could still reimplement a table; this design is about **supported** API and clear ownership of global state." (DD/pid_registry_process_global_actor_gate.md:27)
23. **Why not `abort()`?** "Nothing ends a Silica process through C `abort()`" (DD/runtime_failure_reporting.md:36)
24. **Why not ask the programmer for a pin override?** Pins come only from the board pack (DD/transport_links_design.md decision 12, ~line 95).
25. **Why not a custom IR built on LLVM?** "SIR is a custom IR designed for Silica's semantics and for human and LLM comprehension. LLVM is not used in the pipeline except possibly as the assembler" (C/sir_design_spec.md:24)

---

## Part 4. Interview leads (24 questions)

1. **The no-GC line.** The requirements list "A garbage collector" as a non-goal and forbid anything "done 'every so often'" (DD/data_structure_redesign_requirements.md:66, :194). Where did this conviction come from? Was there a moment, a pause or an outage, that made it non-negotiable?
2. **"Lee is dissatisfied with the model as a whole."** (DD/data_structure_redesign_requirements.md:63). What did the family-arena model feel like from the inside, and what told you it was wrong, not just incomplete?
3. **Linear types adopted, then abandoned in two days.** Owned regions were linear on 2026-10-22. By 2026-10-24 "Stack regions are not linear; safety is by lifetimes only" (DD/data_structure_redesign_requirements.md:78). What did you see that made linearity unnecessary? Is Silica's safety story now closer to lifetimes than to Rust-style ownership?
4. **Lee's first criterion.** The documents cite "Lee's first criterion" and "check when the error corrupts data" (DD/region_memory_safety_design.md:193; DD/data_structure_redesign_requirements.md:86). Can you state your full list of criteria for what the language must check?
5. **Nothing hidden.** The nothing-hidden rule decides spellings (`strict state_release;`, DD/chunk15_stack_memory_design.md:421) and forces every spawn to name a stack policy (DD/silica-specification.md:7658). Where did the rule come from? Where does it conflict with ergonomics, and how do you settle those cases?
6. **Copy by default, even for `move`.** You made `move(x)` copy anyway and only end the sender's use: "There is no O(1) cross-actor transfer" (DD/data_structure_redesign_requirements.md:68). Was giving up zero-copy transfer painful? What would make you reconsider?
7. **Preserving sharing in copies.** "Unlike the BEAM, a Silica copy preserves sharing inside a message" (DD/data_structure_redesign_requirements.md:115). Why did that matter enough to pay for a per-message table?
8. **Crash to the supervisor.** (DD/region_memory_safety_design.md:621). How did your Erlang experience shape the decision that a bounds error kills the actor but never performs the access? Why keep abort 71 for `main`?
9. **`main` is not an actor.** (DD/silica-specification.md:7668). Why should the entry point be the one unsupervised place, and why keep it deliberately small?
10. **Not a sandbox.** The FFI security model opens with "It is not a sandbox" (DD/dangerous_ffi_security_model.md:11). Why put that admission in the first paragraph, and how do you want programmers to feel about the `dangerous_` prefix?
11. **The contagious prefix.** The `dangerous_` name spreads to the root binary (DD/dangerous_ffi_security_model.md:55–67). Did you consider a softer mechanism, such as an annotation or a manifest? Why choose naming as the enforcement tool?
12. **No inbound calls, ever.** "Calls from C or from another language into Silica are not part of the language and are not planned." (DD/silica_ffi_wrapper_specification.md:907). What do you give up? Embedding Silica as a library is one obvious cost. Why is it worth it?
13. **Only the compiler may de-taint.** `recreate` "is written by the compiler, never by the program" (DD/silica_ffi_wrapper_specification.md:1051), and `decode` is the same mechanism (DD/transport_serialization_design.md:120). Why not trust a programmer's validator?
14. **The broker document recommends Rust and Erlang.** It suggests Rust or Erlang for the safe application and Rust for the broker (DD/brokered_ipc_isolation_architecture.md:349). Was it written before Silica could play those roles? Will Silica ever host its own broker?
15. **Same code, board to cloud, with explicit rejections.** Hosted compilers reject `peek` "including in a function nothing calls" (DD/silica_device_actor_specification.md:356–357), and "a program is accepted or rejected for the same language reasons on every port" (:354). How do you reconcile "write once" with targets that refuse whole feature families?
16. **A restart doesn't reset the silicon.** (DD/silica_device_actor_specification.md:333). What has "let it crash" taught you about the physical world that Erlang, running on servers, never had to face?
17. **Registers by name.** "Registers are reached by name, never by address or offset" (DD/silica_device_actor_specification.md:36). Was this a reaction to a particular embedded experience, such as vendor HALs or C macros?
18. **Placement belongs to the programmer.** The runtime "does no BEAM-style balancing of its own" (DD/actor_memory_budget_plan.md:934) and never moves an actor on its own (DD/actor_spawn_core_affinity_os_semantics.md:19). Why reject the scheduler the BEAM is famous for?
19. **One compilation unit.** "Read this before designing anything in Silica" (DD/APPLICATION_IS_ONE_COMPILATION_UNIT.md:3). What does whole-program compilation buy philosophically, beyond atom tables? How long will the split-build workaround last?
20. **Transport as language.** "A new protocol or carrier is a change to the language" (DD/transport_serialization_design.md:105). Why close the set of formats and carriers to library authors? Isn't that the opposite of Erlang's openness?
21. **Speaking ETF.** Exchanging terms with Erlang and Elixir nodes is a stated requirement (DD/transport_serialization_design.md:87). Is Silica meant to join BEAM clusters as a peer, as a replacement, or as the embedded edge of a BEAM system?
22. **AArch64-only, then not.** The SIR specification said in 2025 that "Cross-chip support is not a goal" (C/sir_design_spec.md:22). Silica now targets x86-64, Xtensa and Cortex-M. What changed your mind, and does SIR still carry AArch64 assumptions?
23. **"No-generics, explicit-type, LLM-friendly."** The capabilities draft lists this as Silica's design philosophy (DD/silica_actor_capabilities_specification.md:38), but Silica now has bracket generics and traits. How has "LLM-friendly" shaped the language, and was dropping "no-generics" a concession?
24. **Writing for agents.** The documents carry status blocks, "Wording to use" rules ("Do not write 'AArch64 works' (unproven)", DD/transport_hosted_status.md:60), and dated "Decided by Lee" lines. How has building Silica with AI implementers shaped the principles themselves, for example the emphasis on honesty, measurement and explicitness?

---

## Appendix: status cautions for chapter drafts

- **Implemented or largely implemented:** the stack memory model on Apple Silicon and Linux x86-64 (DD/chunk15_stack_memory_design.md:4); runtime failure reporting on all targets; Fifi naming, worker placement and taint; device workers and pin builtins on ESP32-S3 and STM32; atom-indexed registries; carriers on the Mac; transport `encode`/`decode` with ETF; links for hosted targets and ESP32-S3; byte-identical fixed points on the hosted paths.
- **Design only or draft:** actor capabilities and protocols; brokered IPC; IPC_OS and IPC_RTOS; quantum-safe TLS; crypto labels; per-space hardware memory behaviour; full `recreate`; NUMA lazy page migration; STM32 flash execution (link-verified, not run on the board); the BEAM distribution protocol.
- **Superseded but worth narrating:** the never-freed family arena (Q2 a), linear owned regions, counted storage, "messages move" (Q6), and stack overflow "send message, let actor decide".
