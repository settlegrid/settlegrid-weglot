# STRATEGIC BRIEF — THE FUNNY TWENTY
### Retro-Subversion Games That Survive a Brutal Buildability/Fun Battletest
*Scope: solo / Claude-Code-on-mobile, minimal audit surface, App Store, "just for fun"*

---

## THE THESIS

A "2D retro game switched up to be funny" has one trap and one cheat code.

**The trap:** most comedy in games is *expensive*. Slapstick (Goat Sim, Thank Goodness You're Here) lives in animation and voice. Rage-comedy (QWOP, Getting Over It) lives in physics *feel* that takes months to tune. Both blow up your audit surface and your asset budget. Neither is codeable-simple.

**The cheat code: ROLE INVERSION.** Take a retro game and play it from the *other side* — you're the pipes, not the bird; the ghost, not Pac-Man; the wall, not the paddle. Inversion is the rare twist that is *simultaneously* hilarious (incongruity + a villain/victim you've never been allowed to be) and **holds code complexity flat or lowers it** (the loop already exists; you just move the input). The second cheat is **reframing** — the same loop, recast as a mundane modern indignity (the alien invasion is just a *commute*; the minefield is a *dinner party*). Reframing costs only text and a reskin.

The 20 below are the survivors. Comedy that needed expensive assets or physics-tuning got killed (see Kill Log). What's left wins on **both** axes.

---

## THE BATTLETEST

Two axes, scored 1–10. A concept had to clear **7+ on BOTH** to survive.

### Axis A — BUILDABILITY (low audit surface)
Sub-tests, each a potential instant-kill:
- **Single scene.** One SpriteKit `SKScene`. No scene-graph management.
- **Deterministic / contained logic.** State machine you can hold in your head. No emergent chaos to debug.
- **No backend, no netcode, no real-time multiplayer.** (Instant kill — this is where audits and bugs metastasize.)
- **No physics-*feel* dependency.** If the comedy requires the jank to feel *exactly* right, kill it — that's an infinite tuning loop, not a build.
- **Asset-cheap comedy.** The joke must live in framing/text/one reskin, not in bespoke animation or voice.
- **Game Center leaderboard + StoreKit only.** No custom server. Local-first.

### Axis B — FUN / ADDICTIVENESS / SHAREABILITY
- **Readable in 3 seconds, no tutorial.**
- **"One more try" loop** (instant restart, score chase, escalation).
- **The twist generates a shareable moment** — a clip or screenshot that makes someone send it to a friend.
- **Escalation, not a one-note gag.** A single joke = a 30-second laugh = death by retention. The mechanic must *deepen* the joke.

### Kill criteria (any one = dead)
1. Requires real-time multiplayer / server. 2. Comedy depends on physics-feel tuning. 3. Comedy depends on bespoke art/voice volume. 4. The joke doesn't escalate. 5. Redundant with a stronger survivor.

---

## THE SURVIVORS — SCORE TABLE
*Sorted by composite. BUILD = buildability/low-audit. FUN = engagement/shareability.*

