# Interview progress

Running log kept by the `ghostwriter` skill.

## Coverage by chapter

| Ch | Title | Sessions | Status |
|---|---|---|---|
| 1 | Why? and Why Not? | 1 | woven 2026-11-13 (new sections: The wrong problem; A recovery, and a new kind of reader) |
| 2 | How We Got Here | 0 | draft (ideas + opportunities) |
| 3 | Honesty — Hide Nothing | 1 | woven 2026-11-13 (new section: Honest about the tools) |
| 4 | Transparency — Say What You Do | 1 | woven 2026-11-13 |
| 5 | Independence — Share Nothing | 1 | woven 2026-11-13 (new section: The end of one size fits all) |
| 6 | Resilience — Fail Gently, Never Silently | 1 | woven 2026-11-14 (new sections: The loop that heals, with figure; The master's studio; Helping each other up) |
| 7 | Predictability — Leave Nothing to Chance | 1 | woven 2026-11-13 (new sections: The heap and the file; Proof before code) |
| 8 | Simplicity — One Way to Do Each Thing | 1 | woven 2026-11-14 |
| 9 | Accountability — Make Danger Visible | 1 | woven 2026-11-14 (new section: For everyone who answers for software) |
| 10 | Rigor — Refuse the Almost Right | 1 | woven 2026-11-14 |
| 11 | Fidelity — Respect the Machine | 1 | woven 2026-11-14 (new figure: hourglass vs channel) |
| 12 | Connection — Speak Across Every Boundary | 1 | woven 2026-11-14 (new section: Fork the language) |

## Open threads

- **Opportunities.** Every principle chapter now ends with *What it opens up*,
  drafted from the documents. These are the narrator's reading; the author's own
  view of what each principle makes possible is the main thing to draw out.

- Verify all `% TODO-VERIFY` items (agent-recorded quotes) before weaving.
- Dates: BEAM_SEMP last commit (2025-10-09 vs 2025-10-31); additional-rules
  spec dated 2025-02-12 (typo?).

## Corrections from the author

- 2026-11-13: A crash in foreign C code ends only the dangerous actor, which is
  restarted by its supervisor; ch06 and ch09 corrected.

- 2026-11-14: Ch10 "Refuse, don't repair" described an unimplemented design as
  current. Rewritten as design intent; only the unused-value check (E1055)
  exists. Costs section adjusted.

## Sessions

### 2026-11-13 — Chapter 1 (Why? and Why Not?) + voice
Transcript: `sessions/2026-11-13-ch01-why.md`. 13 questions.

Learned:
- **Voice decided: third person.**
- The 2024 paper was not self-initiated: a member of the EEF approached Barney
  at CodeBEAM San Francisco (a professional conference) to write an article
  arguing, if the data supported it, that BEAM languages belonged on the
  agencies' memory-safe list. Barney followed the data, not the advocacy:
  honesty and truth over advocacy; neither the BEAM nor Silica is perfect.
- Earliest memory of the safety question: Java feeling far safer than the
  C/C++ Barney wrote in industry.
- **New precursor: a Rust port of the BEAM (2025)**, prompted by people asking
  what the "memory-safe" Erlang VM is written in (C). On **24 December 2025**,
  well along in that port, Barney paused and saw it was the wrong problem:
  forcing a language not designed for BEAM ideas to express them (square pegs,
  round holes). A few minutes' search found no language that could express
  the SwErl/SEMP ideas and stay memory safe; initial designs took a few hours.
- **June 2025 mini-stroke (ON THE RECORD).** Could not read; complex thought and
  speech were restricted. The Rust re-engineering work helped recovery, which
  eventually allowed the "wrong problem" insight. Now learning Tagalog.
  Author wants it told so others in similar situations know they are not
  alone.
- *Language is language, human or computer* is a **lifelong view, not the
  insight** (author correction): a self-described language geek who has loved
  languages of all kinds for decades and once considered a linguistics major.
- **Origin of LLM-friendliness:** during recovery Barney relied on LLMs for
  coding and saw them struggle with languages written for human-only
  understanding; building a language that works with what LLMs do well looked
  easier than fighting them. They struggled most with deep nests of
  user-named types (by analogy, deep inheritance) → no user-named types.
- Generics: seen as a fad that did not reduce complicatedness in practice;
  seeing the data shape lets you reason realistically. Removal is now a
  conviction, not "for now". Traits are distinct: older than generics and OO
  classes, with a different feel newcomers don't confuse with generics.
- Fifi: Barney didn't want it; added so programmers of boards and operating
  systems (cars, power, water, networks), steeped in C and the PDP-11 model,
  could adopt Silica gradually. What attracts those who do look: expressing
  the device's reality directly — memory types the chip enforces (e.g.
  atomic memory), audited/authenticated pointers.

