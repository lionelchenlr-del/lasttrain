# Train regression checks

Build a temporary place from the repository root:

```sh
python3 tools/build_studio_regression.py
```

Open `/tmp/LastTrain-alignment-regression.rbxlx` in Roblox Studio, then select **Test → Start Test Session → Run**. The temporary place enters Game mode and disables the story controller so it cannot compete with the test driver. Production files are unchanged. Tests are not included by the production Rojo project.

Expected output: `LASTTRAIN_REGRESSION_ALL_PASS 5648 assertions`. Two full routes, twelve arrivals and two reverse return trips run with short test durations; production uses 42 seconds per station. Actual Roblox engine tests use one standing anchored test rig and one unanchored seated rig. They verify native seat attachment, seat release, passenger transport, door positions after every arrival, wheel and rail centers/contact height, transparent passenger glass, an unobstructed aisle, floor and ceiling seams, segmented route geometry, and route safety decisions at all seven stations.

After testing, four camera views show the exterior, interior, gangway, and wheel contact for 12 seconds each. This fixture must never be published as the game.

These checks do not replace four-client network testing, real-player input testing, or published-server purchase/teleport tests. Walking physics and replication under latency are not established by the anchored standing test rig. Route-safety decisions are tested directly; a malicious-client exploit simulation was not performed.

The 2026-10-24 fixture also samples 21 floor positions at each gangway, checks level collision surfaces, traversable width and lateral walls, and repeats the connection checks after every arrival. It checks visible gangway lamps, intact seat prompts, dark cab glazing and independent coach numbers. Logs are saved in `tests/results/2026-10-24.txt`.
