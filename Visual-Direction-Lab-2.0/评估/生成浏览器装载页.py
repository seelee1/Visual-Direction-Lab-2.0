"""把已冻结的请求呈现为本地只读网页，供浏览器按原文装载。"""
from pathlib import Path
from html import escape
import hashlib
import json

trial = Path(__file__).parent / '实际试验' / 'DeepSeek-v0.4-首轮'
output = trial / '浏览器装载'
output.mkdir(exist_ok=True)
manifest = json.loads((trial / '管理清单.json').read_text(encoding='utf-8'))
links = []
for record in manifest['requests']:
    source = trial / record['request_file']
    raw = source.read_bytes()
    if hashlib.sha256(raw).hexdigest() != record['sha256']:
        raise ValueError('冻结请求发生变化：' + record['request_id'])
    text = raw.decode('utf-8')
    identifier = record['request_id']
    page = (f'<!doctype html><meta charset="utf-8"><title>{identifier}</title>'
            f'<h1>{identifier}</h1><p id="metadata">字符数：{len(text)}；SHA256：{record["sha256"]}</p>'
            f'<label for="prompt">请求正文</label><textarea id="prompt" readonly rows="25" style="width:98%">{escape(text)}</textarea>')
    (output / (identifier + '.html')).write_text(page, encoding='utf-8')
    links.append(f'<li><a href="{identifier}.html">{identifier}</a></li>')
(output / 'index.html').write_text('<!doctype html><meta charset="utf-8"><title>冻结测试请求</title><h1>冻结测试请求</h1><ul>' + ''.join(links) + '</ul>', encoding='utf-8')
print(json.dumps({'pages': len(links), 'directory': str(output)}, ensure_ascii=False))