| # | Codename | Retro Base | Twist type | BUILD | FUN | Σ |
|---|----------|-----------|-----------|:----:|:---:|:--:|
| 1 | **PIPE DREAMS** | Flappy Bird | Role inversion | 9 | 8 | 17 |
| 2 | **HOARDER** | Tetris | Goal inversion | 9 | 8 | 17 |
| 3 | **GERALD** | Whack-a-Mole | Comedy of guilt | 9 | 8 | 17 |
| 4 | **SMALL TALK MINEFIELD** | Minesweeper | Reframe | 9 | 8 | 17 |
| 5 | **GHOSTED** | Pac-Man | Role inversion | 7 | 9 | 16 |
| 6 | **COMMUTE INVADERS** | Space Invaders | Role inversion + reframe | 8 | 8 | 16 |
| 7 | **TINY SPACES** | Lunar Lander | Reframe | 8 | 8 | 16 |
| 8 | **FROG DASH** | Frogger | Reframe | 8 | 8 | 16 |
| 9 | **SNAKE, BUT HR** | Snake | Goal inversion + reframe | 9 | 7 | 16 |
| 10 | **PIGEON COMMAND** | Missile Command | Reframe | 8 | 8 | 16 |
| 11 | **TAPPER FROM HELL** | Tapper | Absurd escalation | 8 | 8 | 16 |
| 12 | **PASSIVE-AGGRESSIVE SIMON** | Simon | Reframe | 9 | 7 | 16 |
| 13 | **CUSTOMER SERVICE OF THE DEAD** | Typing of the Dead | Reframe | 8 | 8 | 16 |
| 14 | **SITTING DUCK** | Duck Hunt | Role inversion | 8 | 8 | 16 |
| 15 | **THE BALL HAS ANXIETY** | Pong | Anthropomorphism | 8 | 7 | 15 |
| 16 | **SPACE UBER** | Asteroids | Role inversion | 8 | 7 | 15 |
| 17 | **BRICKED** | Breakout | Role inversion | 7 | 8 | 15 |
| 18 | **DOODLE DOWN** | Doodle Jump | Goal inversion | 8 | 7 | 15 |
| 19 | **CONGA** | Centipede / Snake | Reframe | 7 | 8 | 15 |
| 20 | **POT PLANT** | Tamagotchi | Anti-pet inversion | 8 | 7 | 15 |

---

## SURVIVOR PROFILES

### TIER S — BUILD FIRST (Σ17: max buildability, strong fun)

**1. PIPE DREAMS** *(Flappy Bird, inverted)*
You don't control the bird — you control the **pipes**. A brainless bird flaps forward on autopilot, trusting you completely, and your job is to drag the gaps so it survives. *Or not.* The dark heart: you can betray it.
- **Funny:** you are the level itself. The bird is an idiot who believes in you. Mercy is optional. Clips of a player smugly closing the gap on a trusting bird write themselves.
- **Buildable:** it's Flappy with the input moved from bird to pipes. The bird AI is a constant forward velocity + gravity. Trivial. Single scene.
- **Hook:** "how long can you keep the moron alive" score chase + an unlockable evil mode.

**2. HOARDER** *(Tetris, goal inverted)*
You must **never complete a line.** Survive as long as possible without clearing a single row, fighting the 40-year-old instinct hammered into your hands. Clear a line and a banner drops: *"YOU CLEARED A LINE. YOU MONSTER."* Game over.
- **Funny:** weaponizes muscle memory against the player. Watching someone reflexively complete a row and lose is pure comedy of failure.
- **Buildable:** literally Tetris with inverted scoring and an inverted fail-state. Same code, flipped sign.
- **Hook:** the board fills toward the top — pure escalating tension, "one more piece."

**3. GERALD** *(Whack-a-Mole, comedy of guilt)*
The moles have names, jobs, and families. You whack them anyway. Each hit triggers a half-second obituary: *"Gerald. Father of three. Loved jazz."* A "Mercy" button lets you spare one — but mercy breaks your combo.
- **Funny:** escalating pathos against a brutal score loop. The tension between the leaderboard and your conscience is the whole joke, and it deepens with absurd backstories.
- **Buildable:** Whack-a-Mole + text overlays + a procedurally-assembled name/bio table. No physics.
- **Hook:** combo multiplier vs. guilt meter; daily "most heartless player" leaderboard.

**4. SMALL TALK MINEFIELD** *(Minesweeper, reframed)*
You're at a dinner party. Tiles are conversation topics. Mines are landmine subjects — politics, *"so when's the baby?"*, crypto. The numbers tell you how close you are to social catastrophe. Clear the table without detonating an awkward silence.
- **Funny:** every adult has lived this. The reframe makes Minesweeper's cold logic into social dread. Topic labels carry the comedy.
- **Buildable:** it *is* Minesweeper — the most solved, lowest-risk grid logic in existence — with a reskin and a topic table.
- **Hook:** themed parties (in-laws, office holiday, first date) as content packs; daily seed.

---

### TIER A — STRONG (Σ16)

**5. GHOSTED** *(Pac-Man, inverted)*
You're one of four ghost roommates trying to catch the freeloader Pac-Man who keeps eating your labeled leftovers (*"Brenda's yogurt," "DO NOT TOUCH — Steve"*).
- **Funny:** roommate-passive-aggression as a chase. You finally get to *be* the ghost.
- **Build note:** the **one** survivor with real logic risk — ghost pathfinding. Mitigated: classic Pac-Man ghost AI is the most documented AI in games (each ghost = a simple target-tile rule). Flag for a light audit. Highest fun score on the board earns it.

