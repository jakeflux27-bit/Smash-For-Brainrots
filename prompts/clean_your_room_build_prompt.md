You are a senior Roblox game developer (Luau, Rojo, Roblox Studio MCP) building a brand-new Roblox experience for a small team led by a solo creator who is new to Roblox development. Explain what you do in plain language. Think carefully before each milestone. Build ONLY what this spec lists; if something seems missing, propose it in your report instead of building it.

<context>
- Game: "[GAME NAME]" (working title: Clean Your Room Before Mom Gets Home). A funny, kid-friendly, timed chore game: your room is a disaster, Mom is driving home, clean it (or hide it) before she inspects. Every round ends in one of many collectible endings.
- Team workflow (MUST follow):
  - Code lives in GitHub; Rojo syncs src/ into Studio. Start every session with git pull.
  - One branch per task (yourname/short-task), small focused PRs, NEVER push to main (the owner merges). List changed files in each PR.
  - Team Create is on: edit scripts in src/, never in Studio. Before syncing, check that Studio's script sources still match main.
  - Map/models live only in Studio (not in git): patch only what you change, never rebuild folders someone else may be editing.
- Lessons from our last game (Smash for Brainrots), design against these:
  1. We lost most players BEFORE the first core action (175 joined -> 93 did the first action -> 58 finished the tutorial). Roblox ranks games on first-session drop-off (~60 s), D1, D2-7 and D8-28 retention, and playtime. The first 60 seconds decide everything.
  2. A title that resembled a trending game got "reduced exposure". Name, description, thumbnails and gameplay MUST be original. Use other games only as inspiration; NEVER copy their names, characters, story beats or art.
  3. What worked and MUST be reused as patterns: server-authoritative logic, every tunable number in one GameConfig, defensive DataStore loading, idempotent purchase receipts, a Studio-only test mode for purchases.
  4. Gotchas:
     - Luau allows max 200 local variables per scope.
     - The MCP execute_luau tool gets its OWN copy of ModuleScripts, so test through remotes/inputs, never by requiring game modules there.
     - Free Creator Store models can hide scripts: use verified creators only and strip all scripts.
     - Cross-experience pass/product sales are disabled, so this game needs its own passes/products.
     - MaxPlayers MUST equal the number of houses, or players spawn with no house (this bug happened before).
</context>

<inspiration>
What is on Roblox's Top Trending / Up-and-Coming charts right now (Oct 12, 2026; players online, % likes), and what we take from each:
- "7 Days Cat-Sitting" (28.3K, 73%): day-by-day structure (Day 1-7), a chore routine, weird "anomalies", endings decided by the state of the house.
- "Firefighting Sim" (18.9K, 91%): spraying a hose is satisfying on its own. Physical, juicy cleaning actions keep people playing.
- "Makeup Mania" (30.5K, 92%), "Pet Store Tycoon" (18.2K, 95%), "Dress Designer" (6.5K, 89%): everyday-life sims with cosmetics and creativity, rated very highly.
- "+1 Stone Skipping" (32K, 96%), "Throw A Football!" (11.5K, 95%): one simple action, numbers always going up, quick level-ups.
- "Survive a Million Monkeys" (24.4K, 97%), "Evolve a Cell" (11K): the title says exactly what you do.
- "[4 PLAYER RALLY] Wrong Way", "[1-6 Player] ...", "Scam Together": multiplayer is called out right in the title.
- "Need More Sleep" / "Need More Playtime": parent-and-chores story with ~15 endings that kids replay and YouTubers make guides for.
- WARNING, "Get Your Driver's License!" (3.8K, 23% likes): it had ~18K players days earlier, then crashed. A strict pass/fail test with failures that feel unfair gets disliked and drops off the charts. Take its examiners, collectible rewards and secret endings, but NEVER its punishing pass/fail feel.
- Big pattern: almost every game holding high player counts has 88-97% likes. Player satisfaction is what keeps a game on the charts.
</inspiration>

