"""Build a disposable native-client journey from station 1 through hidden station 9."""
from pathlib import Path
import subprocess,sys,xml.etree.ElementTree as E
repo=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]) if len(sys.argv)>1 else Path('/tmp/LastTrain-Hidden09-Regression.rbxlx')
if out.resolve().is_relative_to(repo):raise ValueError('Keep fixtures outside the repository')
subprocess.run([sys.executable,str(repo/'tools/build_story_regression.py'),str(out),'--branch=Records','--ending=Station08','--live-monster'],check=True)
tree=E.parse(out)
for i in tree.iter('Item'):
 name=i.findtext('Properties/string[@name="Name"]')
 if name=='BoardingStoryInput':i.find('Properties/string[@name="Source"]').text=(repo/'tests/StudioHiddenRoute.client.lua').read_text()
 if name=='BoardingStoryTest':i.find('Properties/string[@name="Source"]').text='workspace:SetAttribute("StoryTestBranch","Records");workspace:SetAttribute("StoryTestEnding","Station08");\n'+(repo/'tests/StudioHiddenRoute.server.lua').read_text()
tree.write(out,encoding='utf-8',xml_declaration=True)
print('Hidden-route fixture:',out)
