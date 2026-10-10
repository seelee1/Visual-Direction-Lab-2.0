from pathlib import Path
import json, hashlib, sys
from datetime import datetime, timezone

ROOT=Path(__file__).resolve().parent/'实际试验/DeepSeek-v0.5-资源对照'
rid,url=sys.argv[1:3]
def read(path): return json.loads(path.read_text(encoding='utf-8'))
def write(path,obj): path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
manifest=read(ROOT/'管理清单.json')
req=next(r for r in manifest['requests'] if r['request_id']==rid)
target=ROOT/('原始输出/'+rid+'.json')
if target.exists(): raise SystemExit('已登记，不覆盖')
answer_path=ROOT/('原始输出/'+rid+'.md')
answer=answer_path.read_text(encoding='utf-8').rstrip('\r\n')
write(target,{'request_id':rid,'eligible_for_primary':True,'status':'completed_visible_answer_captured',
    'conversation_url':url,'captured_at':datetime.now(timezone.utc).isoformat(),'platform':'DeepSeek web',
    'backend_model_version':None,'thinking_mode':True,'search_mode':False,'reasoning_saved':False,
    'loading_mode':'inline_text_checked_before_submission','request_sha256':req['sha256'],
    'response_file':'原始输出/'+rid+'.md','response_sha256':hashlib.sha256(answer_path.read_bytes()).hexdigest(),
    'answer_characters':len(answer.encode('utf-16-le'))//2})
records=[read(p) for p in (ROOT/'原始输出').glob('*.json')]
sequence=read(ROOT/'运行顺序.json')
item=next(s for s in sequence if s['request_id']==rid)
item['status']='completed'
write(ROOT/'运行顺序.json',sequence)
scene=next(s for s in manifest['scenes'] if s['id']==req['scene'])
(ROOT/('评审/'+item['review_id']+'.md')).write_text('# '+item['review_id']+'\n\n创作要求：'+scene['request']+'\n\n交付要求：'+manifest['output_contract']+'\n\n回答：\n\n'+answer+'\n',encoding='utf-8')
write(ROOT/'运行状态.json',{'status':'completed_resources_pilot' if len(records)==12 else 'running',
    'completed_requests':len(records),'excluded_responses':0,'video_runs':0,'backend_model_version':None,
    'thinking_mode':True,'search_mode':False,'notes':['选段对照，不是整包测试','每个独特输入一次；钥匙R/E同文重复','开发者知条件审查，尚未独立盲评']})
print(json.dumps({'id':rid,'completed':len(records),'characters':len(answer)},ensure_ascii=False))