New open threads:
- The Rust BEAM port: where is it, how far did it get, does it survive?
- The 24 December scene: where, what was on screen, what happened next.
- Traits vs generics: the standard library's type parameters (e.g. ordered
  map) — clarify for readers how this differs from generics.
- Who at the EEF (name only with permission); CodeBEAM SF year (2024?).

To verify:
- CodeBEAM San Francisco date (likely March 2024, matching the outline).

Woven (author approved): ch01 (origin of the paper, Rust port, 24 December,
recovery and LLMs, language geek), ch02 (Before Silica), ch08 (named types,
generics, traits, LLM origin), ch09 (A bridge, reluctantly built), ch11 (what
draws bare-metal programmers).

### 2026-11-13 (second) — Chapter 3 (Honesty)
Transcript: `sessions/2026-11-13-ch03-honesty.md`. 10 questions.

Learned:
- **The first dishonesty Barney saw was the optimizer.** Beyond removing no-ops
  and duplication, optimizers spend most of their effort converting PDP-11
  behaviours into modern chip behaviours — yet knowledgeable people call such
  languages "close to the metal". They aren't.
- David Chisnall's ACM article "C Is Not a Low-level Language" (2018) first
  gave words to that nagging concern; the ideas stayed at the front of
  Barney's mind from publication, but there were no tools to act at scale.
- **LLMs were the missing tool**: an "army of developers on my team" (a
  colleague's phrase), not vibe-coding. Example: SwErl–BEAM node
  communication took well over a month by hand; about 20 minutes with LLMs,
  the Erlang/BEAM docs and Barney's guidance.
- Trust in LLM code grew over time: hard to separate hype (for and against)
  from truth until used on something significant; models and tooling
  improved; more Silica code gave the models patterns.
- **AI policy is out of date**: trust must shift to the contributor using the
  tool; wording still being worked out.
- What honesty opens up: easier for LLMs to reason about, debug and extend;
  Barney uses no IDE or editor (occasionally vim), lowering cognitive load.
  For reviewers/auditors: `dangerous_` trees show where bugs most likely live;
  visible data types; "the code you see is the code that runs."
- **Hidden heap**: an "oh...crap" moment — pushing hard for behaviour without
  watching what the "highly focused, yet unscrupulous" workers produced.
  Since then: more reviews, automated where possible, multiple checks against
  the design documents.

New open threads:
- How should the new AI policy read? (Revisit when written.)
- Defaults Barney has been tempted to allow (ch03 TODO, not asked).

To verify:
- Chisnall, "C Is Not a Low-level Language: Your computer is not a fast
  PDP-11," ACM Queue 16(2), 2018 — exact title and issue.

Woven (author approved): ch03 (optimizer insight + Chisnall; Honest about the
tools; hidden-heap reaction and review practice; opportunities), ch10 (link
from refusal to the optimizer insight), ch02 (army of developers, reviews).

### 2026-11-13 (third) — Chapter 5 (Independence)
Transcript: `sessions/2026-11-13-ch05-independence.md`. 9 questions.

Learned:
- **SwErl lineage confirmed, with different lessons than drafted:** (1)
  supervisors were nearly impossible — no clean way for a crashing actor to
  report to its supervisor before disappearing, so restarts couldn't be done
  well; (2) an actor needs only stored state and a function — no hand-written
  hidden lock to wait for messages, no "spawned and alive" limbo; (3) actors
  can be fairly simple to implement; (4) trait-like code modelled on Erlang's
  templates was cumbersome and uncomfortable. "Good first exploration."
- Writing the compiler let Silica build failure reporting on what chips and
  OSes themselves can report.
- **No automatic load balancing: "Not hiding is the principle."** Programmers
  can write the balancing that best fits their application. One-size-fits-all
  was useful when code was expensive; with fast code generation Barney is no
  longer sold on it — even Silica can reasonably be forked (e.g. a unique
  codec and data shapes for transport).
- **Answer to the fragmentation critique:** the critic was right in the past.
  Communities still form around shared knowledge, but the knowledge is now how
  to make "this piece of rock" do what's needed — manipulating the language
  rather than libraries. Libraries remain and are shared, but anyone can adapt
  them to their exact need, because of today's LLMs.
- **Vision:** today's systems are static because of history (weak machines,
  humans as the bottleneck). Picture millions of distributed nodes spawning,
  using and discarding single-use actors around a smaller persistent core.
  The BEAM ("a work of genius and inspiration") assumed stable, safe
  environments; SEMP took it a step further, toward churn: devices off,
  networks down, Ethernet→Wi-Fi→Bluetooth mid-conversation, phones rebooting,
  apps stopped by calls. Devices are a mess: duplicate installs, per-device
  operating systems with a late-1950s/early-1960s design. "The operating
  system wars are over. Everybody lost… It is time to move on."