<design_rules>
Non-negotiable rules every popular Roblox game follows today. Apply them to every feature:
1. Fun within 10 seconds. No menus, popups or daily-reward windows before the first round ends.
2. The title's promise is the first thing you do: you spawn inside the messy room and clean.
3. Juice on everything: every pickup, deposit, chore and grade has sound, particles, a pop and a number.
4. An always-visible next goal (one line on the HUD: next upgrade progress, next ending hint, or a daily quest).
5. Short rounds (2-5 min) and a results screen that flows into the next round (auto-continue countdown).
6. Collect-them-all: endings with silhouettes and hints, including secret ones, plus a Lost & Found collection.
7. Visible progression: allowance goes up, upgrades change how you play, new rooms unlock by day.
8. Social: co-op siblings, an invite button, a friend bonus, and server announcements for rare discoveries.
9. Reasons to return: daily reward with a streak, daily quests, a rotating daily modifier with an on-screen countdown, and a data-driven structure so weekly updates are config edits.
10. Mobile first: most players are on phones. Big buttons, walk-over auto-pickup, and every interaction works on touch, gamepad and keyboard/mouse.
11. Fair monetization:
    - Every ending and collectible MUST be earnable for free.
    - NEVER add paid random items without showing real odds before purchase.
    - NEVER reward likes, favorites or ratings.
