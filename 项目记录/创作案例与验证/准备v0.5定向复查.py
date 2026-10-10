"""冻结四项仅核心指令复查；历史输出用于诊断参照，不用于因果结论。"""
from pathlib import Path
import json, hashlib

PROJECT = Path(__file__).resolve().parent.parent.parent
ROOT = PROJECT / '资料归档/创作案例与验证/实际试验/DeepSeek-v0.5-定向复查'
if ROOT.exists():
    raise SystemExit('复查已准备，不覆盖冻结数据')
for name in ('冻结材料', '请求', '原始输出'):
    (ROOT / name).mkdir(parents=True, exist_ok=True)
def write(path, obj):
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
def digest(data):
    return hashlib.sha256(data).hexdigest()
core_bytes = (PROJECT / '助手指令/共用内容/核心指令.md').read_bytes()
(ROOT / '冻结材料/A0.md').write_bytes(core_bytes)
core = core_bytes.decode('utf-8-sig').strip()
old = json.loads((PROJECT / '资料归档/创作案例与验证/实际试验/DeepSeek-v0.4-首轮/管理清单.json').read_text(encoding='utf-8'))
requests, scenes = [], []
for index, (scene_id, historical_id) in enumerate((('N52','P014'),('N51','P010'),('D38','P006'),('D31','P002')), 1):
    scene = next(s for s in old['scenes'] if s['id']==scene_id)
    scenes.append(scene)
    rid = f'C{index:03d}'
    prompt = ('你是一位视觉艺术与动画创作助手。\n\n创作要求：\n'+scene['request']+
              '\n\n交付要求：\n'+old['output_contract']+
              '\n\n创作指令与可选构思资源（只按相关性使用，不是输出模板）：\n'+core)
    (ROOT / f'请求/{rid}.md').write_text(prompt+'\n', encoding='utf-8')
    write(ROOT / f'请求/{rid}.json', {'request_id':rid,'messages':[{'role':'user','content':prompt}],'status':'prepared_not_executed'})
    h=2166136261
    for ch in prompt:
        h=((h ^ ord(ch))*16777619)&0xffffffff
    requests.append({'request_id':rid,'scene':scene_id,'condition':'v0.5_core_only','replicate':1,
                     'historical_reference':historical_id,'request_file':f'请求/{rid}.md',
                     'sha256':digest(prompt.encode('utf-8')),'characters':len(prompt),'fnv1a_utf16':h})
write(ROOT/'管理清单.json',{'trial_version':'0.5-targeted-1','request_count':4,'replicates':1,
    'scope':'core_only_not_resource_or_package_validation', 'requests':requests,'scenes':scenes,
    'output_contract':old['output_contract'],'materials':[{'condition':'A0','frozen_file':'冻结材料/A0.md','sha256':digest(core_bytes)}],
    'limitations':['public_previous_tasks','historical_reference_not_contemporaneous_control','one_sample_each','exact_backend_unknown']})
write(ROOT/'运行状态.json',{'status':'prepared_not_executed','completed_requests':0,'video_runs':0})
print(json.dumps(requests,ensure_ascii=False))
