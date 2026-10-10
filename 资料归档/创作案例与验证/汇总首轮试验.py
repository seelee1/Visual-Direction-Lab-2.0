"""校核首轮冻结输入与已保存的最终回答，生成描述统计和条件隐藏评审材料。"""
from pathlib import Path
import hashlib
import json
from collections import defaultdict

ROOT = Path(__file__).resolve().parent / '实际试验' / 'DeepSeek-v0.4-首轮'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def write(path, obj):
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

manifest = read(ROOT / '管理清单.json')
sequence = read(ROOT / '运行顺序.json')
requests = {r['request_id']: r for r in manifest['requests']}
for material in manifest['materials']:
    assert sha(ROOT / material['frozen_file']) == material['sha256'], material
for req in requests.values():
    payload = read(ROOT / '请求' / (req['request_id'] + '.json'))['messages'][0]['content']
    assert hashlib.sha256(payload.encode('utf-8')).hexdigest() == req['sha256'], req
    assert (ROOT / req['request_file']).read_text(encoding='utf-8').rstrip('\r\n') == payload

records = [read(p) for p in sorted((ROOT / '原始输出').glob('*.json'))]
valid = [r for r in records if r.get('eligible_for_primary', True)]
assert len(valid) == 16 and {r['request_id'] for r in valid} == set(requests)
groups = defaultdict(list)
rows = []
for record in records:
    assert sha(ROOT / record['response_file']) == record['response_sha256'], record
    assert record['request_sha256'] == requests[record['request_id']]['sha256']
for record in valid:
    answer = (ROOT / record['response_file']).read_text(encoding='utf-8').rstrip('\r\n')
    count = len(answer.encode('utf-16-le')) // 2
    assert count == record['answer_characters']
    req = requests[record['request_id']]
    groups[req['condition']].append(count)
    rows.append({'request_id': req['request_id'], 'scene': req['scene'],
                 'condition': req['condition'], 'characters': count,
                 'length_compliant': 300 <= count <= 500,
                 'conversation_url': record['conversation_url']})
    order = next(x for x in sequence if x['request_id'] == req['request_id'])
    scene = next(s for s in manifest['scenes'] if s['id'] == req['scene'])
    (ROOT / '评审' / (order['review_id'] + '.md')).write_text(
        '# ' + order['review_id'] + '\n\n创作要求：' + scene['request'] +
        '\n\n交付要求：' + manifest['output_contract'] + '\n\n回答：\n\n' + answer + '\n', encoding='utf-8')
write(ROOT / '描述统计.json', {
    'primary_outputs': 16, 'excluded_outputs': len(records) - 16,
    'characters_definition': '最终可见文本的 UTF-16 长度，包含标点、数字和内部换行，去除文件结尾换行',
    'conditions': {key: {'n': len(vals), 'mean_characters': sum(vals)/len(vals),
                         'min_characters': min(vals), 'max_characters': max(vals),
                         'length_compliant': sum(300 <= v <= 500 for v in vals)}
                   for key, vals in groups.items()},
    'rows': sorted(rows, key=lambda r: r['request_id']),
    'not_an_effectiveness_score': True})
state = read(ROOT / '运行状态.json')
state.update(status='completed_pilot_outputs_captured', completed_requests=16,
             completed_responses_including_excluded=len(records), excluded_responses=len(records)-16,
             submitted_requests=len(records), video_runs=0)
state['notes'].extend(['首轮每条件每场景仅一次；不构成统计证据', '本轮评审由项目作者知晓条件进行，不是盲评'])
state['notes'] = list(dict.fromkeys(state['notes']))
write(ROOT / '运行状态.json', state)
print(json.dumps({'verified_primary_outputs': 16, 'excluded_outputs': len(records)-16,
                  'frozen_materials': 3, 'frozen_requests': 16,
                  'review_packets': 16, 'length_compliant': sum(r['length_compliant'] for r in rows)}, ensure_ascii=False))
