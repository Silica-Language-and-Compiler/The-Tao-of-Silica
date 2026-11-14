# Precursors: "Unsafe Impedance" (2024) and BEAM_SEMP (2025)

Research notes for *The Tao of Silica*. This file traces two earlier projects by Silica's author: the Erlang '24 paper "Unsafe Impedance" and the BEAM_SEMP secure-RPC overlay. It follows the ideas in each that later turned up in Silica, whose first commit is 2025-12-26 (`git -C /Volumes/2T/silica log --reverse`). Each claim is cited to a file and line. No source file was modified.

**Notes on the sources (read these first)**

- The top-level `Article/unsafe_impedance_0715/unsafe-impedance-final.tex` is **0 bytes** on disk. The full text is inside `unsafe-impedance-final.zip` in the same folder (tex dated 2024-07-17). All article line numbers below refer to the `.tex` inside that zip.
- `Article outline.pages` was read by decompressing its `Index/Document.iwa` (Snappy-framed protobuf). It is dated 2024-03-20 (created) to 2024-03-25 (last saved).
- The brief said `design-principles.md`, `index.md` and `learn-silica.md` had been copied into BEAM_SEMP. **None of them are there.** They are not in the working tree, and they are not anywhere in git history on any branch (`git log --all --name-only`). BEAM_SEMP's Markdown is only `README.md`, `multiplexing and backpressure design doc.md` and `LICENSE.md` on `main`. The `origin/multiplex_dev` branch also has `Working Docs/trust_merm_design.md`, `Working Docs/trust_test_coverage_plan.plan.md` and `test/README.md`. Everything quoted from SEMP below is therefore SEMP's own material, not Silica text copied back into it. Someone should ask the author whether a different checkout or folder was meant.
- There is a `publication contract.pdf` in the article folder. Its contents were not read. It confirms only that a publication agreement exists.

---

## 1. Project one: "Unsafe Impedance: Safe Languages and Safe by Design Software" (2024)

### 1.1 What it was, and when

