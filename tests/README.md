# Current stationary-carriage regression (2026-10-24)

Production now keeps the passenger train fixed. Scenery and station scenes provide travel. Historical results below describe earlier moving-train versions.

- `python3 tools/run_movement_regression.py`: 111 checks, 18 journeys with train transform APIs forbidden.
- `luau tests/DepartureGate.spec.luau`: 116 checks.
- `luau tests/TicketAccess.spec.luau`: 45 checks.
- `luau tests/EditionLedger.spec.luau`: 22,507 checks, 500 global serials, receipt replay and allocation cap.
- `python3 tools/build_studio_regression.py /tmp/LastTrain-geometry.rbxlx`: Studio **Run**, seven scene positions/collision sets, two full visual routes, 12 arrivals, seat/door/connection/cab checks. Latest result: 18,762 checks.
- `python3 tools/build_player_regression.py /tmp/LastTrain-player.rbxlx`: Studio **Test**, actual unanchored client-owned character walks the connected cars during a 42-second journey, then sits, opens and closes both full-size previews without disturbing the native seat weld, stands and dies/respawns during another journey. Client train drift must remain below .0001 studs. No server carry or character anchoring is used in this fixture.
- `python3 tools/build_story_regression.py /tmp/LastTrain-story.rbxlx --lobby --branch=Conductor --ending=Conductor`: Studio **Test**, normal server story controller, anchored test character and native prompt holds; all seven stops, ending ACK and real unowned/owned paid-seat prompts. `--ending=Station08` selects the secret branch; `--live-monster --travel=42` retains the monster and full journey duration. Timings changed only in the disposable fixture. Three endings were reached across separate sessions.
- `python3 tools/build_premium_regression.py /tmp/LastTrain-shop.rbxlx`: Studio **Test**, eight entitlements, unlisted purchase rejection, invalid equip, profile equipment choices, receipt deduplication and native VIP lounge access. Fixture-only server grants do not represent real Robux purchases.

All test places stay outside the repository and are excluded from the production Rojo tree. No live payment, four-client latency, published teleport or long-term cloud persistence claim is made. Seven real pass IDs and one developer product ID are still required before sale.

---

# Train regression checks

Build a temporary place from the repository root:

```sh
python3 tools/build_studio_regression.py
```

Open `/tmp/LastTrain-alignment-regression.rbxlx` in Roblox Studio, then select **Test → Start Test Session → Run**. The temporary place enters Game mode and disables the story controller so it cannot compete with the test driver. Production files are unchanged. Tests are not included by the production Rojo project.

Expected output: `LASTTRAIN_REGRESSION_ALL_PASS 6307 assertions`. Two full routes, twelve arrivals and two reverse return trips run with short test durations; production uses 42 seconds per station. Actual Roblox engine tests use one standing anchored test rig and one unanchored seated rig. They verify native seat attachment, seat release, passenger transport, door positions after every arrival, wheel and rail centers/contact height, transparent passenger glass, an unobstructed aisle, floor and ceiling seams, segmented route geometry, and route safety decisions at all seven stations.

After testing, four camera views show the exterior, interior, gangway, and wheel contact for 12 seconds each. This fixture must never be published as the game.

These checks do not replace four-client network testing, real-player input testing, or published-server purchase/teleport tests. Walking physics and replication under latency are not established by the anchored standing test rig. Route-safety decisions are tested directly; a malicious-client exploit simulation was not performed.

The 2026-10-24 fixture also samples 21 floor positions at each gangway, checks level collision surfaces, traversable width and lateral walls, and repeats the connection checks after every arrival. It checks visible gangway lamps, intact seat prompts, dark cab glazing and independent coach numbers. Logs are saved in `tests/results/2026-10-24.txt`.

The door/cab repair adds 512 shell rays, 64 root-cap rays, and frame sampling during 27 door operations (fixed-part intersections, stable transparency/material and a fixed sliding track). The earlier fixture detected the orange beltline intersecting an opening door; the final version passes after moving both waist stripes inward. Final engine output: `tests/results/2026-10-24-door-cab.txt`.

## Actual story and boarding regression

Run `luau tests/DepartureGate.spec.luau` for 116 state checks covering platform waiting, countdown resets, dwell, deaths/missing characters and roster changes.

Build `python3 tools/build_story_regression.py`. Open `/tmp/LastTrain-boarding-story-regression.rbxlx` and choose **Test** (F5), with one real Studio client. The normal RoundController stays enabled. A temporary client driver aims at each prompt and uses native InputHoldBegin/InputHoldEnd with its normal hold time; server distance and stage validation remain active. The test finishes with `LASTTRAIN_STORY_ALL_PASS`: station 2 waits with a passenger still on the platform, the boarding prompt remains usable, exiting during door closure cancels departure and reopens doors, and reboarding reaches station 4. Only the disposable fixture accelerates timing and disables the monster. This is one local client with an anchored character, not four-client latency or manual walking coverage.

The current cab fixture also checks that lamps are integrated into the shell and no separately raised cab parts remain. Final logs: `tests/results/2026-10-24-taiwan-boarding.txt`.

## First-station ticket tutorial

Run `luau tests/TicketAccess.spec.luau` for 45 checks of independent four-passenger records, ticket-before-validation, repeat collection/scan, one anomaly per passenger, disconnect cleanup and a fresh round. The real-client story fixture now begins before the ticket gate: rejection without a ticket, personal collection, no validation on collection alone, an unauthorized boarding attempt returned outside, a successful scan with the private client-only anomaly (and restoration), gate open/closed collision, no repeat anomaly, and validation preserved after an actual character reload. Only boarding after validation advances the shared story. It then repeats the station-2 waiting and closing-door exit scenarios through station 4. The test ACK remote is injected only into the disposable fixture.

This is one actual client with scripted prompt input and an anchored test character; manual walking and four-client latency remain separate. Latest output: `tests/results/2026-10-24-ticket-entry.txt`. No ticket data is persisted across rounds.

For the normal Studio lobby path, build `python3 tools/build_story_regression.py /tmp/LastTrain-ticket-lobby-final.rbxlx --lobby`, then start Test (F5). Its temporary client driver joins the one-person queue using the normal MatchmakingRequest, leaves the initial Status debounce window, and runs the same tutorial/respawn/station-4 test. The initial spawn check requires the exact ticket-concourse position. Both direct-round and lobby-to-round sessions passed; lobby log: `tests/results/2026-10-24-ticket-lobby.txt`.
