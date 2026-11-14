# Interview session — 2026-11-13 (third session)

- **Chapter:** 5, Independence (*Share Nothing*)
- **Topic:** the Erlang lineage and SwErl; why independence; the promise of
  millions of actors; giving up automatic load balancing; what it opens up
- **Interviewer:** ghostwriter skill
- **Chosen because:** no interview coverage yet, and it carries an open thread
  from the progress log: confirming the SwErl-to-Silica lineage, which no
  Silica document mentions.

---

**Q:** Chapter 5 currently tells the story that SwErl taught you what a borrowed
actor model needs from its host: Swift's dictionaries weren't safe to share,
messages had no types, and sending and asking looked the same. But that's my
inference; no Silica document mentions SwErl. Is that how you see it? What did
SwErl actually teach you that ended up in Silica?

**A:** I quickly learned that 1) supervisors were nearly impossible to implement. 2) actors needed nothing more than a stored state and a function. No hidden lock was needed to be written by me to make them wait for a message. no need to move an actor off a thread in some sort of 'spawned and alive' state. 3) Actors can be fairly simple to implement. 4) I also created some code that was similar to traits based off of the templates Erlang uses, though it was cumbersome to pull off and I was uncomfortable with the results. Good first exploration though.

**Q:** Start with the first lesson. Why were supervisors nearly impossible in
SwErl? What did Swift lack, or get in the way of, that a supervisor needs, and
what did Silica have to have from day one to make supervision possible?

**A:** i could not figure out a clean way to get a crashing actor to report to its supervisor before disapearing. Therefore I couldn't figure out how to get a supervisor to do a good job of restarting failed actors. Silica, because I was writing the compiler, let me deal with this based on what chips and OSes would and could report themselves.

**Q:** Erlang's runtime moves work between processor cores to balance the load,
and most Erlang programmers never think about it. Silica's specification says
the runtime never moves an actor on its own; the program decides where its
actors run. Why give up something Erlang programmers take for granted?

**A:** Not hiding is the principle. Any programmer can implement their own load balancing algorithm that most efficiently solves that problem for the application they are writing and the overall problem thier application is solving. One-size-fits-all has been a usefull tool in the past in computing. With the speed of code generation now, I'm no longer sold on that idea. Even the Silica language and compiler can reasonably be forked if there is some other need. A unique codex and set of data shapes for data transport would be an example of that.

**Q:** That's a bold idea for the book: one-size-fits-all made sense when code
was expensive to write, and fast code generation changes the bargain, even for
the language itself. But a critic will say forks fragment a community: shared
libraries, shared knowledge and shared tools are what make a language
ecosystem valuable. How do you answer that?

**A:** the critic was correct in the past. In the now and future communities are still built around shared knowledge, but what that shared knowledge is has changed. It is now 'how do I get this piece of rock to do what I need it to this time?' The shared knowledge has become how to manipulate the language rather than manipulate libraries. There will still be libraries. They will still be shared. The difference is anybody can easily modify them to fit the explicit, direct need of the problem they are trying to solve. This is all because of the LLMs we have today.

**Q:** Let's turn to what independence opens up. In October 2026 a single
machine held a million idle Silica actors, and a thousand ran on a board with
half a megabyte of memory. With actors that cheap and that independent, what
kinds of systems do you picture people building that are hard to build today?

**A:** Nearly all systems built today are static in nature. This is because of history. That history included slower, weaker machines and humans writing code being the bottleneck in the system. I can envision systems consisting of millions of distributed nodes where each node is spawning, using, and then discarding actors that are single use with some smaller number of actors that are consistantly used. The BEAM, a work of genious and inspiration, is the background for these ideas, but if you look at SEMP you see it taken one step further. BEAM-node networks were designed for stable, safe computing environments. That isn't what we face today. Devices aren't always on. Networks aren't always available. Devices switch from ethernet to wifi to bluetooth all while communicating with one device. Phones reboot. Phones get calls and apps therefore stop. SEMP is designed to deal with this churn. Here is something else. our devices are a mess. How many instances of your word processer should you have to install? How much wasted space is there on your devices because you have to have these things called operating systems, for which the basic design was set in the late 1950's early 1960's, on every device? The operating system wars are over. Everybody lost. The users lost. The OS producers lost. Everybody lost. It is time to move on.

> Interviewer note: major vision material — dynamic systems of millions of
> nodes with churning single-use actors; SEMP as a step beyond BEAM networks
> (designed for stable environments) toward churn; the critique of
> per-device operating systems and duplicated installs. Belongs in ch05
> opportunities, and likely ch11 and ch12.

**Q:** "The operating system wars are over. Everybody lost." If it's time to
move on, move on to what? Paint me the picture: in the world you're imagining,
what runs on a phone, a laptop or a sensor in place of an operating system, and
where does your word processor live?

**A:** Here is some very early imaginings https://github.com/yenrab/organism

> Interviewer note (read 2026-11-13): *Organism*, Draft Specification v0.3,
> README only, 9 commits. A distributed operating-system replacement for
> people and groups: one persistent computational identity (the "organism")
> spread across devices ("organs", none authoritative); collective organisms
> for families/teams; actors instead of processes/threads as the kernel
> primitive; asynchronous messaging as the only interaction; capabilities
> instead of ambient permissions; persistence guaranteed by the runtime;
> per-device hypervisor with one slim kernel per actor and "capability
> membranes"; hierarchical files replaced by content-addressed "memory
> tissue"; UIs as stateless projections of actors; supervision trees;
> "failure is normal"; degrade, contain and heal. Opens with "The OS wars are
> over. Everybody lost." Conceptual; open research areas listed.

**Q:** In Organism, a person has one persistent computational life, and each
device is just an organ of it; there are actors instead of processes,
capabilities instead of permissions, and the runtime, not the application,
guarantees that things persist. Where does Silica sit in that picture? Is
Silica the language Organism would be built in, the thing that runs on each
organ, or something else?

**A:** I see no reason organism or something like it couldn't be built in Silica. I hope to do so in the near future.

**Q:** One fact to check before I write it. The project's working notes, written
by your AI agents, record that in September 2026, when hosted actors still
each had their own operating-system thread, one of them proposed scaling the
promise of millions of actors back to a library, and you refused, saying the
language keeps its promise. Is that accurate, and why was it a line you
wouldn't cross?

**A:** Yes, that's accurate. To be truely useful, agents have to not be in a one-to-one relationship with threads or they are nothing but a fancy facade for a thread. They would be false and untruthful.

> Interviewer note: "agents" here means actors (context: actors vs threads).

---

*Session closed by the interviewer after 9 questions.*
