"""冻结新场景母版请求，逐项冻结转换输入，登记网页可见输出。"""
from pathlib import Path
from datetime import datetime, timezone
import json, hashlib, sys

PROJECT = Path(__file__).resolve().parent.parent.parent
ROOT = PROJECT / '资料归档/创作案例与验证/实际试验/DeepSeek-v0.5-母版转换'
def sha(b): return hashlib.sha256(b).hexdigest()
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def write(p, x): p.write_text(json.dumps(x, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
def request(rid, scene, kind, body, dependency=None):
    path=ROOT/('请求/'+rid+'.md')
    if path.exists(): raise SystemExit('请求已冻结，不覆盖')
    path.write_text(body+'\n', encoding='utf-8')
    write(path.with_suffix('.json'), {'request_id':rid,'messages':[{'role':'user','content':body}]})
    h=2166136261
    for unit in [int.from_bytes(body.encode('utf-16-le')[i:i+2],'little') for i in range(0,len(body.encode('utf-16-le')),2)]:
        h=((h^unit)*16777619)&0xffffffff
    return {'request_id':rid,'scene':scene,'condition':kind,'sha256':sha(body.encode()),
            'characters':len(body.encode('utf-16-le'))//2,'fnv1a_utf16':h,'dependency':dependency}

mode=sys.argv[1]
if mode=='prepare':
    if ROOT.exists(): raise SystemExit('已准备，不覆盖')
    for folder in ('冻结材料','请求','原始输出'): (ROOT/folder).mkdir(parents=True)
    sources=['核心指令.md','输出与信息保留.md']
    materials=[]
    for name in sources:
        data=(PROJECT / ('视觉表现资源/'+name.removeprefix('构思资源/') if name.startswith('构思资源/') else '助手指令/共用内容/'+name)).read_bytes()
        (ROOT/'冻结材料'/name).write_bytes(data)
        materials.append({'condition':name,'frozen_file':'冻结材料/'+name,'sha256':sha(data)})
    scenes=[
        {'id':'C01','request':'8 秒日式二维，少女在白天的空教室里静静坐着；单镜头，不添加剧情事件。'},
        {'id':'C02','request':'8 秒日式二维，一名人物站在有立柱的室内，一束室外移动的光照入；人物基本不动，单镜头。'},
        {'id':'C03','request':'8 秒日式二维，一滴水落入浅水盘，水面映着窗框；固定近景单镜头。'},
        {'id':'C04','request':'10 秒日式二维，山间的雾缓慢穿过树林；固定远景单镜头，不添加人物。'}]
    contract='交付一份 600–900 个中文字符的简短艺术母版，明确选定的观看重点、画面布局、可见发展、关键关系与形式节奏。可分段，不写候选列表、制作流程或原理教材；不要输出视频提示词，不展示内部思考。未指定条件自行作明确创作选择。'
    core=(ROOT/'冻结材料/核心指令.md').read_text(encoding='utf-8').strip()
    reqs=[]
    for i,s in enumerate(scenes,1):
        body='创作要求：\n'+s['request']+'\n\n交付要求：\n'+contract+'\n\n创作指令：\n'+core
        reqs.append(request(f'M{i:03d}',s['id'],'art_master',body))
    write(ROOT/'管理清单.json', {'trial_version':'0.5-conversion-1','materials':materials,'scenes':scenes,'requests':reqs,
        'planned_requests':8,'master_contract':contract,'limitations':['diagnostic_not_randomized_comparison','one_master_per_scene','core_only_master','new_conversation_conversion','conversion_requests_frozen_after_master_capture','no_blind_review_or_video']})
    write(ROOT/'运行状态.json',{'status':'prepared_not_executed','completed_requests':0,'video_runs':0})
    (ROOT/'README.md').write_text('# 新场景艺术母版与转换诊断\n\n四个新场景，每场景先生成母版，再在独立新会话中转换为提示词。母版请求在首项运行前冻结；转换请求待母版采集后逐项冻结，转换发送前不得更改。母版不加载构思资源，转换仅加载该场景要求、原样母版和输出约定全文。没有直接成稿对照，不据此证明两阶段更优。\n\n只保存可见最终交付，不保存隐藏思考。后台版本未知；深度思考开、搜索关。独立会话降低历史补全，但同一平台与模型并不构成独立评审。评审区分用户要求、核心表现、成立条件与形式节奏；母版已有问题、转换新增问题、正常压缩与无法判断分别记录，不用字数或术语计分。不是新资源或完整包验证，也没有视频生成。\n',encoding='utf-8')
    print(json.dumps(reqs,ensure_ascii=False))
elif mode=='conversion':
    mid=sys.argv[2]; manifest=read(ROOT/'管理清单.json')
    rec=read(ROOT/('原始输出/'+mid+'.json'))
    master=(ROOT/rec['response_file']).read_text(encoding='utf-8').rstrip('\r\n')
    parent=next(r for r in manifest['requests'] if r['request_id']==mid)
    scene=next(s for s in manifest['scenes'] if s['id']==parent['scene'])
    rid='P'+mid[1:]
    spec=(ROOT/'冻结材料/输出与信息保留.md').read_text(encoding='utf-8').strip()
    body='原始创作要求：\n'+scene['request']+'\n\n转换任务：\n将下面艺术母版转成一份 300–500 个中文字符、可独立理解的连续视频生成提示词。保留选定设计，不重新构思；压缩解释与装饰，保留决定画面表现的关系及必要条件。只输出提示词，不写分析或信息保留清单。若存在实质冲突，不暗中替换设计，可简短指出。未指定生成模型，不猜测模型限制。\n\n艺术母版（完整原文）：\n'+master+'\n\n转换约定：\n'+spec
    req=request(rid,parent['scene'],'conversion',body,{'request_id':mid,'response_sha256':rec['response_sha256']})
    manifest['requests'].append(req); write(ROOT/'管理清单.json',manifest)
    print(json.dumps(req,ensure_ascii=False)); print(body)
elif mode=='record':
    rid,url=sys.argv[2:4]; manifest=read(ROOT/'管理清单.json')
    req=next(r for r in manifest['requests'] if r['request_id']==rid)
    target=ROOT/('原始输出/'+rid+'.json')
    if target.exists(): raise SystemExit('已登记，不覆盖')
    path=target.with_suffix('.md'); answer=path.read_text(encoding='utf-8').rstrip('\r\n')
    write(target,{'request_id':rid,'eligible_for_primary':True,'status':'completed_visible_answer_captured',
        'conversation_url':url,'captured_at':datetime.now(timezone.utc).isoformat(),'platform':'DeepSeek web',
        'backend_model_version':None,'thinking_mode':True,'search_mode':False,'reasoning_saved':False,
        'request_sha256':req['sha256'],'response_file':'原始输出/'+rid+'.md','response_sha256':sha(path.read_bytes()),
        'answer_characters':len(answer.encode('utf-16-le'))//2})
    count=len(list((ROOT/'原始输出').glob('*.json')))
    write(ROOT/'运行状态.json',{'status':'completed_conversion_diagnostic' if count==8 else 'running',
        'completed_requests':count,'excluded_responses':0,'video_runs':0})
    print(json.dumps({'id':rid,'completed':count,'characters':len(answer)},ensure_ascii=False))
else: raise SystemExit('未知操作')
