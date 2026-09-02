DREVOS iOS RecipeModels compile fix V10

Replace only:
  DrevosIOS/Models/RecipeModels.swift

Why:
  snapshot.key is a non-optional String. After `?? snapshot.key`, local `id` is already String,
  so `guard let id` is invalid. The corrected guard only checks whether the String is empty.

Do not replace GoogleService-Info.plist or other project files.

Optional validation from repository root:
  py VERIFY_PATCH.py
