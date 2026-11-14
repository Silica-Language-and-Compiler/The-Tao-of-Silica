# Interview session — 2026-11-14 (seventh session)

- **Chapter:** 6, Resilience (*Fail Gently, Never Silently*)
- **Topic:** the motto's change; let it crash beyond the BEAM; never silent;
  guarding only what can be ruined; foreign code as a unit of failure; the
  elephant mother; where resilience is missing today
- **Interviewer:** ghostwriter skill
- **Chosen because:** no interview coverage yet; the earlier author correction
  (foreign-code crashes end only the dangerous actor) touched this chapter.

---

**Q:** On 12 April 2026, days after the project went public, the motto changed
from "Bad security practices should always be compiler errors!" to "Secure by
default — fail soft, never fail silent", later gaining "at compile time". The
first puts everything on the compiler; the second gives the running program a
part. What changed in your thinking in those few days? What made the compiler
alone not enough?

**A:** Given the infinite set of bad code possibilities, there didn't seem to be a way to catch them all at compile time. Division by zero where the divisor is a variable is an example. Short of doing a simulated execution of the code, there isn't a way to guarentee this example, and others like it, would be caught. Nevertheless, All bad code should be caught as early as possible. It's a boots-and-braces situation.

**Q:** The runtime half carries a promise most systems don't make: a failure is
always reported, with no way to switch the report off. Many platforms let you
silence errors because people want to cut the noise. Why is "never silent" a
hard line for you? Was there a time you were burned by a failure that left no
trace?

**A:** Because these are errors not warnings. Bad code is bad code. Also, it is AIs that now deal with the error output. They don't mind big data sets.

**Q:** Noise was a reason to silence errors when a person had to read every one;
a model doesn't tire of them. If every failure in a running Silica system is
reported completely and AIs are reading the reports, what does that make
possible? Picture a fleet of devices in the field, or a service that can't go
down. What does the loop between failure, report and fix look like once nothing
is hidden?

**A:** Failure->report->AI evaluation and flagging-> proposed fix -> human assessment -> AI produced fix -> human assessment -> production. Of course there are the 'don't do it' branches for the human assessment steps.

**Q:** There are two human gates in that loop: one before any fix is written,
one before it reaches production. Many people building with AI are trying to
take humans out of exactly those steps. Why keep the human in twice? What is the
person judging at the first gate that's different from the second?

**A:** Humans are the reason code is written. Code, traditionally, has been a form of communication between the person writing the code and the person using the code. It's like talking with someone, just the medium of transmition is different. Now, with the AIs involved, it is the intentions of the producer being transmitted. Here is an historical analog. The Dutch great masters didn't paint everything they put their name on. They had a studio of artists working for them and being trained by them. The master dictated how things were to be done and what was to be communicated to the person looking at the piece. The unknown artists did most of the work. The master did all of the directing. Production of software has, and always will be, a creative work. Without intention there can be no creation.

**Q:** Silica's beginner book explains supervision through an elephant mother:
she doesn't stop her calf from ever stumbling, but when it falls she gets it
back on its feet. Where did that image come from? Why an elephant?

**A:** I have always been interested in lots of things. I've never had a problem with being in a situation where I didn't have an interest to pursue. My difficulty has always been having too many things I'm interested in pursuing, then having to pick between them. Decades ago, I watched a documentary on african elephants. They are very intellegent, very long lived, obviously care for their children and family members, and help their children when they have a problem. The falling and help getting up came from that documentary. I don't remember what it was called. I don't remember what year it was. When I was pondering how to help someone understand supervisors, elephant families popped right into my head so I went with it.

**Q:** Where in the world today would you most like to see this kind of
resilience — systems that let a part fail, help it back up and always say what
happened — where it doesn't exist yet?

**A:** This is going to sound strange give the topic. Humanity has always struggled with this failure and response pairing. Some of us get too caught up in making sure we aren't being taken advantage of. This is the most important place. Tech-wise, I'd say in embedded systems. The embedded systems that keep our lives going and help bring us out of poverty. Electrical production, water providers, farming, and don't forget cars and their systems. So transportation systems as well.

**Q:** When you say some of us get too caught up in making sure we aren't taken
advantage of, do you mean that when someone fails, the response is often
suspicion or punishment rather than help getting up? And that people and
communities would do better treating failure the way a supervisor does: expect
it, contain it, help the one who fell back up, and be honest about what
happened?

**A:** You got that right. We can fall into the trap of, "There must be something wrong with them" thinking when failure happens. I've seen this in and outside of business and education.

> Interviewer note: the interviewer's question proposed the supervisor framing;
> the author confirmed it. Weave as the author's confirmed view, but keep the
> wording close to the author's own ("something wrong with them" thinking).

---

*Session closed by the interviewer after 8 questions.*
