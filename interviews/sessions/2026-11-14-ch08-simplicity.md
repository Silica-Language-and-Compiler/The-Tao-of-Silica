# Interview session — 2026-11-14 (eleventh session)

- **Chapter:** 8, Simplicity (*One Way to Do Each Thing*)
- **Topic:** one way to do each thing; where the instinct comes from; type
  parameters in the standard library vs generics; the human as judge and the
  machine as typist; what simplicity opens up
- **Interviewer:** ghostwriter skill
- **Chosen because:** no session of its own yet (named types, generics and
  traits came from the ch01 session); open gaps on temperament and the future.

---

**Q:** The design notes for a small tool the project built for itself define it
first by what it would not be: not a full editor, not a platform, not dependent
on anyone else's kit. Small, native, understandable. The same instinct runs
through the language: one way to repeat, one way to choose, one way to name.
Where does that instinct come from? Can you remember first feeling that fewer,
plainer pieces beat a rich menu?

**A:** Simple has always been better for me since I was small. The more complicated things are, the more likely they hide problems. Also, when I worked in the simulation industry, when interacting with customers to get their ideas about what the piece of software they wanted, one of the biggest things to lay out were the boundaries; things it wouldn't do so that scope creap would be kept to a minimum and the spec would be comprehensible. That mean that there would be a document both us as software providers and they as the users could understand and rely on. It also meant that when a bug was reported, we could both go to the document to see if it was a bug or an actual choice of behavior. Working within these kinds of bounds can be very liberating. Playing a musical instrament is a freeing exprerience because of the boundaries imposed by its design; the simplicity of the instrament.

**Q:** A piano has a fixed set of keys and the music comes from what you do
inside that limit. Do you play? What? And does playing feel like writing in
Silica — freedom that comes from the limits rather than in spite of them?

**A:** I played base clarinet in junior high. I took fiddle lessons for a while as an adult. Becoming lost in the sound when you get it right is very freeing. Creative acts always require boundaries. Computer languages are powerful because they give you limits you can use to your advantage and creatively.

**Q:** Silica has no generics, yet its standard library has collections — an
ordered map, say — that are told what kinds of values they hold. A reader who
knows other languages will ask whether that's generics by another name. How
would you explain the difference to that reader, without the code?

**A:** Generics hide data shapes. Silica's data structures elivate data shapes so they don't get lost and so there is no question what is being used. Each approach has a different purpose.

**Q:** Some Silica programs are longer than their equivalents elsewhere because
they spell out what others abbreviate. Was there a moment you were tempted to add
a second way to do something, a shortcut for a common case? What made you hold
the line?

**A:** There was a time when I was tempted to  add aliases to make the code easier for humans to read. I spoke with one of the people who I had been bouncing ideas of off. His response was not to add them. He stated that it would reduce the amazingness and 'beauty' of the language. I held firm and did not add aliases. It would have made it 'easier' for humans but made it harder for LLMs to generate correct code.

> Interviewer note: the colleague is unnamed; refer to them by role in the book.

**Q:** The beginner book tells newcomers to let a model write and to spend their
effort learning to read and judge. The machine types; the human judges. Ten
years out, if that's how most software is made, what does it look like? Who are
the programmers, and what does judging require of them?

**A:** Its like any other artform and like the Dutch master example I gave. The master does the judging. The person who has a grounding in reality and knows what they desire does the judging. The AIs do the typing. The humans do the conceptualization and ensure the end result is what they wanted.

---

*Session closed by the interviewer after 6 questions.*