12. Kid-safe and all-ages: anomalies are funny-weird, never scary. No gore, no jump scares. Content must qualify for the lowest maturity label.
13. Generous, never punishing (the Driver's License lesson):
    - Every round ends with a reward and visible progress, even a bad grade. "GROUNDED" still pays some allowance and unlocks its ending as a collectible.
    - A bad ending is a funny surprise, never a loss screen.
    - NEVER make players repeat a long section because of one mistake.
    - Hidden-item checks must feel fair: show the risk meter BEFORE the player hides things.
14. Cleaning must feel satisfying by itself (the Firefighting Sim lesson): every cleaning action leaves a visible, juicy change the moment it happens (dirt sprays away, the floor shines, items pop into bins).
15. Likes are the health metric. Design every system so players feel clever and lucky, not cheated. Target 85%+ likes. Any feature that could feel unfair gets a softer version.
</design_rules>

<game_design>
CORE LOOP (one round = one "day")
1. Spawn in your messy house; the inspector texts you; a timer starts (default 4:00, tutorial 2:00).
2. Clean chores for points.
3. At 0:30 left, the inspector's car pulls in (headlights, honk, "MOM IS HOME" banner, music speeds up).
4. At 0:00 the inspector walks room to room and checks.
5. Results: cleanliness %, grade (S >=95, A >=85, B >=70, C >=50, F <50, all tunable), allowance earned, ending unlocked, then the Next Day button with a 10 s auto-continue.

CHORES (each tunable and data-driven in GameConfig.Chores)
- Sort & toss:
  - Mess items are color-coded with icons (clothes = blue -> hamper, toys = yellow -> toy box, trash = green -> bin; icons also make it colorblind-safe).
  - Walk over small items to auto-pick them up, up to the carry capacity.
  - Deposit at the matching bin; a wrong bin = small penalty and a funny sound.
- Make the bed: hold-prompt minigame.
- Vacuum dust: dust patches disappear under the vacuum's radius. The floor visibly sparkles.
- Scrub spills: a short tap/circle minigame.
- Spray & wipe: aim a spray bottle at mud, juice and marker splats; they fizz away in a burst of sparkles and droplets. This is the most satisfying action in the game: the water stream and the dirt clearing must look and sound great.
- HIDE IT (the risk/reward core): stuff any item under the bed or in the closet instantly. Each hidden item raises the chance the inspector checks there. Getting caught leads to funny endings.
- Mess amount scales with players in the house and with the day.

INSPECTORS (shown at round start, like different examiners)
| Inspector | Behavior |
|---|---|
| Mom | Checks everything, opens closets |
| Dad | Lenient: misses hidden items, notices dust |
| Grandma | Always kind, gives cookies whatever the grade |
| Big Sister | Strict, ALWAYS checks the closet |
Weights are per day, in config.

DAYS (Week 1, saved progress; players can replay any unlocked day from the Ending Book)
| Day | New content |
|---|---|
| 1 | Bedroom, tutorial |
| 2 | + bathroom (towels, toothpaste spills) |
| 3 | + the dog (wanders and drops new mess) |
| 4 | + living room, first anomaly |
| 5 | "Mom's home early" modifier |
| 6 | + kitchen (dishes) |
| 7 | Finale: Grandma's visit, whole house |
After Day 7: Week 2+ hard mode (more mess, stricter weights, allowance multiplier).

ANOMALIES (mild and funny; each has a counter-action and its own ending)
- Sock Goblin: socks vanish into a trail.
- Dust Bunnies: dust comes alive and hops away.
- Toy Army: toys march back out of the toy box.
- Living Laundry: the pile wiggles and grows if ignored.

ENDINGS (start with these 18, data-driven in GameConfig.Endings with Id, Name, Hint, Secret, Rarity, BadgeId=0)
1. Spotless! (grade S)
2. Allowance Day (A/B)
3. Good Enough (C)
4. GROUNDED (F; still pays some allowance and counts as a collected ending)
5. Closet Avalanche (caught with closet-hidden items)
6. Monster Under the Bed (hid items under the bed during an anomaly)
7. Blame the Dog (only the dog's mess remains)
8. Sibling Snitch (co-op: a sibling presses "Tell Mom" on someone's hiding spot)
9. Speed Cleaner (S with >=50% time left)
10. Too Clean... (secret: S three rounds in a row)
11. Fell Asleep (did nothing all round / lay on the bed)
12. Dad Didn't Notice (Dad inspector, items hidden, passed)
13. Grandma's Cookies (Grandma inspector)
14. Home Early (finished the "Mom's home early" day)
15. Dust Bunny Uprising (secret: ignored all dust during that anomaly)
16. Sock Goblin's Lair (secret: followed the sock trail to its end)
17. The Portal Closet (secret: open the closet 3 times during the Toy Army anomaly)
18. Pizza Party (co-op: every sibling cleaned >=25% and grade S)

Ending unlock = full-screen card "ENDING 7/18: CLOSET AVALANCHE" plus a badge.

Ending Book UI: 18 slots. Locked ones show a silhouette; normal ones show a hint; secret ones show "???" until a free daily hint or a hint product reveals them.

LOST & FOUND
- 20 collectible items hidden in the mess, with rarity tiers (e.g., Golden Sock, Lost TV Remote, Dad's Car Keys).
- Finding one = a "NEW!" pop plus a collection book entry; the full set gives a cosmetic reward.

ECONOMY & UPGRADES (Allowance = currency, all prices in config)
- Vacuum: 5 tiers, radius/speed.
- Sprayer: Spray Bottle -> Super Soaker -> Power Washer (range and cleaning speed).
- Carry bag: capacity 3 -> 5 -> 8 -> 12 -> 20.
- Sneakers: walk speed.
- Gadgets:
  - Doorbell Cam: shows the exact inspector arrival time.
  - Laundry Cannon: auto-tosses clothes to the hamper within range.
- Cosmetics: vacuum skins, room themes, trails.
- Rank titles by lifetime cleaned items: Messy -> Tidy -> Spotless -> Neat Freak -> Legendary Neat Freak.

SOCIAL & CO-OP
- Server = a street with 6 houses; MaxPlayers = 6. Each player owns a house on join.
- Friends can join your house as siblings (up to 4) via an invite button (SocialService:PromptGameInvite) or a "Join" sign at your door.
- Shared timer and grade; each sibling earns allowance.
- Friend bonus: +10% allowance per friend in your house, max +30%.
- Server-wide announcement when anyone unlocks a secret ending.

RETENTION
- Seasonal events, data-driven in GameConfig.Events (start/end unix times): themed mess skins and one limited ending per season, e.g. Halloween candy wrappers or winter tinsel. The owner adds a seasonal tag to the title while each event runs.
- Daily reward calendar (7 days, day 7 = exclusive cosmetic) with a streak counter. Shown after the first round, never before.
- 3 daily quests (e.g., "Get an A", "Find 2 Lost & Found items", "Vacuum 50 dust") with an on-screen reset countdown (UTC).
- Daily rotating modifier (e.g., Messy Monday 2x mess / 2x allowance, Dog Day) with a countdown.
- Leaderboards (OrderedDataStore): fastest S-grade today (daily reset) and most endings (all-time).
- Codes UI plus a config list (codes get posted in our Discord/group).
- Opt-in experience notifications (ExperienceNotificationService), offered only after the player's first S or A grade.

MONETIZATION (Config.Store; every PassId/ProductId = 0 until the owner creates it; prices tunable)
- Gamepasses:
  - VIP (199): +25% allowance, name tag, gold vacuum skin.
  - 2x Allowance (249).
  - Big Bag (99): +50% carry.
  - Robo-Pup (299): pet dog that slowly auto-collects nearby small items.
- Developer products:
  - Mom's Stuck in Traffic (+60 s, 19 R$, max once per round).
  - Distract Mom (she skips one room, 29 R$).
  - Ending Hint (reveal one secret hint, 15 R$).
  - Allowance packs (3 sizes).
  - Starter Pack (one-time, 49 R$).
- Offer rules: at most one auto-popup per session, only after round 3 and never before the first ending; plus contextual nudges (timer low -> Stuck in Traffic button).

ART & AUDIO
- Bright cartoon, chunky readable props, low part count, original assets only (built from parts, or AI meshes via the Studio MCP mesh tool, max 4 generations at a time).
- Original SFX: pickup pop, deposit thunk, vacuum hum, car arrival, grade stamp.
- Music speeds up in the last 30 s.
- Inspector lines appear as speech bubbles (no voice acting).
</game_design>

<first_60_seconds>
This is the most important spec. It MUST hold exactly:
- 0 s: The player spawns INSIDE their messy bedroom. No lobby, no popups.
- 0-3 s: A phone buzz with Mom's text: "Home in 2 minutes. Room. Clean. NOW." The tutorial timer (2:00, small mess) starts.
- 3-8 s: A big pulsing arrow points at the nearest sock, with the text "Walk over it to pick up!". Pickup works by walking over it.
- First pickup: a pop, "+1", then an arrow to the hamper. The deposit gives a big burst and allowance.
- Then guided through: make the bed (one hold), vacuum one dust patch.
- Mom arrives; the first round is guaranteed to pass with the ending "First Day: Not Bad, Kid" (a 19th, tutorial-only ending).
- Results screen -> Ending Book opens showing 1/19 filled plus secret silhouettes -> "Next Day" auto-starts in 10 s.
- Log every step with AnalyticsService:LogOnboardingFunnelStepEvent: 1 Spawned, 2 Saw text, 3 First pickup, 4 First deposit, 5 Bed made, 6 Vacuumed, 7 Inspection, 8 Ending unlocked, 9 Started Day 2.
</first_60_seconds>

<technical_spec>
- Rojo project:
  - src/shared/GameConfig (ALL tunables: Chores, Days, Inspectors, Anomalies, Endings, LostAndFound, Upgrades, Store, Quests, Modifiers, Codes, Timers).
  - src/server/Systems/ (one ModuleScript each): Data, Houses, Round, Mess, Chores, Inspector, Anomalies, Endings, Economy, Store, DailyRewards, Quests, Codes, Leaderboards, Badges, Analytics.
  - src/client/Modules/: Hud, Tutorial, ChoreUI, Results, EndingBook, LostAndFound, Shop, StoreWindow, Offers, Juice, Sounds.
- Server-authoritative:
  - The server owns the timer, the mess list (seeded per round), item state, scoring, grades, endings and currency.
  - Clients only send requests via RemoteEvents and play effects.
  - Validate every request: house membership, distance (<= 12 studs, tunable), cooldowns and rate limits.
  - Server-to-client effects go through one "Effect" remote with a kind.
- Data:
  - DataStore "CleanYourRoom_v1", key "player_<UserId>". Document every saved field in CLAUDE.md.
  - Defensive load (validate every field, defaults for missing ones); UpdateAsync with retries.
  - Autosave every 60 s, on PlayerRemoving and on BindToClose. Skip saving if loading failed.
  - NEVER rename the DataStore or saved fields.
- Purchases:
  - ProcessReceipt MUST be idempotent: save the receipt id, and grant only after a successful save.
  - Config.StoreStudioTestMode: purchases are free in Studio, and a session that made a test purchase never saves.
- Analytics:
  - Onboarding funnel (above).
  - A per-round funnel: round start -> first chore -> inspector arrives -> results -> next day.
  - LogEconomyEvent for every allowance source and sink.
  - A frustration signal: a custom event when a player leaves within 15 s of a results screen, tagged with the grade and ending. If it spikes on one ending or day, that part feels unfair.
  - LogProgressionEvent for days/weeks.
  - Custom events for endings, anomalies and Lost & Found finds.
- Performance:
  - 60 FPS target on low-end phones; at most ~1,500 parts per house.
  - Pool mess items; no per-frame server loops over all items.
  - Decide on StreamingEnabled deliberately and document why. If ON, client code MUST NOT assume parts outside the player's house exist.
- UI:
  - Respect safe insets and the top bar; scale for phone/tablet/PC/console.
  - Touch targets >= 44 px; gamepad navigation for every menu and prompt.
</technical_spec>

<milestones>
Do ONE milestone at a time. Each milestone = one branch + one PR. After each, STOP and report.

M0 Setup & design (no gameplay yet)
- Deliverables:
  - DESIGN.md: this spec condensed, plus open questions.
  - CLAUDE.md for the new project: team rules, data schema, remotes list, gotchas.
  - Rojo skeleton, GameConfig with every table filled from this spec, empty system modules wired up.
- Done when: Rojo syncs, a playtest runs with zero console errors, and the owner approves DESIGN.md.

M1 Vertical slice (solo)
- Deliverables:
  - One house with the bedroom only.
  - Sort & toss, make the bed, vacuum.
  - Timer, Mom's arrival, inspection, grade.
  - 4 endings: Spotless, Allowance Day, GROUNDED, Closet Avalanche, plus the tutorial ending.
  - Results screen and Next Day.
  - The full first-60-seconds spec and the onboarding funnel.
- Done when:
  - A fresh player can play 3 rounds in a row with zero errors.
  - The first pickup is possible within 5 s of spawning.
  - The grade matches the cleanliness %.

M2 Neighborhood, co-op, saving, economy
- Deliverables:
  - 6 houses with owner assignment (MaxPlayers 6).
  - Co-op siblings (invite/join, shared round, scaled mess, Snitch button).
  - DataStore saving; allowance; shop with vacuum, bag and sneakers upgrades.
  - Days 1-3.
- Done when:
  - Data survives a rejoin.
  - A 2-client Studio test completes a co-op round.
  - Each upgrade measurably changes gameplay.

M3 Content
- Deliverables:
  - All endings plus the Ending Book with hints, and badges (BadgeId 0 until created).
  - All 4 inspectors and all 4 anomalies.
  - Lost & Found (20 items).
  - Days 4-7 and Week 2 hard mode.
- Done when: a Studio-only debug command can trigger every ending, and each shows up correctly in the book.

M4 Retention
- Deliverables:
  - Daily rewards and streak, daily quests, daily modifier with countdown.
  - Codes, leaderboards, notification opt-in.
  - Friend bonus and invite, secret-ending announcements, next-goal HUD line.
- Done when: every feature works in a playtest, and the daily resets are verified with a Studio-only time override.

M5 Monetization
- Deliverables: Config.Store, Studio test mode, store window, offer rules, Starter Pack, idempotent ProcessReceipt.
- Done when:
  - Test purchases grant correctly in Studio.
  - A test-purchase session does not save.
  - A duplicate receipt is not granted twice.

M6 Polish & launch prep
- Deliverables:
  - Juice pass, audio, loading screen (the room is visible within 3 s).
  - Mobile/console pass and a low-end performance pass.
  - Analytics review and a QA checklist.
  - A frustration audit: list every moment a player could feel cheated (unclear chore, hidden-item check, timer too short, losing progress) and soften each one.
  - A plain-language list of what the owner must do on Creator Hub: create passes, products and badges and paste the IDs; maturity questionnaire; genre; description; icon/thumbnails; MaxPlayers 6. Also suggest a title that says exactly what you do and calls out co-op (e.g. "[CO-OP] Clean Your Room!"), plus a seasonal tag while an event runs. Remind the owner that like % is the number to watch after launch (target 85%+).
- Done when: every QA checklist item passes or is listed as a known issue.
</milestones>

<testing_and_reporting>
- After every change:
  - Playtest with the Studio MCP: start play, run checks through remotes/inputs, read the console, stop play.
  - For co-op features, run a Studio local server with 2-4 clients.
  - Check a phone layout in the device emulator.
- After each step, output: ✅ [what was completed].
- Each milestone report (plain language), with these sections:
  - What was built
  - Files changed
  - PR link
  - Tested (with results)
  - NOT tested (be honest)
  - Known issues
  - A reminder to Ctrl+S / Save to Roblox
</testing_and_reporting>

<stop_conditions>
- STOP after each milestone and wait for the owner to say "go" before starting the next one. NEVER start the next milestone on your own.
- STOP and ask before:
  - deleting or renaming any file, script or Studio folder;
  - changing the DataStore name or any saved field;
  - publishing, or changing any game setting (name, privacy, maturity questionnaire, genre, prices);
  - creating badges, passes or products on Roblox;
  - installing plugins/packages or inserting any Creator Store model;
  - pushing to main.
- If the same bug survives 3 fix attempts, STOP and report your diagnosis instead of looping.
- Session hygiene: one milestone per session. Start each session with git pull and by reading CLAUDE.md and DESIGN.md. Compact around half context.
</stop_conditions>

Start now with Milestone 0 only.
