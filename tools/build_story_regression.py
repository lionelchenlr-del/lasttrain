"""Build an isolated real-client story repro. Start it with Studio Test (F5)."""
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as E
repo=Path(__file__).resolve().parents[1]
lobby='--lobby' in sys.argv
arguments=[a for a in sys.argv[1:] if a!='--lobby']
out=Path(arguments[0]) if arguments else Path('/tmp/LastTrain-boarding-story-regression.rbxlx')
if out.resolve().is_relative_to(repo): raise ValueError('Keep temporary test places outside the repository')
subprocess.run(['rojo','build',str(repo/'LastTrain_Studio_Kit/default.project.json'),'-o',str(out)],check=True)
tree=E.parse(out);root=tree.getroot()
names={p.text:i for i in root.iter('Item') if (p:=i.find('Properties/string[@name="Name"]')) is not None}
names['ExperienceMode'].find('Properties/string[@name="Source"]').text='''local c=require(game.ReplicatedStorage.LastTrain.Shared.GameConfig)
c.TravelDuration=.65; c.MinimumStopDuration=.3; c.DepartureCountdown=.8
workspace:SetAttribute("LastTrainMode","MODE")'''.replace('MODE','Lobby' if lobby else 'Game')
names['StationmasterAI'].find('Properties/string[@name="Source"]').text='-- Disabled only in the temporary story fixture.'
for parent,kind,name,file in [('ServerScriptService','Script','BoardingStoryTest','StudioBoardingStory.server.lua'),('StarterPlayerScripts','LocalScript','BoardingStoryInput','StudioBoardingStory.client.lua')]:
 i=E.SubElement(names[parent],'Item',{'class':kind,'referent':name})
 p=E.SubElement(i,'Properties');E.SubElement(p,'string',{'name':'Name'}).text=name
 source=(repo/'tests'/file).read_text()
 if lobby and kind=='LocalScript':
  source='''task.wait(1) -- Leave the normal lobby Status request its debounce window.
local r=game.ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Remotes"):WaitForChild("MatchmakingRequest")
local response=r:InvokeServer("Join",1)
assert(response.ok,"Lobby matchmaking request failed: "..tostring(response.message))
print("LASTTRAIN_ENTRY_LOBBY_JOIN_PASS")
'''+source
 E.SubElement(p,'string',{'name':'Source'}).text=source
tree.write(out,encoding='utf-8',xml_declaration=True)
print(out)
