"""Mux own synthetic tone plus honest source captions; FFmpeg is a dev tool only."""
from pathlib import Path
import argparse,subprocess,tempfile,shutil
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--ffmpeg',required=True);p.add_argument('--output',type=Path,default=root/'Resources/podcast-caption-test.mp4');args=p.parse_args()
args.output.parent.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='caption-fixture-',dir=args.output.parent) as folder:
 temp=Path(folder);srt=temp/'markers.srt';out=temp/'own-tone.mp4'
 srt.write_text('1\n00:00:00,000 --> 00:00:40,000\n[Synthetic test tone · first marker]\n\n2\n00:00:40,000 --> 00:00:59,500\n[Synthetic test tone · final marker]\n',encoding='utf-8')
 subprocess.run([args.ffmpeg,'-nostdin','-hide_banner','-loglevel','error','-fflags','+bitexact','-i',str(root/'Resources/podcast-test-audio.wav'),'-i',str(srt),'-map','0:a:0','-map','1:s:0','-map_metadata','-1','-c:a','aac','-b:a','48k','-flags:a','+bitexact','-c:s','mov_text','-metadata:s:s:0','language=eng','-metadata:s:s:0','title=Synthetic tone markers','-movflags','+faststart',str(out)],check=True)
 shutil.copyfile(out,args.output)
