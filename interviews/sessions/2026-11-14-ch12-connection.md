# Interview session — 2026-11-14 (eighth session)

- **Chapter:** 12, Connection (*Speak Across Every Boundary*)
- **Topic:** networking in, out, and transport as language; trusting nothing
  that arrives; BEES and Erlang interop; SEMP's churn ideas and Organism; what
  connection opens up
- **Interviewer:** ghostwriter skill
- **Chosen because:** no session of its own yet (only the Organism material
  from the ch05 session), and it holds the clearest three-step *Why? / Why not?*
  sequence in the record.

---

**Q:** The commit history and the spec record three positions in two months.
On 14 September 2026 TCP/IP went into the core language. Three days later the
spec said "Networking is not part of the Silica language", with sockets reached
only through Fifi. Then in November, transport came back as "a full and equal
citizen" of the language, while sockets stayed outside. What happened in those
three days in September that made you take networking back out?

**A:** (The author first pasted a technical note on the current implementation:)

> sockets still go through the FFI. The carried_on syntax sits on top of that and hides it from ordinary programs.
>
> - FFI layer: The actual socket calls are in a C sidecar, compiler/stdlib/net/silica_sockets.c. It is desccompiler by silica_sockets_wrapper.meta. compits.silica wraps those C functions in Silica. Thelink-symbol .scout files in the trials list the silica_sockets_* symbols, such as silica_sockets_udp_biWhere the FFI runs: The code that calls it is pec (§20.4) says networking is reached through the FFI in dangerous actors, not as a core-language feature. The carriers dangerous_tcp_carrier.silica and dangerous_udp_carrier.silica are those actors.
> - What programs write: A program declares carried_on wire: (:tcp) (:interface, "en0"); and starts it with spawn_dangerous_carrier(wire, ...). The compilatching carrier actor, using the transport packfor the target. The program talks to the carrier by messages such as (:open, ...), (:tx, ...) and (:rx, ...). It never
>   calls a socket function itself.

The debate I was having was what should be part of BEES and what should be part of the language. The last dicision was the correct one. Modern devices swim in a sea of connectivity. To have a library sperate from the language when doing communication is strange and weird at this point in history. One of the early things that should be done is to engineer a TCP/IP stack in Silica. That way the dangerous FFI call can go away.

**Q:** Today every connection runs through a `dangerous_` carrier because the
sockets beneath are C. A TCP/IP stack written in Silica would remove that. What
would it change, for you or for someone building a device, to have networking
with no foreign code anywhere beneath it?

**A:** The memory safety contat of the Silica language would be the big difference. Also, by writing it in Silica it can truely become part of the compiler and therefore the language.

**Q:** (Interviewer read "contat" as "contract".) The spec says every received
byte is untrusted; data is fully valid or refused, never half-accepted. It also
makes the ways data can be packaged a fixed set: a new wire format is a change
to the language, never a library. Most ecosystems let anyone publish a new
serialization library. Why close that door? Where did you see the damage an
open-ended set of formats can do?

**A:** If transport is part of the languge, it only makes sense that wire formats are too. Otherwise the language is incomplete and self contradictory. Using LLMs it isn't difficult to add a new wire format. a codex and some code is really all that is needed. I had this very conversation with a collegue. My statement to them is still my current thinking. If you need a different wire format/data shape, fork the compiler, add the wire format/data shape. if you think it might be helpful for others, do a pull request with your thinking and any evidence you've collected. This approach has significant advantages to developers. When you have a specific need regarding data transfer, you don't have to try to twist an existing format to fit your need. Create your own. Even if it is just for a smaller project. We have entered and are continuing to go through a new time; one where software is disposable. Build good quality. Don't plan on longevity.

**Q:** "Software is disposable: build good quality, don't plan on longevity"
seems to pull against other things you've said. The embedded systems you most
want to protect — power, water, cars — often run for decades. You want proofs
of correctness and a compiler that reproduces itself byte for byte. How does
disposable software fit with infrastructure that has to last? Or does
"disposable" mean something more specific than it sounds?

**A:** I see no conflict in the statements. disposable doesn't necissarily mean the entire piece of software, though it could. I can mean parts of it. I think the history of changes to Silica bares out that I've been working this way. If a piece doesn't fit or makes other things harder to do, replace it with something that is better. Don't fall for the sunk-cost falicy.

**Q:** The agents' notes record a ruling from October: when Silica and BEES
conflict, Silica wins and BEES's plan is what changes. Is that accurate? And
beyond settling conflicts, what did building BEES teach you about connection
that you might not have learned otherwise?

**A:** Yes that is accurate. BEES, as you have seen before, has been around conceptually for some time. BEES is one of the reasons I started making Silica. There was no language that could do it well. As Silica came into a more full existance and discoveries were made along the way, there were things that had been planned for BEES that didn't need to be there or didn't make sense there any more. Again, don't fall for the fixed-cost falicy.

> Interviewer note: "fixed-cost falicy" read as the sunk-cost fallacy, as in
> the previous answer. Confirms the agent-recorded "Silica wins" ruling.

**Q:** SEMP took a step past the BEAM toward churn — devices off, networks
dropping, Ethernet to Wi-Fi to Bluetooth mid-conversation — and judged peers by
behaviour over time; Silica has no counterpart yet. How do SEMP's churn and
behaviour ideas carry forward, into Silica's transport or into Organism? Waiting
for their place, or left behind?

**A:** These go forward as part of BEES. Division of responsibilities. Silica does transport. BEES manages transport.

**Q:** With transport in the language, wire formats you can fork, and BEES
managing peers and churn on top, who gains the most? What could someone build
with that combination that is out of reach today?

**A:** A truely distributed system including mobile, IOT, personal, and shared devices. Currently this is extremely difficult to pull off. Also, things like Organism become possible. I see organism as one example of these distributed systems I just described. User ease and their ability to trust a system could go way up. Today, we have fractured, independent systems we wire together so they simulate integrated systems.

---

*Session closed by the interviewer after 7 questions.*
