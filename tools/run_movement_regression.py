"""Execute production travel logic with stand-ins that reject passenger-train movement."""
from pathlib import Path
import subprocess
import tempfile
repo=Path(__file__).resolve().parents[1]
test=(repo/'tests/TrainMovement.spec.luau').read_text()
source=(repo/'LastTrain_Studio_Kit/src/ServerScriptService/LastTrain/TrainOperations.lua').read_text()
with tempfile.TemporaryDirectory(prefix='lasttrain-motion-') as scratch:
 p=Path(scratch)/'movement.luau'
 p.write_text(test.replace('-- MODULE_UNDER_TEST',source))
 subprocess.run(['luau',str(p)],check=True)
