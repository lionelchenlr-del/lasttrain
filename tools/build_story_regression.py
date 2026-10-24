"""Build an isolated real-client story repro. Start it with Studio Test (F5)."""
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as E
repo=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]) if len(sys.argv)>1 else Path('/tmp/LastTrain-boarding-story-regression.rbxlx')
if out.resolve().is_relative_to(repo): raise ValueError('Keep temporary test places outside the repository')
subprocess.run(['rojo','build',str(repo/'LastTrain_Studio_Kit/default.project.json'),'-o',str(out)],check=True)
tree=E.parse(out);root=tree.getroot()
names={p.text:i for i in root.iter('Item') if (p:=i.find('Properties/string[@name="Name"]')) is not None}
names['ExperienceMode'].find('Properties/string[@name="Source"]').text='''local c=require(game.ReplicatedStorage.LastTrain.Shared.GameConfig)
c.TravelDuration=.65; c.MinimumStopDuration=.3; c.DepartureCountdown=.8
workspace:SetAttribute("LastTrainMode","Game")'''
names['StationmasterAI'].find('Properties/string[@name="Source"]').text='-- Disabled only in the temporary story fixture.'
for parent,kind,name,file in [('ServerScriptService','Script','BoardingStoryTest','StudioBoardingStory.server.lua'),('StarterPlayerScripts','LocalScript','BoardingStoryInput','StudioBoardingStory.client.lua')]:
 i=E.SubElement(names[parent],'Item',{'class':kind,'referent':name})
 p=E.SubElement(i,'Properties');E.SubElement(p,'string',{'name':'Name'}).text=name
 E.SubElement(p,'string',{'name':'Source'}).text=(repo/'tests'/file).read_text()
tree.write(out,encoding='utf-8',xml_declaration=True)
print(out)