- **Organism** (github.com/yenrab/organism, draft spec v0.3): "very early
  imaginings" of what comes next — one persistent computational life across
  devices as organs; actors, messages, capabilities, runtime persistence.
  Barney sees no reason it couldn't be built in Silica and hopes to soon.
- **Verified:** Barney refused to scale back "millions of actors" to a library:
  actors tied one-to-one to threads would be a facade for a thread — "false and
  untruthful".

New open threads:
- Organism and SEMP: how SEMP's churn ideas feed Organism.

Woven (author approved): ch05 (SwErl lessons, verified refusal, The end of one
size fits all, churn vision), ch06 (SwErl supervision lesson), ch12 (new closing
section: Beyond the operating system — Organism; author chose ch12 over an
epilogue).

### 2026-11-13 (fourth) — Chapter 7 (Predictability)
Transcript: `sessions/2026-11-13-ch07-predictability.md`. 9 questions.

Learned:
- **Rust as theatre:** managing sharing and transfers is like producing a
  musical whose actors are all young and unstable — given enough time, you can
  make it happen.
- **Silica's picture:** everything predictable; no sharing; everything via the
  stack; use a variable after passing its data to a function and the compiler
  refuses.
- **The insight behind the stack decision:** the heap and file storage are two
  expressions of the same thing, unsafe for the same reason — something else
  may have changed the data since you stored it. At the deepest level, heap
  use and persistent storage are the same.
- **Local persistent storage uses transport**: same conversion checks, same
  codecs. Safe transport is safe transport, persistent or not, local or
  network.
- **Verified:** reclamation must be deterministic, not GC-like — because without
  determinism you cannot later prove the code correct (think Lean proofs).
- **Proof first:** formal proof of correctness is a goal (in the spec and the
  development plan). A proof written before the code makes it easier for LLMs
  to implement correctly, if done in an LLM-friendly way. The human writes the
  proof and bears full responsibility; models may assist.
- **Most important opportunity:** what can't yet be imagined — what interested
  people will build on a stable foundation; stable yet flexible systems;
  questions previously infeasible to answer.

To verify:
- Where formal proof appears in the specification and the development plan
  (silica-formal-verification-specification.md; ROADMAP).

Woven (author approved): ch07 (theatre image, verified determinism line, The
heap and the file, Proof before code, the unimagined opportunity), ch10 (proof
first), ch12 (storage uses transport).

### 2026-11-13 (fifth) — Chapter 4 (Transparency)
Transcript: `sessions/2026-11-13-ch04-transparency.md`. 7 questions.

Learned:
- **Verified:** 238 of 254 function-level effect declarations were decorative.
- A shift in perspective: a functional language need not put effects at the
  function level. Function-level declaration was "too gross" — the sieve too
  coarse; effects piled up and muddied the declaration. One way to do
  something; everything should do one thing and do it well.
- `do...end` blocks were tried and rejected after feedback from an engineer
  Barney respects: overused in other languages, so Silica's meaning would need
  constant explaining — cognitive load for readers, confusion for LLMs. Hence
  `sequence ... produces pure ... end`.
