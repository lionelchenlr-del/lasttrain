"""Build a disposable Studio test place. Run it with Test > Start Test Session > Run.
Production scripts and the shipped place are never modified by this harness.
"""
from pathlib import Path
import xml.etree.ElementTree as E
import subprocess
import sys
output=Path(sys.argv[1]) if len(sys.argv)>1 else Path("/tmp/LastTrain-alignment-regression.rbxlx")
repo=Path(__file__).resolve().parents[1]
if output.resolve().is_relative_to(repo):
 raise ValueError("Write the disposable test place outside the repository")
subprocess.run(['rojo','build',str(repo/'LastTrain_Studio_Kit/default.project.json'),'-o',str(output)],check=True)
tree=E.parse(str(output)); root=tree.getroot()
names={}
for item in root.iter('Item'):
 name=item.find("Properties/string[@name='Name']")
 if name is not None:names[name.text]=item
names['ExperienceMode'].find("Properties/string[@name='Source']").text='workspace:SetAttribute("LastTrainMode","Game")'
names['RoundController'].find("Properties/string[@name='Source']").text='-- Disabled only in this temporary regression place.'
i=E.SubElement(names['ServerScriptService'],'Item',{'class':'Script','referent':'regressionfixture'})
p=E.SubElement(i,'Properties');E.SubElement(p,'string',{'name':'Name'}).text='TrainRegression'
E.SubElement(p,'string',{'name':'Source'}).text=(repo/'tests/StudioTrainRegression.server.lua').read_text()
tree.write(str(output),encoding='utf-8',xml_declaration=True)