**6. COMMUTE INVADERS** *(Space Invaders, inverted + reframed)*
You're an alien just trying to descend and **parallel-park your saucer** for the Monday commute while a paranoid human below takes pot-shots. You don't shoot — you dodge and land.
- **Funny:** the epic invasion is actually rush hour. The aliens are annoyed, not menacing.
- **Buildable:** Invaders with the player role flipped to dodge-and-descend; you delete the entire player-shooting system.

**7. TINY SPACES** *(Lunar Lander, reframed)*
Land your ship in a parking spot that shrinks each level while an alien queued behind you **honks**, louder and louder. Space DMV.
- **Funny:** the most cinematic descent in gaming, recast as parking anxiety. The honk audio is the punchline.
- **Buildable:** Lunar Lander physics = thrust + gravity, two of the simplest forces to code. Single screen.

**8. FROG DASH** *(Frogger, reframed)*
You're a delivery frog carrying a fragile boba tea across traffic. The cars aren't the real threat — *jostling* is. Spill meter rises with every bump; tips drop at the end.
- **Funny:** gig-economy frog. The boba physics jiggle and the falling star-rating are the comedy.
- **Buildable:** Frogger grid movement + a single "spill" float variable.

**9. SNAKE, BUT HR** *(Snake, inverted + reframed)*
The snake is your company's headcount during a hiring freeze. Apples are unsolicited new hires you must **avoid**. Grow too long and you're "over budget" — fired.
- **Funny:** corporate incongruity; a snake you're desperately trying *not* to grow.
- **Buildable:** Snake with inverted food logic. As trivial as it gets.

**10. PIGEON COMMAND** *(Missile Command, reframed)*
Defend your freshly-washed car (or picnic) from descending **pigeon poop** with a tiny umbrella. Escalating pigeon armadas.
- **Funny:** humanity's last stand vs. pigeons. Mundane stakes, epic framing.
- **Buildable:** Missile Command targeting on a single screen.

**11. TAPPER FROM HELL** *(Tapper, escalating absurdity)*
Slide drinks down the bar to increasingly impossible patrons: a ghost (drink falls through), a dragon (it evaporates), a guy who only orders "the vibe."
- **Funny:** the escalation *is* the content. Each new patron is a new joke and a new rule.
- **Buildable:** lane-based sliding, one of the simplest arcade loops. New patrons = data, not new code.

**12. PASSIVE-AGGRESSIVE SIMON** *(Simon, reframed)*
A memory game where Simon is your partner who "remembers everything." The sequence isn't colors — it's grievances: *"you forgot the milk," "you left the cap off," "your mother called."* Recall the full argument to survive.
- **Funny:** relationship grievance escalation. The sequence getting longer = the fight getting worse.
- **Buildable:** Simon is a trivial sequence-memory loop + a text/audio table.

**13. CUSTOMER SERVICE OF THE DEAD** *(Typing of the Dead, reframed)*
Zombies approach. You don't shoot — you **de-escalate**. Tap the correct canned support phrase (*"I completely understand your frustration"*) to neutralize each one. Customer support as survival horror.
- **Funny:** corporate-speak as a weapon. Wrong tone = the zombie escalates to a manager.
- **Buildable:** tap-to-select (not free typing — better on mobile *and* lower audit) + spawn waves.

**14. SITTING DUCK** *(Duck Hunt, inverted)*
You're the duck, dodging the hunter. Bob and weave across the screen. And the smug Duck Hunt **dog now laughs at YOU** when you're hit. Revenge premise.
- **Funny:** the most hated NPC in arcade history, weaponized against the player who always wanted to shoot it.
- **Buildable:** single-screen dodge mechanic + a reaction sprite.

---

### TIER B — SOLID (Σ15)

**15. THE BALL HAS ANXIETY** *(Pong)* — The ball has googly eyes and flinches *away* from your paddle. You must gently coax a frightened ball into a rally. Escalating moods (clingy → avoidant → it brings a friend) keep it from being one-note. *Build: Pong + a small avoidance vector + an eye sprite.*