- **Answer to the Haskell objection:** propagating callees' effects up the
  chain loses signal in noise. That's also why `dangerous_` moved to the
  module name: pure signal.
- What it opens up: LLMs hitting a missing or unnecessary effect error know
  exactly where to fix it; several effect blocks can sit in one function and
  inside one another — the monad stands out instead of hiding.
- **Memory as an effect:** memory safety is a foundational reason for Silica;
  all direct memory use is unsafe, must be called out and intentional, with
  some pain so it doesn't happen too often with too little thought — the
  problem with memory as an invisible service.
- **Friction vs busywork:** calling something out without being obtuse is
  useful friction; busywork drives people away.

New open threads:
- The engineer who gave the do...end feedback (name only with permission).

Woven (author approved): ch04 (do...end history, coarse sieve, verified
238/254, signal vs noise, memory safety and deliberate pain, friction vs
busywork, opportunities), ch09 (dangerous_ as pure signal).

### 2026-11-14 — Chapter 10 (Rigor)
Transcript: `sessions/2026-11-14-ch10-rigor.md`. 8 questions.

Learned:
- **The gap is not deliberate:** the refusal rules are published ahead of the
  build simply because the compiler hasn't caught up yet.
- **Why refuse rather than ignore:** unused code adds complexity and another
  attack surface for bad actors. Clean up after yourself at work, at home, when
  visiting, and when changing code. Every line written could hold a bug; get
  rid of what isn't needed. Reasoning and extrapolation, **not drawn from a
  specific incident** (author has no example); present it as an argument.
- **Refusal as a check on LLM output:** the errors verify what the models did
  and say exactly what to remove, so an LLM can readily remove it.
- **The fixed point (12 Sept 2026):** Barney watched the compile; it took a few
  attempts over a few days to remove the Rust build's runtime leftovers.
  Afterwards all Rust dependencies were removed; Clang became the linker and
  assembler. Reason: unused tools should be removed from devices for the same
  reasons as unused code.
- **Opportunity:** LLM-generated code that is more succinct, more likely to be
  correct and more likely to be safer, at scale.
- **Hot code upgrade under whole-program compilation:** actively being thought
  about; Barney believes a solution exists but is not ready to discuss it.

New open threads:
- Hot code upgrade: revisit when the author is ready. Author: leave it out of
  the book for now (2026-11-14).

To verify:
- Date Rust dependencies were removed and Clang adopted (design docs / git log).

Woven (author approved): ch10 (reasons for refusal and the clean-up ethic; gap
is the compiler catching up; refusals as a check on LLM output; the fixed-point
days and removal of Rust; new first opportunity). In-place updating left out.

### 2026-11-14 (second) — Chapter 6 (Resilience)
Transcript: `sessions/2026-11-14-ch06-resilience.md`. 8 questions.

Learned:
- **Why the motto changed (April 2026):** the set of possible bad code is
  infinite; not all of it can be caught at compile time (e.g. division by a
  variable divisor) short of simulated execution. Still, catch all bad code as
  early as possible. "Boots-and-braces": compiler first, runtime second.
- **Never silent:** these are errors, not warnings; bad code is bad code. AIs
  now read the error output, and they don't mind big data sets — noise is no
  longer a reason to silence failures.
- **The repair loop:** failure → report → AI evaluation and flagging →
  proposed fix → human assessment → AI-produced fix → human assessment →
  production, with "don't do it" branches at each human step.
- **Why humans stay in (the studio of the Dutch masters):** humans are why code
  is written; code is communication between producer and user, and with AI it
  is the producer's intentions being transmitted. The masters directed;
  studio artists did most of the work. Software is and always will be creative
  work; without intention there is no creation. (Candidate also for ch01/ch03.)
- **The elephant mother:** from a documentary on African elephants watched
  decades ago (title and year not remembered) — intelligent, long-lived, caring
  for family, helping their young up when they fall. Came to mind when pondering
  how to explain supervisors. Barney has always had more interests than time.
- **Where resilience is most needed:** first among people — the trap of
  "there must be something wrong with them" thinking when failure happens, seen
  in and outside business and education. In technology: embedded systems that
  keep lives going and lift people out of poverty — electricity, water,
  farming, cars and transportation.

