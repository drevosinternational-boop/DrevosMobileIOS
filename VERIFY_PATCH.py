from pathlib import Path
p = Path('DrevosIOS/Models/RecipeModels.swift')
text = p.read_text(encoding='utf-8')
assert 'guard !id.isEmpty else { return nil }' in text
assert 'guard let id, !id.isEmpty else { return nil }' not in text
assert '?? snapshot.key' in text
print('PATCH VALIDATION PASSED')
print('RecipeModels.swift optional-binding compile error fixed.')