**16. SPACE UBER** *(Asteroids, inverted)* — You're a peaceful chunk of rock drifting home; a trigger-happy "hero" ship keeps blasting you. Dodge to your exit. The asteroid's-eye-view of every space hero ever. *Build: Asteroids drift + role flip to dodge.*

**17. BRICKED** *(Breakout, inverted)* — You're the wall. Shuffle and reposition your bricks to protect the one VIP brick (the boss's favorite) from a relentless ball. The bricks gossip about each other. *Build: Breakout flipped, drag-to-reposition.*

**18. DOODLE DOWN** *(Doodle Jump, inverted)* — Your character is terrified of heights and wants to go **down**, but every platform bounces them up. Fight reverse-gravity to reach the safe ground floor, screaming the whole way. *Build: Doodle Jump with inverted goal + camera.*

**19. CONGA** *(Centipede / Snake)* — You lead a conga line, recruiting dancers into your tail. But each one has demands — one needs the bathroom, one is drunk and weaves, one keeps stopping to text. Keep the line alive. *Build: Snake/centipede tail logic + per-segment quirk flags.*

**20. POT PLANT** *(Tamagotchi, anti-pet)* — A houseplant with crippling anxiety that does **not** want your attention. Over-watering and over-talking stress it out; you must neglect it *exactly* the right amount. It sends you guilt-trip texts. *Build: timer-based state machine. Slow daily check-in loop — the strongest pick for a loyal, returning user base.*

---

## KILL LOG
*What didn't survive, and why. The battletest has teeth.*

| Killed concept | Axis failed | Cause of death |
|---|---|---|
| True `.io` reverse-arena (you're the food) | A | Real-time multiplayer = netcode = audit hell. Instant kill, despite `.io` being hot. |
| QWOP-style limb flailer | A | Comedy depends on physics-*feel*. Infinite tuning loop, not a build. |
| Getting-Over-It rage climber | A | Same physics-feel trap + frustration-comedy needs months of feel-tuning. |
| Voiced slapstick (Goose-Game / TGYH clone) | A | Comedy lives in animation + voice volume. Asset budget explosion. |
| Rhythm / DDR subversion | A | Audio-sync timing on mobile is fiddly and audit-prone. Benched. |
| Ragdoll Goat-Sim sandbox | A | 3D + open physics = scope explosion. |
| DIET PAC (Pac-Man on a diet, avoid food) | Kill #5 | Redundant with HOARDER + SNAKE-BUT-HR (the "avoid the thing you crave" lane was already full and stronger). |
| MEETING SIMULATOR (paper-airplane cave-flyer) | Kill #5 | Strong and dead-simple, but the one-button-flyer slot loses to richer survivors. **Best bench candidate** if you want the absolute lowest-effort first build. |

---

## RECOMMENDATION — WHAT TO BUILD FIRST

If the goal is *fastest path to a shipped, funny, low-audit thing*: build a **Tier-S concept**, because they max buildability without sacrificing the laugh.

- **Lowest risk, instant joke: HOARDER.** It's Tetris with a flipped sign and a savage fail-banner. You could have a playable prototype in one Claude Code session, and the joke needs zero explanation.
- **Most shareable / clip-friendly: PIPE DREAMS.** The "betray the trusting bird" moment is a built-in viral hook, and it's still just Flappy with moved input.
- **Best for a *loyal, returning* base (your stated goal): POT PLANT.** The slow daily check-in loop is what builds retention and habit, not score-chasing — different muscle from the rest, ad-free-friendly, and quietly hilarious.

**Suggested play:** ship **HOARDER** or **PIPE DREAMS** first as a fast credibility/learning build (one screen, one joke, Game Center leaderboard, ad-free as a positioning wedge against the Block-Blast ad-fatigue crowd), then use what you learn about App Store submission and retention to back a slower-burn **POT PLANT**.

*Stack for all of them: SpriteKit (gameplay) + SwiftUI (menus) + Game Center (leaderboards) + StoreKit (optional one-time "remove nothing, it's already ad-free / tip jar"). No server. No netcode. Minimal audit.*
