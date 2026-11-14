# Interview session — 2026-11-13 (fourth session)

- **Chapter:** 7, Predictability (*Leave Nothing to Chance*)
- **Topic:** why no garbage collector; the view of Rust's ownership model; the
  October 2026 memory redesign; what predictable memory opens up
- **Interviewer:** ghostwriter skill
- **Chosen because:** no interview coverage yet; it holds the most dramatic
  episode in Silica's history and several agent-recorded statements that need
  the author's confirmation.

---

**Q:** Silica's documents are unusually sharp about Rust: the beginner book
dismisses its ownership rules as "borrow-checker theatre". Yet you wrote
Silica's bootstrap compiler in Rust, and spent much of 2025 porting the BEAM to
it. What, to you, is theatrical about Rust's approach to memory?

**A:** It feels like getting all the sharing and transfers is like trying to be the producer of a musical play where the actors are all young and unstable. Given enough time, you can make it happen.

**Q:** Stay with your image. If memory in Rust is producing a musical with a
young, unstable cast, where every share and transfer has to be choreographed,
what is memory in Silica like? What's the equivalent picture?

**A:** everything is predictable. There is not sharing. Everything is done via the stack. If you pass data to a function and then try to use the variable that data was in your going to get a compiler error. no sharing.

**Q:** Getting there took a remarkable fortnight in October 2026. The design
documents show one approach after another adopted and dropped: single-owner
regions, then a per-structure arena that was safe but never gave memory back
(projected at around 170 gigabytes an hour on a busy machine), then owner lists,
reference counting, explicit copying, until everything moved onto the actors'
stacks. Take me to the day you decided on the stack. What made that the answer?

**A:** I realized that what is usually considered the heap and file data storage are two expressions of the same thing and they are both inherently unsafe for the same reason. something else may have messed with it since the last time you stored data. At the deepest, non-implementation details level, heap use and persistant storage are the same.

**Q:** That's a striking equivalence: the heap and a file are the same kind of
thing, and unsafe for the same reason, because something else may have touched
them since you last looked. If that's true, it should shape how Silica treats
persistent storage too. How does it? What does a Silica program do differently
when it reads back something it stored?

**A:** Silica's local persistant storage uses transport. The same conversion checks are used. The same codex are used. Safe transport is safe transport whether it is persistant or not. local or network.

**Q:** A fact to check. The agents' working notes record that when one of them
suggested a garbage-collector-style sweep that runs when memory crosses a
threshold, you rejected it: reclamation could not be similar to garbage
collection; it had to be completely deterministic and predictable. Is that
accurate, and why was that a hard line rather than a preference?

**A:** If it isn't deterministic, you can not later do proof of work (think LEAN proofs for code).

> Interviewer note: confirms the agent-recorded rejection (implicitly). "Proof
> of work" here means formal proofs of program correctness (as in Lean), not
> the cryptocurrency term; word carefully in the chapter.

**Q:** So determinism is what keeps the door to proof open. Is proving Silica
programs correct, with something like Lean, a real goal you're working toward?
And if it arrives, what does it make possible that isn't possible today?

**A:** Yes. you can find it in the language specification and in the development plan. If you can provide the proof of correctness before the code is written, it will make it that much easier for LLMs to implement the code correctly, assuming it is done in an LLM friendly way.

> Interviewer note: verify where the proof goal appears in the spec and the
> roadmap/development plan (silica-formal-verification-specification.md is
> one source).

**Q:** That reverses the usual order: proof first, code second, with the model
writing code to fit a proof. In that world, who writes the proof? Is that the
human's job, the part the human judges and answers for, or do you see models
writing the proofs too?

**A:** It's the humans job to write the proof. Models can assist, but the proof is the full responsibility of the human who is grounded in reality.

**Q:** Last question for this chapter. The draft lists what predictable memory
opens up: timing you can promise, actor systems that fit on tiny machines,
whole classes of vulnerability that can't be written, and capacity you can plan
because idle actors cost nothing. Which of those matters most to you, or is the
most important opportunity something that isn't on that list?

**A:** The most important thing to me is what I can't even imagine. What will interesting and interested people use this stable foundation to build? What kind of stable yet incredibly flexible systems will they build? What questions that were unfeasible to answer previously will they answer?

---

*Session closed by the interviewer after 9 questions.*
