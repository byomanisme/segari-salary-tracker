import json

with open(r'c:\Users\MyBook Hype AMD\KULIAH SISTEM INFORMASI\project apa aja\hitung_gaji_segari\portfolio_web\version_2.dart', 'r', encoding='utf-8') as f:
    raw = f.read()

try:
    content = json.loads(raw)
except:
    content = raw

with open(r'c:\Users\MyBook Hype AMD\KULIAH SISTEM INFORMASI\project apa aja\hitung_gaji_segari\portfolio_web\build5_v2.dart', 'w', encoding='utf-8') as out:
    out.write(content)

print('Lines in build5_v2.dart:', len(content.splitlines()))