- **Venue:** Proceedings of the 23rd ACM SIGPLAN International Workshop on Erlang (Erlang '24), 2 September 2024, Milan, Italy. DOI `10.1145/3677995.3678196`. Received 2024-05-30, accepted 2024-06-27 (tex lines 79–87).
- **Authors:** Lee Barney (Brigham Young University–Idaho) and Adolfo Neto (Universidade Tecnológica Federal do Paraná) (tex lines 155–169).
- **Timeline:**
  - 2024-03-20 to 03-25: the outline (`Article outline.pages`).
  - 2024-05-30: submitted.
  - 2024-07-15 to 07-17: camera-ready (zip timestamps).
  - 2024-09-02: presented.
- **Trigger:** the December 2023 multi-agency report *The Case for Memory Safe Roadmaps* and CISA's *Secure by Design* papers. The White House ONCD technical report of February 2024 was the other trigger (abstract, tex 181–182). The outline begins by citing exactly these two sources: the ONCD report URL and the CISA "case-memory-safe-roadmaps" page.

### 1.2 Thesis

The agencies named six "memory safe languages" (C#, Go, Java, Python, Rust, Swift). The paper argues that this label is "necessary but insufficient," because every one of those languages lets unsafe code be written or loaded, and the unsafe code can then be hidden. To measure how hard a language makes this, it proposes a new axis, **unsafe impedance**. It then proposes an organizational stopgap for BEAM shops, the **Unsafe Acceptance Process (UAP)**.

> "All of the MSLs mentioned in the articles published by these security agencies allow memory unsafe code to be directly written in the language or loaded from libraries. If unsafe code is written or loaded to produce a product, the product is then is written using unsafe code. This implies that moving to MSLs is necessary but insufficient." (tex 259)

> "Unsafe impedance … is also a way to aid creators of MSLs as they contemplate the design of their new language." (tex 259)

The second sentence is worth flagging for the book. In 2024 the paper already names *language creators* as an audience.

### 1.3 Key ideas

1. **Secure by default, redefined for languages.** The paper takes CISA's product definition and applies it to a language:
   > "*Languages are secure by default if they are created in a way that protects against the production of all types of Common Vulnerability and Exposures (CVEs).*" (tex 277)
2. **Spatial and temporal taxonomy of memory CVEs.** Spatial means buffer overflow and underflow, out-of-bounds indexing, pointer arithmetic and uninitialized reads. Temporal means use-after-free, double free, dangling pointers, leaks and data races (Table 1, tex 281–299). The March outline had a longer list, including "Stack Clashing," "Iterator and Reference Invalidation" and "Time-of-Check to Time-of-Use Bugs."
3. **The unsafe impedance scale: none, low, high, infinite.**
   > "We define the difficulty experienced by programmers when when complying with these requirements as *unsafe impedance*. Choosing languages with a high unsafe impedance as part of the product design makes it easier to claim that the product is secure by design." (tex 305)
   > "Languages that do not allow any writing, loading, or use of unsafe code we define as having *infinite unsafe impedance*." (tex 317)
4. **Visibility is part of safety.** The paper keeps faulting languages for having no visual marker of unsafety:
   - On C#: "there is no verbiage or any other indicator stating that this code, and code using the results of this code, are unsafe." (tex 323)
   - On Java: "The **native** keyword is insufficient in that a novice reading the code is not directly told the code may be unsafe." (tex 385)
   - On Go: "There is no requirement enforced by the Go language's syntax to indicate that a variable is unsafe." (tex 365)
5. **Hiding unsafe code behind safe-looking wrappers is the core danger.** The paper quotes the Rust FFI guidance approvingly as evidence *against* Rust:
   > "It is common to hide the use of unsafe code in Rust by writing functions that show themselves as being safe … the Rust documentation states that one of these unsafe libraries 'can choose to expose only the safe, high-level interface and hide the unsafe internal details'." (tex 447)
   >
   > On the BEAM: "It is possible to use the **create_array** function from Erlang code without knowing it is unsafe. BEAM languages such as Erlang and Elixir can hide unsafe code in much the same way Rust, Swift, and the other languages mentioned do." (tex 535)
6. **Shared address space is the real problem with FFI.** On Python's ctypes: "the library uses the memory space of the Python REPL. This gives any security vulnerability access to any data and code in the REPL's memory space." (tex 403–405). The same charge is made against Rust (tex 465) and Swift (tex 474).
7. **The BEAM is good but compromised by NIFs.** The paper quotes the Erlang documentation: "An erroneously implemented native function can cause a VM internal state inconsistency, which can cause a crash of the VM, or miscellaneous misbehaviors of the VM at any point after the call to the native function" (tex 495). It argues that without pointers and with immutable data, "nine of the ten common CVEs … are irrelevant assuming no NIFs are used" (tex 537). It rates Erlang and Elixir as *high* impedance, "in the lower end of this category due to the ability to hide the execution of unsafe code" (tex 543).
8. **Atom-table exhaustion is a known BEAM pitfall.** "it is possible to exceed the the number of atoms available since atoms are not garbage collected" (tex 539–541).
9. **The Unsafe Acceptance Process (UAP).**
   > "The purpose of any UAP is to increase unsafe impedance. The UAP must impose a significant barrier to the loading and use of potentially unsafe code." (tex 566)
   > "no programmer or software engineer should be able to independently add potentially unsafe code … Such an evaluation must be skeptical, and adverse to the addition of any NIF in its initial perspective." (tex 580)
   >
   > A NIF proposal must include six items: harm caused by not having it, a security-risk statement, the source code, tests or proofs for "all conceivable edge cases," measured speedups, and a pure-Erlang/Elixir alternative (tex 570–578).
10. **Safety over speed and reuse.**
    > "We question whether these speed and reuse decisions are still relevant." (tex 591)
    > "it is time to value safety over speed and reuse … secure by default and an infinite unsafe impedance should be the goal of every language creator and maintainer." (tex 593)
    > "These applications, however, are not secure by default since it appears there are no secure by default languages that have infinite unsafe impedance." (tex 596)

That last line is the article's open door: *no such language exists*.

### 1.4 The outline versus the final paper

The March 2024 outline is organized around a celebratory claim: "Erlang Avoids These in this Way … Elixer Avoids These in this Way" (decompressed `Document.iwa`). The published paper turned more self-critical. Erlang and Elixir are still the best-rated languages in Table 2, but the paper concedes they are only "secure by default … as long as no unsafe code is loaded and used" (tex 545). It adds the UAP because the language alone was not enough. That shift from "Erlang avoids this" to "even Erlang lets this through" is a narrative beat worth asking the author about.

### 1.5 Influences named in the folder (titles only)

Papers the author collected at the top level of `/Volumes/2T/BEAM Security Article/`:

- *Making reliable distributed systems in the presence of software errors* (Armstrong's thesis)
- *Self management and the future of software design*
- *The Oz-E project: Design guidelines for a secure multiparadigm programming language*
- *Extending Erlang for safe mobile code execution*
- *Towards secure Erlang systems*; *Secure design and verification of Erlang systems*; *A security model for functional …* (three files of identical size, so possibly the same stub)
- *Application Security of Erlang Concurrent Systems*
- *Erlang SGX: Protecting Confidential Erlang Workloads with Intel SGX*
- *Supporting Secure Coding with RefactorErl*
- *Enforcing user privacy in web applications using Erlang*
- *Erlang as an alternative to a non-functional language*
- *Convergence in language design: a case of lightning striking four times in the same place*

The `cited/` folder holds the CVE-category sources: buffer overflow and underflow, use-after-free, Dr. Memory, stack clashing, TOCTOU, race conditions, memory leaks. It also holds CISA *SecureByDesign*, *The Case for Memory Safe Roadmaps*, and the ONCD report. `refs.bib` adds the Rust FFI Omnibus, Project Panama, ctypes, `erl_nif` docs, the EEF *Secure Coding and Deployment Hardening* guide, and *The BEAM Book*.

*Oz-E* (secure language design guidelines) and *Extending Erlang for safe mobile code execution* are the most direct ancestors of "design a new language to be secure."

---

## 2. Project two: BEAM_SEMP, with TRUST and TEMPUS (August–October 2025)

### 2.1 What it was, and when

SEMP is "a secure communication network overlay for large-scale distributed systems" for BEAM nodes. It replaces standard Erlang distribution and EPMD (README.md line 4). It has two halves:

- **TRUST** (Trusted, Rapid, Unmodifiable, Secure Topology) is for stable nodes. It provides mTLS, a fingerprint whitelist, per-MFA permissions, suspicion and quarantine, and token-accelerated reconnects (README 6, 28–32).
- **TEMPUS** (Transient Entities Managed by a Peer-overlay for Unified Security) is for ephemeral nodes. It is a Cyclon gossip layer whose admission uses producer-signed, short-lived tokens, Ed25519 proof of possession, and platform attestation (README 8, 347–408). TEMPUS exists only as design prose. No `tempus_*` code exists.

**Timeline** (`git log --all`):

- 2025-08-23: earliest "Last Modified" in module headers (`trpc.erl:16`, `trust_conn.erl:20`). The code predates the repo.
- 2025-08-29: initial commit, then "fixed mTLS configuration bugs."
- 2025-09-04: "both cast and call now work between nodes. Added blacklisted modules/functions that can not be used even if you whitelist them. Instead, wrap them."
- 2025-09-06: whitelist moved from TRUST to the shared SEMP layer "in support of adding tempus."
- 2025-09-07: "added some http modules to the forbidden list."
- 2025-09-08: TEMPUS design text added to the README.
- 2025-09-17: "compared SEMP and gRPC."
- 2025-09-29 to 10-09: multiplexing and backpressure design doc; `semp_` renamed to `trust_`; `trust_listener` replaced by `trust_conn_fsm` (main ends here).
- 2025-10-23 to 10-31 (`origin/multiplex_dev` only): implementation of multiplexing, test suites, "all current tests pass."

Silica's first commit follows **56 days** after SEMP's last commit.

### 2.2 Thesis

Distributed Erlang's default trust model (one shared cookie, a full mesh, EPMD, `rpc` that can run anything) is too permissive for hostile networks. SEMP's answer is default-deny: every remote request is a single, fully authenticated, explicitly authorized MFA call over its own connection. Failures are scored locally and never explained to the caller.

> "TRUST is a **strict, request-per-connection** overlay for BEAM nodes. It replaces the Erlang distribution handshake entirely, **does not use EPMD** … Every connection executes at most **one** request (CALL or CAST) and then closes." (README 30)

> "All failures are **logged and scored locally** (suspicion/quarantine); errors are **never** sent back to remote peers." (README 32)

### 2.3 Key ideas, with citations

1. **Kill the ambient channel first.** `semp_kill_it_all:std_distribution/0` sets `dist_auto_connect` to `never`, disconnects every node, and stops `net_kernel`. It then installs a `dbg` tracer that **kills any process that calls `rpc` or `erpc`**:
   ```erlang
   %% handler: kill the *caller*
   handle_trace({trace, Pid, call, {Mod, _Fun, _Args}} = _Evt, S)
     when Mod =:= erpc; Mod =:= rpc ->
       exit(Pid, erpc_disabled),
   ```
   (`src/semp_kill_it_all.erl` 5–19, 54–58)
2. **Identity is a certificate fingerprint.** TLS 1.3 only, `verify_peer`, `fail_if_no_peer_cert`, ALPN `trust/1`. "TRUST derives **FP = SHA-512(client_cert_DER)** and treats this fingerprint as the peer identity" (README 53–55). "Unique certificate per node … Sharing a cert collapses identity" (README 277).
3. **The whitelist decides everything, and the default is `none`.** Each fingerprint maps to `none | any | #{Module => all | [{Fun, Arity}]}`. "`none` — nothing permitted (default if omitted/invalid)" (README 62). See also `semp_whitelist.erl` 1–12.
4. **A forbidden set that the whitelist cannot override.** `semp_policy:is_forbidden/3` (`src/semp_policy.erl` 36) runs *before* permissions. It bans:
   - atom creation (`list_to_atom`, `binary_to_term`, line 223)
   - native code and ports (`load_nif`, `open_port`, line 230; `erl_ddll`, line 294)
   - dynamic dispatch (`apply`, `spawn`, `send`, line 241)
   - code loading (`code`, line 290)
   - OS, file and socket stacks; tracing; registries; OTP behaviour entry points
   - SEMP's own namespaces, banned by prefix (`trust_`, `semp_`, `tempus_`; `default_prefixes/0`, line 189)

   The commit message for this has the design rule: blacklisted functions "can not be used even if you whitelist them. Instead, wrap them." (2025-09-04)
5. **Don't let the network create atoms or code.** All decoding is `binary_to_term(Bin, [safe])` (`trust_conn.erl` 570, `trpc.erl` 444). The gRPC comparison row says: "ETF terms. No atoms." (README 458).
6. **Behaviour-based trust (suspicion and quarantine).** A counter per fingerprint goes up on protocol violations, forbidden or denied MFAs, user-code exceptions and timeouts, and down on success. Past the limit (default 3, `include/semp.hrl`), the peer is quarantined and its token revoked. "Quarenteened peers require an out-of-system reset" (README 108–112, 289).
7. **No error oracle.** "The wire protocol only returns `#{t := result, value := Term}` for successful CALLs. CAST never returns anything" (README 285). The code says "close silently" at `trust_conn.erl` 118 and 125.
8. **One request, one connection, one process: a small blast radius.** "Each call isolated by connection; small blast-radius limits damage" (README 463). This avoids the complete-graph problem of distributed Erlang (README 11).
9. **Tokens are not identity.** Tokens are server-issued, short TTL, in memory only, compared in constant time, and revoked on quarantine. "a server restart invalidates all tokens (desired)" (README 83–87, 279; `trust_token.erl` 8–14).
10. **Bounded everything.** Fixed timeouts per stage, an 8 MiB frame cap and a 4 MiB argument cap (README 116–123). The multiplexing design adds per-connection windows (`max_age_ms`, `max_calls`, `idle_ms`, `max_inflight`) with GOAWAY. Its R-5 requirement reads "Preserve security: mTLS, whitelist, forbidden MFAs, **no error frames** to client" ("multiplexing and backpressure design doc.md" 19–23).
11. **OTP supervision as a security structure.** The connection process tree runs listener supervisor → connection supervisor → one `trust_conn_fsm` per socket → a worker supervisor for that connection → temporary RPC workers. Restart intensity is capped (50 restarts in 10 seconds). When a client cancels, its in-flight workers are killed (multiplexing doc; `Working Docs/trust_merm_design.md` on `multiplex_dev`).
12. **Polyglot, Swift-first clients.** "In developement. Swift first, others follow." (README 443, 460).
13. **An "unsafe" escape hatch, off by default.** The config record has `unsafe = false` and `unsafe_cookie = undefined` (`include/semp.hrl` 12–13). The README does not document what this mode does.

---

## 3. Idea-lineage table

| # | Precursor idea (source) | Where it appears in Silica | How it changed |
|---|---|---|---|
| 1 | "Secure by default" as a property of a *language* (article tex 277, 593) | README motto: "Secure by default at compile time — fail soft, never fail silent" (`/Volumes/2T/silica/README.md` 34). The earlier motto, replaced 2026-04-12 (commit 88cb979dc2), was "Bad security practices should always be compiler errors!" | It moved from a rating applied to other languages to Silica's own slogan. "At compile time" means the compiler, not a business process, carries the burden. |
| 2 | Visibility: unsafe code must be *marked* (C#, Java `native`, Go criticisms; tex 323, 365, 385) | The mandatory `dangerous_*` module prefix, transitive "all the way to the app root" (`dangerous_ffi_security_model.md` §3; README 44) | It went past Rust's local `unsafe {}` block. The marker is contagious through imports and appears in the name of the compiled artifact. |
| 3 | Hiding unsafe code behind safe-looking wrappers (tex 447, 535) | `designing_apps_with_foreign_functions.md` 330: "Do not hide dangerous calls behind innocent names … That spreads danger under a friendly API." The rule is enforced by "prohibition on direct application calls into `dangerous_*` modules" (FFI model §1, invariant 2) | The complaint about Rust and NIFs became a compile-time rule plus a style rule. |
| 4 | Shared address space makes FFI unsafe (ctypes/Rust/Swift; tex 403–405, 465, 474) | `dangerous_ffi_security_model.md` §2: "It is not a sandbox … For untrusted native code, the stronger isolation choice is a helper process or brokered IPC." `brokered_ipc_isolation_architecture.md` "Core Safety Principle": "The unsafe library must never be reachable through an in-process FFI boundary" | Silica says outright that same-process FFI cannot be made safe. It offers a three-process broker design (dated 2026-03-19, still design only). |
| 5 | NIF crashes corrupt the whole VM (`erl_nif` warning; tex 495) | Guarded FFI: native faults inside a prepared boundary terminate *only the dangerous actor*, and its supervisor decides what happens next (FFI model §12, invariants 10–11) | The "whole VM dies" failure was narrowed to "one actor dies, let it crash." Silica still admits the limit: "non-faulting corruption is not detectable." |
| 6 | Infinite unsafe impedance as the ideal (tex 317, 593, 596) | Spec §20.4: "Networking is not part of the Silica language" and is reached only through Fifi in dangerous actors; `transport_links_design.md`; FFI is wrapper-first with "no raw pointer, `void *`, or function pointer exposure" (FFI model §4) | Silica does not reach infinity, because Fifi exists. It raises impedance structurally instead: actor-only calls, cast-only workers, a separate `dangerous_actor_ref` type, a separate registry, sidecar metadata, and structural taint. |
| 7 | UAP: unsafe code needs skeptical *review* artifacts (tex 566–583) | Sidecar `.meta`, a generated `silica.link` manifest, the `dangerous_exposure_source/` tree, and an explicit "Audit Checklist" and "Red flags" list (FFI model §5, §15) | The UAP's human checklist became build artifacts the compiler and linker check. The human review that remains is documented ("Wrapper review remains a human and tooling responsibility," §4). |
| 8 | Remove pointers and mutability to eliminate spatial and temporal CVEs (tex 537, Table 1) | Design principles 4–6: region memory, "A dangling pointer is not a representable value," "Heap is an effect" (`docs/design-principles.md` 39–61) | Erlang avoids these CVEs by using a GC and banning pointers. Silica keeps references but ties them to regions in the type system. The answer to "can a systems language without GC eliminate Table 1?" is a type system. |
| 9 | Atom-table exhaustion (article tex 539–541); SEMP bans `list_to_atom`/`binary_to_term` and uses `[safe]` (`semp_policy.erl` 223; `trust_conn.erl` 570) | Atoms are interned at compile time and "never created at run time" (spec §4.1.7; spec line 9667). Transport `decode`: "Unknown atoms are rejected, not created … the one visible difference from `binary_to_term`" (`transport_serialization_design.md` 1284–1286) | A runtime policy and a coding guideline became a language invariant. |
| 10 | SEMP forbidden set: no code loading, no `os`/command execution, no `apply` from remote input (`semp_policy.erl` 241, 290; commit 2025-09-04) | FFI spec §7.2: tainted data "must not be passed to APIs that execute commands, load dynamic code, write executable files, spawn processes, evaluate scripts"; even re-created values "remain barred from `hot_swap`, command execution, and code loading" (FFI spec 921–929, 1106). Command APIs take "an allowlisted program identifier plus an argument list" | The deny-list at the network edge became a type-level taint rule for any data that crossed a foreign boundary. Hot-swap was dropped from the roadmap (capabilities spec status note). |
| 11 | "Can not be used even if you whitelist them. Instead, wrap them." (SEMP commit 2025-09-04) | Wrapper-first FFI: "Silica does not call arbitrary C APIs directly. External libraries must be adapted behind Silica-compatible C wrapper functions" (FFI model §4) | "Wrap the dangerous thing" moved from MFA policy to the FFI boundary. |
| 12 | SEMP per-MFA whitelist: authority is explicit and default-deny (README 57–77) | Actor capabilities: protocol-typed refs that restrict `call` versus `cast`, which messages, and in what order; the same discipline applies to `dangerous_actor_ref` (`silica_actor_capabilities_specification.md` §1.2, §8.5; draft, 2026-04-11). Separate registries for ordinary, dangerous and device actors (FFI model §7, §13) | A runtime lookup table of permitted functions became a static capability carried in the reference type. The draft cites Gordon's *Actor Capabilities for Message Ordering*. |
| 13 | SEMP identity = SHA-512 of the client cert, ALPN `trust/1`, TLS 1.3 only (README 53–55) | `tls_quantum_safe_future.md` §5: result cast carries `peer_fingerprint_sha512` and `alpn`; "A policy that lists ALPN protocols rejects a handshake whose negotiated protocol is not in the list" (lines 150–167). `transport_links_design.md` 215 names "SEMP/TRUST over mutual TLS 1.3 (ALPN `trust/1`, a certificate whitelist)" as being built in Project BEES | **Direct carry-over by name.** TRUST is being re-implemented *on* Silica's transport carriers. Silica also adds hybrid post-quantum key exchange (ML-KEM). |
| 14 | SEMP: one request per connection, one process per connection, small blast radius (README 30, 463; `trust_conn_fsm`) | `tls_quantum_safe_future.md` §6 "One connection, one supervised actor … Sharing one worker across sockets is a compile-time or runtime error" (lines 171–184) | An architectural convention became a rule the compiler or runtime enforces. |
| 15 | SEMP supervision with capped intensity and temporary children (multiplexing doc; `trust_merm_design.md`) | TLS supervisor rules: transient restarts, "Handshake storms escalate; they do not grow an unbounded child table" (`tls_quantum_safe_future.md` §6 rule 8) | The same OTP pattern, restated as language-level supervisor semantics. |
| 16 | SEMP: tokens in memory only, invalidated on restart, constant-time compare (`trust_token.erl` 8–14) | TLS §6 rule 7: "Secrets live on the session actor's stack. Restart and `tls_close` zeroize"; constant-time and secret labels in `crypto-proposal-introduction.md` | Operational hygiene became a proposal for language-level secret labels. |
| 17 | SEMP: no errors to clients; log locally; suspicion scoring (README 285, 108–112) | Broker logging rules: log protocol violations, crashes and rejected operations, but "Logs must avoid leaking sensitive payload data" (`brokered_ipc_isolation_architecture.md` 331–343). Motto "fail soft, never fail silent" (README 34) | **Partial and changed.** Silica favours loud, structured *local* failure reports (`runtime_failure_reporting.md`). No suspicion or quarantine scoring was found in Silica's design docs, so this SEMP idea has not (yet) carried over. |
| 18 | SEMP: kill standard distribution and `rpc`; no ambient remote execution (`semp_kill_it_all.erl`) | Spec §1.2 "Transport Is Language … a new protocol is an addition to the language, never a program library"; carriers are dangerous actors; plain `(:tcp)` is labelled "no authentication, no encryption and no peer identity" (`transport_links_design.md` 215) | Instead of tearing out an unsafe default at runtime, Silica never ships one. Transport is explicit, typed and effect-checked (the `transport` effect). |
| 19 | SEMP's per-connection bounded windows and size caps (multiplexing doc R-2, R-3; README 123) | Broker rule 8: "All operations are bounded by explicit size limits and time limits"; `recreate` "takes its limits as an argument" (FFI model §9) | Bounds moved from config knobs to arguments of the de-taint operation. |
| 20 | SEMP's gRPC comparison and "Swift first" polyglot clients; the `unsafe_cookie` field (README 438–465; `semp.hrl` 13) | `transport_serialization_design.md`: ETF compatibility so Silica can talk to Erlang peers; BEES's "Erlang-compatible BEAM mode with cookie authentication" (`transport_links_design.md` 215) | Interoperability with the BEAM survived. The cookie path reappears as a BEAM-compatibility mode, not as the trust model. |

---

## 4. The "Why?" questions and the "Why not?" turns

### 4.1 Questions the author was asking (2024 to 2025)

1. **Why is a language called "memory safe" when it lets you load unsafe code?** This is the whole premise of the article (tex 259, 303).
2. **Why is unsafe code allowed to look safe?** The C#, Go and Java criticisms are complaints about missing markers (tex 323, 365, 385). The Rust and NIF criticisms are complaints about encapsulation that *hides* (tex 447, 535).
3. **Why is unsafe native code allowed to break the BEAM's guarantees?** The `erl_nif` warning quote (tex 495), and Erlang being placed "in the lower end" of high impedance (tex 543).
4. **Why does loaded native code share the host's memory at all?** The ctypes and REPL argument (tex 403–410).
5. **Why do we still trade safety for speed and reuse?** "We question whether these speed and reuse decisions are still relevant" (tex 591). Heartbleed is the cautionary example.
6. **Why must safety depend on people following a process?** The UAP exists because the language could not enforce it. The paper admits that "Business practices such as UAPs can not guarantee code safety, only reduce the probability" (tex 593).
7. **(SEMP) Why does connecting two BEAM nodes give each one full power over the other?** This is why `kill_it_all` exists and why the forbidden list includes `apply`, `spawn`, `code` and `rpc` (`semp_kill_it_all.erl`; `semp_policy.erl`).
8. **(SEMP) Why should a remote peer be able to create atoms, load code, or learn why it was refused?** See the `[safe]` decoding, the atom bans, and "no error frames" (R-5).
9. **(SEMP) Why is trust a one-time handshake rather than a running judgment?** This motivated suspicion scoring and quarantine (README 106–112).

### 4.2 The "Why not?" turns

- **Article to "why not build it?"** The article ends by observing that "there are no secure by default languages that have infinite unsafe impedance" (tex 596). It also says unsafe impedance is meant "to aid creators of MSLs as they contemplate the design of their new language" (tex 259). Silica's motto, "Secure by default at compile time" (README 34), is the explicit answer. The 2026-04-12 motto change shows the bridge: "Bad security practices should always be compiler errors!" is the UAP turned into a compiler.
- **"Why not move the UAP into the compiler?"** Each UAP requirement has a mechanical counterpart in Silica:
  - "Statement of risk" became the `dangerous_*` name.
  - "Source code" and "tests" became sidecar metadata, `silica.link` and `dangerous_exposure_source/`.
  - "No engineer adds unsafe code independently" became "unsafe code cannot hide, and its dependents are visibly renamed."
- **"Why not stop patching the BEAM and own the runtime?"** SEMP spent two months pulling dangerous defaults *out* of the BEAM at runtime: a `dbg` tracer that kills `rpc` callers, persistent-term deny maps, `binary_to_term [safe]`. That is the strongest evidence that the author hit the ceiling of retrofitting. In Silica those defaults never exist: atoms are compile-time only, transport is in the language, there is no hot-swap, and tainted data cannot reach code loading.
- **"Why not make same-process FFI honest about what it can't do?"** Rather than claim safety, Silica's FFI model states "It is not a sandbox" (§1). It points to brokered IPC for untrusted code. This is the article's shared-memory critique taken to its conclusion.
- **"Why not keep TRUST, but on a better foundation?"** `transport_links_design.md` 215 shows TRUST (mTLS 1.3, ALPN `trust/1`, certificate whitelist) being rebuilt in Project BEES on Silica carriers. SEMP did not die. It became a client of Silica.

---

## 5. Interview leads (20 questions)

1. The article was co-written with Adolfo Neto for Erlang '24 (tex 155–169). How did the collaboration start, and which ideas, such as "unsafe impedance" or the UAP, were yours versus his?
2. The March 2024 outline promised sections titled "Erlang Avoids These in this Way" (`Article outline.pages`). The paper instead admits that NIFs let Erlang hide unsafe code (tex 535, 543). What changed your mind while writing?
3. You wrote that unsafe impedance should "aid creators of MSLs as they contemplate the design of their new language" (tex 259). Were you already contemplating a new language in mid-2024?
4. The conclusion says "it appears there are no secure by default languages that have infinite unsafe impedance" (tex 596). When did that sentence become a to-do item?
5. Silica still has Fifi. Where would you place Silica on your own none/low/high/infinite scale (tex 311–317), and why not infinite?
6. The paper repeatedly criticized languages for lacking a visible unsafe marker (tex 323, 385). Why did you make `dangerous_*` transitive all the way to the root artifact name (`dangerous_ffi_security_model.md` §3), when Rust's `unsafe` is only local?
7. You cited the Rust FFI guidance about exposing "only the safe, high-level interface" as a weakness (tex 447). Silica's tutorial says "Do not hide dangerous calls behind innocent names" (`designing_apps_with_foreign_functions.md` 330). Is that rule a direct reply to Rust?
8. The UAP demanded six proofs before admitting a NIF (tex 570–578). Which of them became compiler or linker checks in Silica, and which remain human review?
9. Your motto changed on 2026-04-12 from "Bad security practices should always be compiler errors!" to "Secure by default — fail soft, never fail silent" (Silica commit 88cb979dc2). Why the change, and why the later addition of "at compile time"?
10. The article argued that loaded libraries share the host's memory space (tex 403–410). Silica's FFI model says "It is not a sandbox" and points to brokered IPC (§2, §16). Why design a three-process broker (2026-03-19) and not implement it yet?
11. You quoted the `erl_nif` warning that one bad NIF can corrupt the whole VM (tex 495). How did that shape the decision that a guarded native fault kills only the dangerous actor (FFI model §12)?
12. `semp_kill_it_all.erl` uses a `dbg` tracer to kill any process that calls `rpc` or `erpc` (lines 22–58). What were you defending against, and did writing it convince you the BEAM couldn't be secured from inside?
13. The 2025-09-04 SEMP commit says forbidden functions "can not be used even if you whitelist them. Instead, wrap them." Is that the seed of Silica's wrapper-first FFI rule (FFI model §4)?
14. SEMP bans `list_to_atom` and uses `binary_to_term(..., [safe])` (`semp_policy.erl` 223; `trust_conn.erl` 570). Silica never creates atoms at run time (spec §4.1.7). Was atom exhaustion (article tex 539) the reason atoms are compile-time only?
15. SEMP never sends error details to a remote peer (README 32, 285), yet Silica's motto is "never fail silent." How do you reconcile silence toward attackers with loudness toward operators?
16. SEMP's suspicion/quarantine scoring (README 106–112, 289) has no counterpart in Silica's design documents. Was it dropped, deferred to BEES, or rethought as supervision?
17. SEMP restricted remote callers with a per-MFA whitelist. Silica's draft actor-capabilities spec restricts senders with protocol-typed references (§1.2, §8.5). Did the whitelist lead you to Gordon's *Actor Capabilities for Message Ordering*?
18. SEMP's last commit was 2025-10-31 and Silica's first was 2025-12-26. What happened in those eight weeks? Was there a specific failure, benchmark or conversation that made you start a language instead of finishing SEMP?
19. `transport_links_design.md` 215 says SEMP/TRUST (mTLS 1.3, ALPN `trust/1`, certificate whitelist) is being rebuilt in Project BEES on Silica carriers. Is BEES SEMP's second life? What does Silica make possible that Erlang did not?
20. SEMP planned "Swift first" clients (README 443) and TEMPUS used App Attest and Play Integrity (README 405–406). Was mobile or edge deployment part of what pushed you toward a native, GC-free language for "modern chips" (design principle 7)?

---

## 6. Short summary for chapter planning

- **2024, the diagnosis.** "Memory safe" is not enough. What matters is how hard a language makes it to write, load and *hide* unsafe code. The ideal is "infinite unsafe impedance," and no such language exists. Until one does, use a skeptical human process (the UAP).
- **2025, the retrofit.** SEMP tried to make BEAM networking secure by default from the outside: kill standard distribution, whitelist by certificate fingerprint, forbid code loading, atom creation and NIF loading even when whitelisted, give no errors to peers, and give every connection its own process. It worked, but every safeguard was a patch on top of permissive defaults.
- **2025-12-26 onward, the rebuild.** Silica moves each patch into the language:
  - The UAP became the `dangerous_*` naming rule, cast-only FFI worker actors, structural taint, and audit metadata.
  - The atom ban became compile-time atoms.
  - The forbidden code-loading list became taint barriers.
  - The fingerprint whitelist and one-actor-per-connection model reappear almost verbatim in the TLS design.
  - TRUST itself is being rebuilt on Silica's transport carriers in Project BEES.
