# Исходники утверждённого стиля Last Ritual

**Статус на 31.10.2026**: оригинальные четыре PNG сохранены **без изменений** в архиве `LastRitual_Art_Source_2026-10-31.zip` (8 494 463 байта) и загружены в личную Библиотеку файлов проекта: `/Last Ritual/Art Sources/` (`library_file_id: libfile_93652e51e27c819189ea8175f359ae85`).

**Важно:** в этом PR в GitHub добавлены только метаданные и инструкция. Сами большие PNG **ещё не закоммичены в GitHub**. Чтобы сделать их полностью независимыми от аккаунта/чата, нужно взять ZIP из Библиотеки или файл, приложенный к текущему ответу, распаковать в корень репозитория и закоммитить содержимое `docs/art/source/` отдельным PR.

Архив содержит:
- `six_tower_concept_board_v1.png` — согласованное оформление шести башен.
- `six_tower_ui_board_v1.png` — большой UI/спрайтовый художественный концепт.
- `necro_tower_concept_levels_v1.png` — три уровня некромантской башни.
- `frost_tower_concept_levels_v1.png` — три уровня ледяной башни.
- `manifests/source_art_manifest.json` — оригинальные SHA-256, размеры и происхождение.

## Процедура для следующих ИИ
1. Получить оригинальный архив из Библиотеки файлов `/Last Ritual/Art Sources/` или у владельца.
2. `unzip LastRitual_Art_Source_2026-10-31.zip -d .`
3. `sha256sum docs/art/source/concepts/*.png` и сверить с `source_art_manifest.json`.
4. Коммитить исходные неизменённые PNG под `docs/art/source/concepts/` вместе с манифестом. НЕ помещать большие concept boards в `assets/spire/towers/` в качестве игрового спрайта.
5. Для новых игровых PNG использовать `docs/art/STYLE_BIBLE.md`, `docs/art/ASSET_SPEC.md` и `docs/art/PROMPT_LIBRARY.md`; делать отдельные RGBA спрайты, проверять pivot, FPS, альфу и import в Godot.
6. Создавать изменения в отдельных PR; не считать художественную концепцию уже реализованной в игре.

Отдельные SVG иконки (12 штук) **уже в GitHub** по путям `assets/spire/towers/*/specializations/{siege,swarm}/icon.svg`. Остальные большие исходники в момент этого коммита доступны через ZIP в Library.

## Importer: проверка и восстановление без потери качества

Скрипт `tools/import_source_art.py` — безопасное восстановление оригинальных PNG из архива. Он сверяет точные SHA-256 и размер каждого файла с репозиторным манифестом, проверяет ZIP CRC и PNG signature, запрещает небезопасные пути и не перезаписывает уже изменённые оригиналы.

```bash
python tools/import_source_art.py LastRitual_Art_Source_2026-10-31.zip --verify-only
python tools/import_source_art.py LastRitual_Art_Source_2026-10-31.zip
git add docs/art/source/concepts/
git commit -m "Import unchanged original concept PNGs"
```

Если ZIP не совпадает с зафиксированными хешами, скрипт завершится ошибкой до записи файлов. В GitHub Actions также выполняются независимые тесты самого импортёра. Архив не нужно сохранять повторно внутри git, достаточно 4 PNG и манифеста.

