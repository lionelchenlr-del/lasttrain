"""Native audio checks alongside the full hidden-station story regression."""
from pathlib import Path
import subprocess,sys,xml.etree.ElementTree as E
repo=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]) if len(sys.argv)>1 else Path('/tmp/LastTrain-Audio-Regression.rbxlx')
subprocess.run([sys.executable,str(repo/'tools/build_hidden_regression.py'),str(out)],check=True)
tree=E.parse(out)
for i in tree.iter('Item'):
 if i.findtext('Properties/string[@name="Name"]')=='StarterPlayerScripts':
  script=E.SubElement(i,'Item',{'class':'LocalScript','referent':'AudioRegressionInput'});props=E.SubElement(script,'Properties');E.SubElement(props,'string',{'name':'Name'}).text='AudioRegressionInput';E.SubElement(props,'string',{'name':'Source'}).text=(repo/'tests/StudioAudio.client.lua').read_text();break
else:raise RuntimeError('Starter scripts not found')
tree.write(out,encoding='utf-8',xml_declaration=True)
