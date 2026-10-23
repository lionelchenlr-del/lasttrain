# Train regression checks

Build a temporary place from the repository root:

```sh
python3 tools/build_studio_regression.py
```

Open `/tmp/LastTrain-alignment-regression.rbxlx` in Roblox Studio, then select **Test → Start Test Session → Run**. The temporary place enters Game mode and disables the story controller so it cannot compete with the test driver. Production files are unchanged. Tests are not included by the production Rojo project.

Expected output: `LASTTRAIN_REGRESSION_ALL_PASS 4387 assertions`. Two full routes, twelve arrivals and two reverse return trips run with short test durations; production uses 42 seconds per station. Actual Roblox engine tests use one standing anchored test rig and one unanchored seated rig. They verify native seat attachment, seat release, passenger transport, door positions after every arrival, wheel and rail centers/contact height, transparent passenger glass, an unobstructed aisle, floor and ceiling seams, segmented route geometry, and route safety decisions at all seven stations.

After testing, three camera views show the exterior, interior, and wheel contact for 12 seconds each. This fixture must never be published as the game.

These checks do not replace four-client network testing, real-player input testing, or published-server purchase/teleport tests. Walking physics and replication under latency are not established by the anchored standing test rig. Route-safety decisions are tested directly; a malicious-client exploit simulation was not performed.
