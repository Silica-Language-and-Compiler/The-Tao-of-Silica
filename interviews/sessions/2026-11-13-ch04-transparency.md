# Interview session — 2026-11-13 (fifth session)

- **Chapter:** 4, Transparency (*Say What You Do*)
- **Topic:** effects declared where the work happens; why effects left function
  signatures; local vs. spreading declarations; memory as an effect; what
  transparency opens up
- **Interviewer:** ghostwriter skill
- **Chosen because:** the only chapter with no input from the author yet.

---

**Q:** Early Silica attached effects to function signatures, as Haskell and
Koka do. By the end of September 2026 you'd ruled that functions never declare
effects; only the blocks that do the work do. The agents' notes record that
when the compiler's own source was converted, 238 of 254 function-level effect
declarations turned out to describe nothing the function itself did. Is that
accurate? And what first made you suspect that putting effects on functions was
the wrong place for them?

**A:** It is accurate. I just remember a shift in perspective. While silica is a functional programming language, that certainly doesn't mean effects have to be at a function level. I realized it was too gross of a declaration. The seive was too coarse. There would be too many effects piling up on the functin declaration. Also, it muddied the function declaration. One way to do something. Every thing should do one thing and do it well. The sequence...produces pure...end blocks came after playing with do...end blocks and rejecting them after getting feedback from another engineer I respect.

> Interviewer note: VERIFIED the 238-of-254 figure.

**Q:** Tell me about that feedback. What did the engineer you respect say about
the do...end blocks that made you drop them, and what did the replacement get
right that they didn't?

**A:** He helped me see that they were overused in other languages and that I would have to explain differences between silica's use and all the other uses. Using do...end would have added cognative load to readers and confusion for LLMs.

**Q:** Here's the objection a Haskell programmer will raise. In most effect
systems, if a helper prints, everything that calls it must admit to printing,
so you can tell from a function's type alone whether calling it touches the
world. Silica deliberately gives that up: effects stay where the work is and
don't climb the call chain. What do you say to someone who thinks that weakens
the guarantee?

**A:** That was the idea behind having the effects on the function declaration. When there are too many effects building up that include all the effects of functions that are called, signal gets lost in noise. It's one of the reasons I moved dangerouse_* out to the name of the module. That gives us pure signal.

**Q:** Signal and noise: effects declared locally where the work is, and the one
effect that must never be missed, foreign code, lifted all the way up into
module names. Now the opportunity side. Has seeing effects marked exactly where
they happen let you, your students or your AI agents do something you didn't
expect: find a bug faster, review something you couldn't before, trust a piece
of code you otherwise wouldn't?

**A:** Yes. Repeatedly the LLMs would get a compiler error because of a missing or unnecissary effect declaration and know exactly where to put the fix. it also lets me use multiple sequence...produces pure...end monads within a function and within each other. The monad stands out instead of being hid.

**Q:** The most unusual effect in Silica is memory itself: reserving storage has
to be declared like printing or talking to a device. Most languages treat memory
as an invisible service. Why make it something a program must admit to, and
who do you think gains the most from that?

**A:** Memory safety was and is a foundational reason for Silica. All direct memory use is unsafe. It needs to be called out. It has to be an intentional thing. It has to have some pain involved or it will happen to frequently with too little thought behind it. That's the problem with the invisible service approach.

**Q:** "It has to have some pain involved" is a deliberate design choice most
language designers would avoid saying out loud. How do you tell the difference
between friction that makes people think and friction that simply drives them
away to an easier language?

**A:** calling out, but not obtuse is friction. Making someone do something that is busywork drives them away.

---

*Session closed by the interviewer after 7 questions.*