New open threads:
- The guarded dangerous actor as the unit of failure for foreign code (ch06
  TODO, not asked).
- Where else the studio/intention idea belongs (ch01? ch03? ch10?).

To verify:
- Nothing new from sources.

Woven (author approved): ch06 (motto change and boots-and-braces; never silent
and AI readers; The loop that heals + figures/repair-loop.tex; The master's
studio; elephant documentary; embedded systems and maintenance opportunities;
Helping each other up), ch01 (pointer to the studio section).

### 2026-11-14 (third) — Chapter 12 (Connection)
Transcript: `sessions/2026-11-14-ch12-connection.md`. 7 questions.

Learned:
- **The three positions were a debate about BEES vs the language**, not about
  whether networking matters. The last decision (transport in the language) is
  the correct one: modern devices swim in a sea of connectivity; a separate
  communication library is strange and weird at this point in history.
- **Current state (author-supplied note):** sockets still go through the FFI
  (a C sidecar) inside `dangerous_` carrier actors; `carried_on` sits on top and
  programs talk to the carrier by messages, never calling sockets themselves.
- **Plan:** an early priority is a TCP/IP stack written in Silica, so the
  dangerous FFI call can go away. Gains: the language's memory-safety contract
  ("contat" read as contract) all the way down, and networking can truly become
  part of the compiler and therefore the language.
- **Closed set of wire formats:** if transport is language, wire formats must be
  too, or the language is incomplete and self-contradictory. With LLMs a new
  format is a codec and some code. Need a different format or data shape? Fork
  the compiler and add it; if it may help others, open a pull request with
  reasoning and evidence. No twisting an existing format to fit.
- **Disposable software:** "a new time… where software is disposable. Build good
  quality. Don't plan on longevity." Not necessarily the whole program — parts.
  Replace whatever doesn't fit or makes other things harder; don't fall for the
  sunk-cost fallacy. Silica's own history bears this out.
- **BEES:** confirmed "Silica wins" ruling. BEES predates Silica conceptually and
  is one reason Silica exists (no language could do it well). As Silica grew,
  BEES plans that no longer made sense there were dropped. **Division of
  responsibilities: Silica does transport; BEES manages transport** — SEMP's
  churn and behaviour ideas go forward in BEES.
- **Opportunity:** truly distributed systems spanning mobile, IoT, personal and
  shared devices — extremely hard today. Organism is one example. User ease and
  trust could rise sharply. Today we wire fractured, independent systems
  together to simulate integration.

New open threads:
- When the Silica TCP/IP stack is built, update ch09/ch12 (FFI no longer needed
  for networking).

To verify:
- Nothing new; "Silica wins over BEES" now author-confirmed.

Woven (author approved): ch12 (the BEES/language debate; C sockets today and the
planned Silica stack; Fork the language + disposable software; BEES history,
Silica wins, transport vs management; truly distributed systems; Organism as
one example), ch09 (SEMP behaviour ideas go forward in BEES).

### 2026-11-14 (fourth) — Chapter 11 (Fidelity)
Transcript: `sessions/2026-11-14-ch11-fidelity.md`. 6 questions.

Learned:
- **Portability is not needed** when specific solutions are easy to produce (ties
  to forking and disposability). ARM first only because Barney's work and home
  machines are ARM; bought a used x86-64 machine for that port; dug out an old
  Raspberry Pi. The compiler's design means a new platform needs only a new
  emitter. Using a chip behaviour on a device without it → emitter error, build
  stops. Developers with LLMs can do the same for their applications, so compiled
  code is device-specific — not bloat, but "laser focused" on the hardware, not
  a lowest bar that reaches all hardware.
- **Why LLVM went:** LLVM uses the PDP-11 model; modern chip behaviours can't be
  exposed efficiently through it. Silly to put a broad, expressive language
  through a PDP-11 bottleneck and hope optimizers expand it back out.
- **The whiteboard images:** an hourglass (language / PDP-11 neck / optimizers /
  chip) beside Silica's path — two vertical lines with Silica at the top and the
  hardware at the bottom. Energizes people when compared. Author proposes the
  diagram for the book.
- **The harder path on boards:** the principle of exposing the hardware through
  the language; the PDP-11 legacy is alive in embedded libraries and tools.
  "Quicker is easier. But better is better." LLMs make doing better at scale far
  more feasible.
