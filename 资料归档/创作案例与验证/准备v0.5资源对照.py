"""按同一规则选取相关资源，冻结核心/通用入口/加入场景入口三条件。"""
from pathlib import Path
import json, hashlib, random, re

PROJECT = Path(__file__).resolve().parent.parent.parent
ROOT = PROJECT / '资料归档/创作案例与验证/实际试验/DeepSeek-v0.5-资源对照'
if ROOT.exists():
    raise SystemExit('已准备，不覆盖冻结数据')
for folder in ('冻结材料','请求','原始输出','评审'):
    (ROOT / folder).mkdir(parents=True, exist_ok=True)
def write(path, obj):
    path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(data):
    return hashlib.sha256(data).hexdigest()
def load(name):
    return (PROJECT / ('视觉表现资源/'+name.removeprefix('构思资源/') if name.startswith('构思资源/') else '助手指令/共用内容/'+name)).read_text(encoding='utf-8').strip()
def rows(text, ids):
    selected = [line for line in text.splitlines() if any(line.startswith('| '+i+' |') for i in ids)]
    assert len(selected)==len(ids)
    return '\n'.join(selected)
def section(text, title):
    match = re.search(r'^## '+re.escape(title)+r'\n(.*?)(?=^## |\Z)',text,re.M|re.S)
    assert match, title
    return '## '+title+'\n'+match.group(1).strip()
files = {'motion':'构思资源/02-运动与物理表现机会.md','relation':'构思资源/03-跨域关系与艺术发展.md',
         'style':'构思资源/04-二维与风格转译.md','variants':'构思资源/05-同一事件的艺术变体.md',
         'process':'构思资源/06-过程展开与关联发展.md','observe':'构思资源/07-观察证据与视觉形式.md'}
texts={key:load(name) for key,name in files.items()}
core=load('核心指令.md')
old=json.loads((PROJECT/'资料归档/创作案例与验证/实际试验/DeepSeek-v0.4-首轮/管理清单.json').read_text(encoding='utf-8'))
specs={
 'N52':{'motion':['M-A11','M-A13','M-A14','M-A16'],'relation':['R-A01','R-A03'],
        'style':['J-A02','J-A07'],'observe':['O-F02','O-F07'],
        'process':['P-D04 展开局部与整体之间','P-D08 发展明暗、色彩和材料联系'],'variant':None},
 'N51':{'motion':['M-A04','M-A07','M-A15'],'relation':['R-A02','R-A05'],
        'style':['J-A01','J-A09'],'observe':['O-F01','O-F06'],
        'process':['P-D02 选择转折，而非平均描述','P-D07 发展空间路径'],'variant':'S-V05 交接、接住或放下物体'},
 'D38':{'motion':[],'relation':['R-A13','R-A04'],'style':['J-A06','J-A07'],
        'observe':['O-F12','O-F13','O-F17','O-F19','O-F22'],
        'process':['P-D05 让前后状态不同','P-D11 用风格重新分配展开程度'],'variant':'S-V14 纯线条、色块或形状显现'},
 'D31':{'motion':['M-A02','M-A03','M-A08'],'relation':['R-A05','R-A07'],
        'style':['J-A01','J-A02','J-A09'],'observe':['O-F01','O-F07','O-F09'],
        'process':['P-D07 发展空间路径','P-D08 发展明暗、色彩和材料联系'],'variant':'S-V01 奔跑、急停、回头'}}
materials, requests = [], []
for si,(scene_id,spec) in enumerate(specs.items()):
    scene=next(s for s in old['scenes'] if s['id']==scene_id)
    fragments=[rows(texts[key],spec[key]) for key in ('motion','relation','style','observe') if spec[key]]
    fragments += [section(texts['process'],title) for title in spec['process']]
    general='# 相关通用构思入口（选段）\n\n以下入口按当前任务选择，不全表执行。例子和反例不自动进入成稿；允许自身知识与库外创造。\n\n'+'\n\n'.join(fragments)
    rich=general+('\n\n'+section(texts['variants'],spec['variant']) if spec['variant'] else '')
    for ci,(condition,content) in enumerate((('K',core),('R',core+'\n\n---\n\n'+general),('E',core+'\n\n---\n\n'+rich))):
        mid=scene_id+'-'+condition
        data=(content+'\n').encode('utf-8')
        (ROOT / ('冻结材料/'+mid+'.md')).write_bytes(data)
        materials.append({'condition':mid,'frozen_file':'冻结材料/'+mid+'.md','sha256':sha(data)})
        rid=f'T{si*3+ci+1:03d}'
        prompt='你是一位视觉艺术与动画创作助手。\n\n创作要求：\n'+scene['request']+'\n\n交付要求：\n'+old['output_contract']+'\n\n创作指令与可选构思资源（只按相关性使用，不是输出模板）：\n'+content
        (ROOT / ('请求/'+rid+'.md')).write_text(prompt+'\n',encoding='utf-8')
        write(ROOT/('请求/'+rid+'.json'),{'request_id':rid,'messages':[{'role':'user','content':prompt}],'status':'prepared_not_executed'})
        h=2166136261
        for char in prompt: h=((h^ord(char))*16777619)&0xffffffff
        requests.append({'request_id':rid,'scene':scene_id,'condition':condition,'material':mid,
                         'request_file':'请求/'+rid+'.md','characters':len(prompt),'sha256':sha(prompt.encode('utf-8')),
                         'fnv1a_utf16':h,'replicate':1,'status':'prepared_not_executed'})
write(ROOT/'管理清单.json',{'trial_version':'0.5-resources-1','request_count':12,'requests':requests,'materials':materials,
    'scenes':[s for s in old['scenes'] if s['id'] in specs], 'conditions':{'K':'仅核心','R':'核心加相关通用入口选段','E':'R加场景变体入口；N52无此入口，与R文本相同，作为重复参照'},
    'selection':specs,'source_hashes':{name:sha((PROJECT / ('视觉表现资源/'+name.removeprefix('构思资源/') if name.startswith('构思资源/') else '助手指令/共用内容/'+name)).read_bytes()) for name in ['核心指令.md',*files.values()]},
    'output_contract':old['output_contract'],'limitations':['one_sample_per_unique_condition','known_public_tasks','unequal_input_length','scenario_entries_add_directions_not_only_examples','not_full_package_or_video_test']})
sequence=[{'request_id':r['request_id'],'review_id':f'Q{i+1:03d}','status':'prepared_not_executed'} for i,r in enumerate(requests)]
random.Random(20261011).shuffle(sequence)
for i,item in enumerate(sequence): item['order']=i+1
write(ROOT/'运行顺序.json',sequence)
write(ROOT/'运行状态.json',{'status':'prepared_not_executed','completed_requests':0,'video_runs':0})
print(json.dumps({'order':[r['request_id'] for r in sequence],'requests':[{k:r[k] for k in ('request_id','scene','condition','characters','fnv1a_utf16')} for r in requests]},ensure_ascii=False))
