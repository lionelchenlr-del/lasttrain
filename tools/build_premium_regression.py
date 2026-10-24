from pathlib import Path
import subprocess,sys,xml.etree.ElementTree as E
repo=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1] if len(sys.argv)>1 else '/tmp/LastTrain-Collection-Shop.rbxlx')
if out.resolve().is_relative_to(repo):raise ValueError('Temporary place must be outside repo')
subprocess.run(['rojo','build',str(repo/'LastTrain_Studio_Kit/default.project.json'),'-o',str(out)],check=True)
t=E.parse(out);n={p.text:i for i in t.getroot().iter('Item') if (p:=i.find('Properties/string[@name="Name"]')) is not None}
for parent,kind,name,file in [('ServerScriptService','Script','PremiumTestServer','StudioPremium.server.lua'),('StarterPlayerScripts','LocalScript','PremiumTestClient','StudioPremium.client.lua')]:
 i=E.SubElement(n[parent],'Item',{'class':kind,'referent':name});p=E.SubElement(i,'Properties');E.SubElement(p,'string',{'name':'Name'}).text=name;E.SubElement(p,'string',{'name':'Source'}).text=(repo/'tests'/file).read_text()
t.write(out,encoding='utf-8',xml_declaration=True)
print(out)
