"""Original procedural score and sound design for Last Train (no third-party samples)."""
from pathlib import Path
import numpy as np
import wave,subprocess,json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'LastTrain_Studio_Kit/release/audio'
SCRATCH=Path('/Users/lionelchen/Documents/Codex/2026-10-23/lasttrain-next/work/audio')
OUT.mkdir(parents=True,exist_ok=True);SCRATCH.mkdir(parents=True,exist_ok=True)
SR=32000;LENGTH=32.;rng=np.random.default_rng(9012026)
def note(m):return 440*2**((m-69)/12)
def add(a,at,m,duration,amp=.1,pad=False):
 n=int(SR*duration);t=np.arange(n)/SR;f=note(m)
 if pad:
  env=np.minimum(t/1.4,1)*np.minimum((duration-t)/2,1)
  v=(np.sin(2*np.pi*f*t)+.28*np.sin(2*np.pi*f*1.002*t)+.13*np.sin(2*np.pi*f*2*t))*env
 else:
  env=(1-np.exp(-t*70))*np.exp(-t*1.2)*np.minimum((duration-t)/.15,1)
  v=(np.sin(2*np.pi*f*t)+.22*np.sin(2*np.pi*2*f*t)*np.exp(-t*2)+.07*np.sin(2*np.pi*3*f*t)*np.exp(-t*4))*env
 idx=(np.arange(n)+int(at*SR))%len(a);np.add.at(a,idx,v*amp)
def save(name,a):
 a=a-np.mean(a);peak=np.max(np.abs(a));a=a*min(.74/max(peak,1e-9),1.0)
 wav=SCRATCH/(name+'.wav')
 with wave.open(str(wav),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes((np.clip(a,-.97,.97)*32767).astype('<i2').tobytes())
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-ac','2','-c:a','vorbis','-strict','-2','-q:a','4',str(OUT/(name+'.ogg'))],check=True)
 return {'file':name+'.ogg','duration':round(len(a)/SR,3),'peak':round(float(np.max(np.abs(a))),4),'rms':round(float(np.sqrt(np.mean(a*a))),4)}
manifest={}
chords={'Night':[[50,57,60,64],[46,53,57,60],[43,50,53,57],[45,52,55,61]],'Investigation':[[38,45,50,53],[39,46,50,57],[38,45,48,53],[37,44,49,55]],'Mystery':[[38,50,57,65],[41,53,60,67],[39,51,58,65],[37,49,56,63]],'Home':[[50,57,61,66],[43,55,59,62],[47,54,59,62],[45,52,57,61]]}
for theme,progression in chords.items():
 if theme=="Investigation":continue # Active investigation mix uses the accepted Mystery track.
 a=np.zeros(int(SR*LENGTH))
 for bar in range(8):
  chord=progression[bar%4]
  for m in chord:add(a,bar*4,m,6,.055 if theme!='Home' else .065,True)
  if theme in ('Night','Home'):
   pattern=[0,2,1,3] if theme=='Night' else [0,1,3,2]
   for beat,j in enumerate(pattern):add(a,bar*4+beat,chord[j]+12,3,.1 if theme=='Home' else .065)
  elif theme=='Investigation':
   for beat in range(8):add(a,bar*4+beat*.5,chord[0]+12,1.1,.045)
   add(a,bar*4+2.5,chord[3]+12,3,.045)
  else:
   for beat in [0,2.5]:add(a,bar*4+beat,chord[2]+12,4,.055)
 manifest[theme]=save('LastTrain_'+theme,a)
# A single preloaded effects bank: each cue has silence on both sides for seeking.
cues={};bank=np.zeros(SR*25)
def cue(name,start,duration,kind):
 n=int(duration*SR);t=np.arange(n)/SR
 env=np.minimum(t/.025,1)*np.minimum((duration-t)/.06,1)
 noise=rng.standard_normal(n)
 if kind=='chime':
  v=np.zeros(n)
  for at,hz in [(0,660),(.16,880),(.32,1100)]:
   tt=np.maximum(t-at,0);v+=.25*np.sin(2*np.pi*hz*tt)*np.exp(-tt*6)*(t>=at)
 elif kind=='reject':v=.2*np.sin(2*np.pi*180*t)*(np.sin(2*np.pi*5*t)>.1)*env
 elif kind=='door':v=np.convolve(noise,np.ones(45)/45,mode='same')*.85*np.sin(np.pi*t/duration)**2+.08*np.sin(2*np.pi*85*t)*env
 elif kind=='click':v=(.18*np.sin(2*np.pi*950*t)+.12*noise)*np.exp(-t*35)*env
 elif kind=='anomaly':v=(.17*np.sin(2*np.pi*92*t)+.13*np.sin(2*np.pi*98*t)+.025*noise)*env*np.exp(-t*.6)
 elif kind=='rumble':v=(.07*np.sin(2*np.pi*54*t)+.03*np.sin(2*np.pi*81*t)+.035*np.convolve(noise,np.ones(80)/80,mode='same'))*env
 elif kind=='shutter':v=np.convolve(noise,np.ones(3)/3,mode='same')*.22*np.exp(-t*24)*env
 elif kind=='countdown':v=.22*np.sin(2*np.pi*740*t)*np.exp(-t*10)*env
 else:v=.16*np.sin(2*np.pi*(440+360*t)*t)*env
 bank[int(start*SR):int(start*SR)+n]+=v;cues[name]={'start':start,'duration':duration}
for args in [('Ticket',.3,.9,'chime'),('Rejected',1.5,.65,'reject'),('Door',2.5,1.2,'door'),('Click',4,.2,'click'),('Anomaly',4.7,2.3,'anomaly'),('Rumble',7.5,4,'rumble'),('Shutter',12,.3,'shutter'),('Countdown',13,.45,'countdown'),('Success',14,1.2,'chime'),('Evidence',15.7,.9,'rise'),('Arrival',17,1.4,'chime'),('Tea',19,.8,'click')]:cue(*args)
manifest['Effects']=save('LastTrain_Effects',bank);manifest['cues']=cues
manifest['Investigation']={**manifest['Mystery'],'variantOf':'Mystery','playbackSpeed':.92}
# Preserve the published IDs when regenerating deterministic source assets.
existing=OUT/'audio-manifest.json'
if existing.exists():
 previous=json.loads(existing.read_text())
 for key,value in manifest.items():
  if isinstance(value,dict) and key in previous and 'assetId' in previous[key]:value['assetId']=previous[key]['assetId']
(OUT/'audio-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(OUT/'LICENSE.txt').write_text('Original Last Train procedural compositions and synthesized effects. Generated from mathematical oscillators and deterministic noise by tools/compose_audio.py. No third-party recordings, lyrics or music samples. Project owner may use and modify these assets for Last Train.\n')
print(json.dumps(manifest,indent=2))