- **Who should build on boards:** everybody and anybody with a need. Problem
  solving principles are the same everywhere and always; with LLMs used as
  Barney has, that's all you need. Nobody and no software is perfect; failures
  happen; adjust and move on.
- **Measure first:** from working in the simulation industry, where even a 1%
  slowdown was wildly unacceptable; plus a lifelong predilection for correctness
  and beauty.

New open threads:
- The simulation industry years: which company/kind of simulation, when.
- A specific board and behaviour someone could finally express (ch11 TODO, not
  asked).

To verify:
- x86-64 and Raspberry Pi ports in the history (dates) — Linux x86-64 first fixed
  point 2026-09-19 per ROADMAP.

Woven (author approved): ch11 (ARM first and portability; LLVM as PDP-11
bottleneck + figures/hourglass.tex; the harder path on boards; simulation
industry and measure first; anyone with a need can build). Author approved
mentioning the simulation industry.

### 2026-11-14 (fifth) — Chapter 9 (Accountability)
Transcript: `sessions/2026-11-14-ch09-accountability.md`. 6 questions.

Learned:
- **No inbound calls — separation of roles.** To embed a Silica app in another
  system, communicate with it through transport. Calling in directly would
  bypass data checking and undermine Silica's security promises.
- **`dangerous_` spreading:** no complaints yet, though some are expected; no
  change anticipated, because the mark makes security audits easier. No
  certified-safe wrapper to stop the spread.
- **Audience:** all of them — engineers, managers, auditors, policymakers; it
  affects all their work. Takeaway: the old ways don't have to be followed; we
  have new tools, use them for what they're good at. "Tradition can be both good
  and stifling. Don't let the good get stifled."
- **Trusting users:** tech people talk about trust with users but rarely trust
  them — "trust us, we know what is best for you". New tools should let users
  express agency; tools must let them see what is happening and how trustworthy
  it is. Old systems may not want that visibility.
- **How users would see it:** through an AI they have come to trust, highlighting
  potential dangers.
- Organism: very early conceptualization; expect dramatic changes in design and
  development, but it will keep its vision.

New open threads:
- Fifi's poodle name origin (not asked).
- Capabilities and brokered isolation: plan and timing (not asked directly).

To verify:
- Nothing new.

Woven (author approved): ch09 (no inbound calls as separation of roles; the
spreading mark stays; trusting users and AI-highlighted danger; Organism early
stage; users who can see and choose; For everyone who answers for software).

### 2026-11-14 (sixth) — Chapter 8 (Simplicity)
Transcript: `sessions/2026-11-14-ch08-simplicity.md`. 6 questions.

Learned:
- **Simple has always been better, since childhood:** complicated things are
  more likely to hide problems.
- **Boundaries from the simulation industry:** with customers, one of the biggest
  things to lay out was what the software would *not* do — keeping scope creep
  down and the spec comprehensible, a document both provider and user could
  understand and rely on; a reported bug could be checked against it (bug, or
  chosen behaviour?). Working within bounds is liberating.
- **Music:** bass clarinet in junior high; fiddle lessons as an adult. Getting
  lost in the sound when you get it right is freeing. Creative acts always
  require boundaries; languages are powerful because they give limits you can
  use creatively.
- **Collections vs generics:** generics hide data shapes; Silica's data
  structures elevate them so they aren't lost and there's no question what's
  used. Different purposes.
- **Aliases rejected:** tempted to add aliases for human readability; a trusted
  sounding board (unnamed; by role) advised against — it would reduce the
  language's "amazingness" and "beauty". Held firm: easier for humans, harder for
  LLMs to generate correct code.
- **Ten years out:** like any art form, like the Dutch masters — the person
  grounded in reality who knows what they want does the judging and the
  conceptualization; AIs do the typing; humans ensure the result is what they
  wanted.

New open threads:
- Two decisions now shaped by trusted sounding boards (do...end, aliases):
  same person? Named with permission?

To verify:
- Nothing new.

Woven (author approved): ch08 (temperament: childhood, simulation-industry
boundaries, music; collections vs generics; aliases rejected; ten-year view as
the Dutch masters' studio).
