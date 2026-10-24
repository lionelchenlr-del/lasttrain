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
