# Interview session — 2026-11-14 (tenth session)

- **Chapter:** 9, Accountability (*Make Danger Visible*)
- **Topic:** Fifi and the `dangerous_` mark; why nothing outside may call in;
  danger that cannot be wrapped; authority you can see; who this chapter is for
- **Interviewer:** ghostwriter skill
- **Chosen because:** no session of its own yet (material so far came from the
  ch01 and ch04 sessions); open gaps on audience and capabilities.

---

**Q:** Silica can call out to foreign code through Fifi, but the documents say
nothing outside may call into Silica, ruled out as a future plan too, not just
for now. Most languages want two-way interop because that's how they get
embedded and adopted. Why close that door completely?

**A:** Seperation of Roles. If someone wants to embed a Silica app in their system, the appropriate way is to use transport to communicate with it.

**Q:** So a system that wants Silica inside it talks to it as a peer, through
checked messages, not by calling into it like a library. If a C program could
call straight into a Silica function, which of Silica's promises would that
break first?

**A:** There would be no data checking. This would negatively impact the security promises Silica makes.

**Q:** One foreign library and `dangerous_` spreads up through every module above
it. Rust took the opposite view: wrap unsafe code in a safe-looking surface.
Has anyone pushed back on the spreading as too noisy or punishing? Is there any
case where you'd let a carefully audited wrapper stop the spread?

**A:** No one has complained yet, though I expect some will. I don't anticipate a change because dangerous_makes security audits easier.

**Q:** Who do you most want to read this chapter — engineers deciding whether to
use a C library, managers responsible for what ships, security auditors, or the
people writing policy (the agencies whose memory-safety guidance started this
story)? And what do you want them to take away?

**A:** I want all of them to read it. It impacts all of their work and jobs. The take away is that the old ways of doing things don't have to be followed. We have new tools. We should use them for what they are good at. Tradition can be both good and stifling. Don't let the good get stifled.

**Q:** The chapter ends with authority you can see: a program can do only what
the parts it has been handed can do, and that authority shows in the design.
Capabilities and brokered isolation are mostly planned; Organism makes
capabilities its whole security model. What does visible authority add beyond
the `dangerous_` mark, and why does it matter enough to come next?

**A:** Organism is in its very early conceptualization phase. I expect dramatic changes when it enters design and development, but it will stick to its vision. Trust is something we talk about between us tech people and the users who use our products, but we rarely trust them. It often ends up being a 'trust us, we know what is best for you' type of situation. With the new tools, we need to change that. Ease up a bit. Let them express agency. To do accomplish this, our tools need to be such that they can visually see what is happening and how trustworth it is. I'm not sure the old systems would want that much visibility. At least my experience is we don't trust technology users much at all.

**Q:** Picture an ordinary person, not a programmer, using a device built this
way. What would they actually be able to see that they can't see today, and
what choice could they make with it?

**A:** Using an AI that they have developed trust in to highlight potential dangers would be the path forward.

---

*Session closed by the interviewer after 6 questions.*
