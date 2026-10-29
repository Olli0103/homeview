"""Bind public simctl camera captures to READY/DONE states in a native UI run."""
from pathlib import Path
import argparse, datetime, hashlib, json, os, signal, subprocess, tempfile, time

def run_capture(command, device, output, log_path, timeout=480, expected_states=0):
    output=Path(output);output.mkdir(parents=True,exist_ok=False)
    log_path=Path(log_path)
    if log_path.exists():raise FileExistsError(log_path)
    captures={};errors=[];offset=0;pending='';started=time.monotonic()
    with log_path.open('w') as log:
        proc=subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
        try:
            deadline=started+timeout
            while True:
                with log_path.open() as stream:
                    stream.seek(offset);chunk=stream.read();offset=stream.tell()
                pending+=chunk
                while '\n' in pending:
                    line,pending=pending.split('\n',1)
                    for phase in ['READY','DONE']:
                        marker='NATIVE_QA_'+phase+':'
                        if marker not in line:continue
                        data=json.loads(line.split(marker,1)[1]);name=data['name']
                        if phase=='DONE':
                            if name in captures:captures[name]['native_done_at']=data['at']
                            continue
                        if not name.replace('-','').isalnum() or len(name)>80 or name in captures:
                            raise ValueError('Invalid or duplicate capture identity')
                        dst=output/(name+'.png')
                        # The public capture service writes to a short local path;
                        # read-back verifies the subsequent external-artifact move.
                        with tempfile.TemporaryDirectory(prefix='native-vision-') as temp:
                            local=Path(temp)/'screen.png';begin=time.time()
                            try:
                                result=subprocess.run(['xcrun','simctl','io',device,'screenshot',str(local)],capture_output=True,timeout=15)
                                ended=time.time()
                                if result.returncode or not local.exists():
                                    errors.append({'name':name,'code':result.returncode});continue
                                data_bytes=local.read_bytes();dst.write_bytes(data_bytes)
                                if dst.read_bytes()!=data_bytes:raise OSError('Capture read-back mismatch')
                            except subprocess.TimeoutExpired:
                                errors.append({'name':name,'code':'capture_timeout'});continue
                        captures[name]={'native_ready_at':data['at'],'host_capture_started_at':begin,
                            'host_capture_ended_at':ended,'file':dst.name,'bytes':len(data_bytes),
                            'sha256':hashlib.sha256(data_bytes).hexdigest(),'read_back':True}
                code=proc.poll()
                if code is not None:break
                if time.monotonic()>deadline:
                    os.killpg(proc.pid,signal.SIGTERM)
                    try:proc.wait(timeout=15)
                    except subprocess.TimeoutExpired:os.killpg(proc.pid,signal.SIGKILL);proc.wait()
                    code=124;errors.append({'code':'owner_timeout'});break
                time.sleep(0.1)
        finally:
            if proc.poll() is None:
                os.killpg(proc.pid,signal.SIGTERM)
                try:proc.wait(timeout=15)
                except subprocess.TimeoutExpired:os.killpg(proc.pid,signal.SIGKILL);proc.wait()
    for row in captures.values():
        row['inside_held_state']=row['native_ready_at']<=row['host_capture_started_at']<=row['host_capture_ended_at']<=row.get('native_done_at',0)
    valid=bool(captures) and not errors and all(r['inside_held_state'] for r in captures.values())
    if expected_states:valid=valid and len(captures)==expected_states
    result={'exit_code':code,'elapsed_seconds':time.monotonic()-started,
        'ended':datetime.datetime.now(datetime.timezone.utc).isoformat(),'system_captures':captures,
        'capture_errors':errors,'captures_within_held_states':valid}
    (output/'captures.json').write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device',required=True);parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--timeout',type=int,default=480);parser.add_argument('--expected-states',type=int,default=0)
    parser.add_argument('command',nargs=argparse.REMAINDER)
    args=parser.parse_args();command=args.command[1:] if args.command[:1]==['--'] else args.command
    if not command:parser.error('Pass the native test command after --')
    result=run_capture(command,args.device,args.output,args.output.parent/(args.output.name+'.log'),args.timeout,args.expected_states)
    print(json.dumps(result));raise SystemExit(result['exit_code'] or (0 if result['captures_within_held_states'] else 2))
