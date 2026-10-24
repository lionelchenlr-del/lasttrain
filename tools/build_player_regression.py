"""Build disposable real-client motion/physics fixture."""
from pathlib import Path
import subprocess,sys,xml.etree.ElementTree as E
repo=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1] if len(sys.argv)>1 else '/tmp/LastTrain-Flicker-Player.rbxlx')
if out.resolve().is_relative_to(repo):raise ValueError('Temporary places must stay outside repo')
subprocess.run(['rojo','build',str(repo/'LastTrain_Studio_Kit/default.project.json'),'-o',str(out)],check=True)
t=E.parse(out)
n={p.text:i for i in t.getroot().iter('Item') if (p:=i.find('Properties/string[@name="Name"]')) is not None}
n['ExperienceMode'].find('Properties/string[@name="Source"]').text='workspace:SetAttribute("LastTrainMode","Game")'
for name in ['RoundController','RecoveryGuard','StationmasterAI']:
 n[name].find('Properties/string[@name="Source"]').text='-- Disabled only in temporary motion fixture.'
for parent,kind,name,file in [('ServerScriptService','Script','MotionTestServer','StudioMotionPlayer.server.lua'),('StarterPlayerScripts','LocalScript','MotionTestClient','StudioMotionPlayer.client.lua')]:
 i=E.SubElement(n[parent],'Item',{'class':kind,'referent':name})
 p=E.SubElement(i,'Properties');E.SubElement(p,'string',{'name':'Name'}).text=name
 E.SubElement(p,'string',{'name':'Source'}).text=(repo/'tests'/file).read_text()
t.write(out,encoding='utf-8',xml_declaration=True)
print(out)
