# AI HANDOFF — Last Ritual

Обновлено: 03.11.2026  
Репозиторий: https://github.com/DoctorStrangeSH/Last-Ritual  
Main snapshot: `b78d299ca0aa8aa5c36dc3098068b4a8c0818a87` (PR #387–#389 gameplay and PR #391 docs merged). PR #389 exact-head CI #41652362559 and post-merge #41652792964 — SUCCESS; docs post-merge #41653573389 SUCCESS.

## Как продолжить

Перед изменениями прочитать:
1. AGENTS.md
2. docs/PROJECT_STATE.md
3. docs/ROADMAP.md
4. docs/AI_HANDOFF_PIXEL_ART.md
5. docs/art/SOUL_ALTAR_ART_NEXT_STEPS.md
6. docs/DECISIONS.md и соответствующий модульный код/тесты.

Работать только от актуального main. Создавать отдельную ветку и PR. Не коммитить прямо в main. Проверять exact-head CI и post-merge main workflow. Обновлять PROJECT_STATE, ROADMAP и handoff при каждом значимом изменении.

## Видение владельца

- Только top-down roguelike + Tower Defense. Старый платформенный прототип не возвращать.
- Днём — стратегическая защита крепости; ночью — исследование комнат и бои в духе Isaac.
- Пять дней/ночей, автоматические переходы, новые карты на каждый забег.
- Длинные, вариативные и стратегические забеги; не сводить игру к короткому прототипу.
- Мрачный детальный Pixel Art для всей игры, единая перспектива и читаемые силуэты.
- Русский UI и понятные мышиные взаимодействия.
- Башни улучшаются L1→L2→L3, четвёртый шаг — выбор специализации.
- Приоритет качества: не включать черновой арт в production ради формального прогресса.

## Проверенное текущее состояние

- Main scene: scenes/run_loop.tscn.
- Day TD: scenes/topdown_td_prototype.tscn; шесть волн, восемь площадок, строительство/улучшение/продажа/ремонт, герой и приоритет целей.
- Night: scenes/topdown_night_prototype.tscn; комнаты, двери, враги, награды, магазины, босс, рывок.
- Campaign: пять циклов дня/ночи; переходы автоматические.
- Meta: scripts/meta_progression.gd.
- Магазин сейчас имеет четыре игровых башни: bone/fire/necro/frost.
- Каталог дополнительно содержит spark/pulse, но их самостоятельная боевая интеграция не завершена.
- Tower helpers находятся в scripts/td/. Основные TD/night scripts всё ещё крупные Node2D scripts; не считать архитектуру полностью компонентной.

## Приоритет разработки по последнему решению владельца (03.11.2026)

**Графику временно заморозить. Следующая основная работа — игровой процесс TD Roguelike.** Не начинать новые арт-паки, runtime art migration или замену спрайтов, пока владелец явно не вернёт этот приоритет.

Наблюдаемая текущая реализация:
- `scripts/run_loop.gd` создаёт новый `fortress_map_seed` при `start_run()` и передаёт его в дневную сцену при каждом `start_phase()`.
- `scripts/td/td_run_map_generator.gd` в main генерирует две/три кривые линии с общим входом и выходом; в средней части маршруты расходятся на отдельные коридоры и снова сходятся. Профиль изгибов воспроизводим по seed.
- Восемь площадок остаются стабильными по ID 0–7 в пределах забега. Соседние площадки каждого ряда гарантированно находятся в пределах 190 px — текущего радиуса синергий башен; валидатор и тесты защищают это правило для 256 seed.
- `run_loop.gd` задаёт seed до импорта состояния крепости. `export_fortress_state()` сохраняет постройки по ID и `map_seed`; `import_fortress_state()` отклоняет snapshot от другого seed. Smoke tests проверяют 256 seed, топологию fork/merge, геометрию, строительство, улучшение и перенос башни; полный `topdown_smoke.gd` проверяет боевые синергии.
- PR #387 merged (`a29bc17f`), PR #388 docs-only (`41584b11`), PR #389 fork/merge routes (`c372d377`), PR #391 handoff (`b78d299c`) merged. Exact-head #41652362559 and post-merge #41652792964 SUCCESS; docs post-merge #41653573389 pending.
- Ограничение main: площадки пока распределяются в двух почти фиксированных рядах. Ветка `feature/td-build-site-layouts-rebased` расширяет сдвиг/шаг рядов и добавляет проверку радиуса площадки относительно дорог, входа/выхода и фиксированных UI hitboxes; exact-head CI впереди. Сохранение специализаций и legacy snapshots ещё впереди.

После этой ветки проверить фактическую читаемость площадок на Windows, затем перенести специализации/приоритеты и проверить обратную совместимость legacy snapshots. Не переходить к волновой стратегии, пока критерии A–C из ROADMAP не закрыты.

После карты — стратегические ветвления волн/маршрутов, разведка следующей волны, значимые inter-wave решения, более длинная кривая сложности и связка дневных решений с ночными наградами. Не увеличивать длительность простым растягиванием таймеров.

## Текущий художественный этап: модульный Pixel Art

### Алтарь душ — production integration завершена
- PR #376 merged; root manifest assets/spire/towers/necro/manifest.json: owner_approved_production / runtime_enabled=true.
- Владелец одобрил L1–L3 и base/Reaper/Legion 8-way оружие 03.11.2026.
- Production base и weapon PNG совпадают с утверждённым source archive; существующие production VFX переиспользуются.
- Старые цельные sprites/fallback сохранены до ручного Windows QA. Не удалять до reference audit.

### Ледяной обелиск — candidate-only
- PR #378 merged; exact-head CI #41583127652 и post-merge Windows Preview #41583281398 SUCCESS.
- Root manifest: assets/spire/towers/frost/manifest.json; review_candidate / runtime_enabled=false.
- 3 bases, base/Frost Lance/Blizzard 8-way weapons, 6 VFX strips.
- Mapping: siege → frost_lance; swarm → blizzard.
- Source: tools/generate_frost_modular_candidates.py; preview: tools/render_frost_modular_preview.py.
- Owner visual approval is still pending. Do not enable runtime; preserve current experimental fallback.

### Костяная баллиста — candidate-only, текущая ветка
- PR #380 merged; exact-head CI #41585101342 and post-merge Windows Preview #41585253951 SUCCESS.
- Root manifest: assets/spire/towers/ballista/manifest.json; review_candidate / runtime_enabled=false.
- 3 bases, base/siege_bolt/bone_volley 8-way weapon atlases, 6 VFX strips.
- Mapping: siege → siege_bolt (heavy single target), swarm → bone_volley (three-bolt volley).
- Gameplay ID stays bone; asset folder is ballista. No stats, balance, save IDs or live Foozle PNGs changed.
- Source: tools/generate_ballista_modular_candidates.py; preview: tools/render_ballista_modular_preview.py; tests: tests/test_ballista_modular_candidates.py.
- Review sheets: candidate/review/contact_sheet_9_1x.png, contact_sheet_72_1x.png, contact_sheet_72_2x.png; published in windows-preview.
- Candidate remains disabled pending owner visual approval and a separate runtime PR.

### Огненная турель — текущий candidate branch
- PR #382 merged; exact-head CI #41589195484 and post-merge Windows Preview #41589363962 SUCCESS.
- Root manifest: assets/spire/towers/fire/manifest.json; review_candidate / runtime_enabled=false.
- 3 bases, base/inferno/sparks 8-way weapon atlases, 6 VFX strips (8 frames each).
- Mapping: siege → inferno (heavy flame cannon/explosive impact); swarm → sparks (three-spark volley). Existing UI labels remain unchanged.
- Gameplay ID stays fire. No combat values, save IDs, legacy Foozle PNGs or live runtime paths changed.
- Source: tools/generate_fire_turret_modular_candidates.py; preview: tools/render_fire_turret_modular_preview.py; tests: tests/test_fire_turret_modular_candidates.py.
- Review sheets: assets/spire/towers/fire/candidate/review/contact_sheet_9_1x.png, contact_sheet_72_1x.png, contact_sheet_72_2x.png; published in windows-preview.
- Candidate is not owner-approved. Preserve all current original fire assets and do not enable runtime.

### Враги осады и Страж ритуала — review candidate, отдельная ветка

- PR #384 merged (`35e719e4`); exact-head CI #41605666907 and post-merge Windows Preview #41605855395 SUCCESS.
- Manifest: `assets/enemies/manifest.json`; `status=review_candidate`, `runtime_enabled=false`.
- Six visual roles: runner, brute, captain, healer, ranged, boss. Each has 8 distinct facing directions × 4 distinct walk frames at 8 FPS; normal roles are 48×48, Ritual Guardian is 96×96.
- TD mapping: runner/brute/captain/healer/boss. Night mapping: regular/flanker → runner, ranged → ranged, champion → brute, boss → boss.
- Source: `tools/generate_enemy_roster_pixel_art.py`; review renderer: `tools/render_enemy_roster_preview.py`; tests: `tests/test_enemy_roster_pixel_art.py`.
- Review sheets: `assets/enemies/candidate/review/enemy_roster_8way_1x.png`, `enemy_walk_cycles_1x.png`, and matching `_2x.png` sheets; all four are published in `windows-preview`.
- Fixed the previous CI findings: the boss now has four visibly distinct walk poses; its 96px atlas fits all eight cells without corner clipping. Generator, reproducibility and review-sheet tests passed in one-shot generation run #41605211560.
- This is art-only. Existing vector runtime stays active; no enemy stats, hitboxes, movement, attacks, waves, or saves changed. Do not promote before owner visual approval and a separate runtime PR.

### Deferred art work — paused by owner
- Owner review of Fire, Frost, Ballista and enemy roster is deferred. CI/contact sheets are not artistic approval.
- After explicit approval, prepare separate runtime PR per tower, preserving current fallback until Windows QA.
- Continue world/enemy/UI Pixel Art migration after tower reviews.

## Ограничения и безопасность

- Не включать модульный runtime, пока отсутствуют все шесть production PNG и владелец не принял полный набор в Windows.
- Не считать контактный лист, smoke test или CI художественным одобрением.
- Не менять боевые характеристики, цены, сохранения или UI в арт-only PR.
- Не вращать всю башню: основание неподвижно, оружие имеет 8 hand-authored направлений.
- Не удалять старые PNG/SVG/атласы без поиска прямых и динамических ссылок.
- Не придумывать Aseprite-исходники. Источник candidate PNG — Python/Pillow generator.
- Не менять legacy gameplay IDs и save schema без отдельной миграции и тестов.

## Проверки и сборка

Godot: 4.4.1 Standard. Главный workflow: .github/workflows/windows-build.yml.

Локальные команды:
- godot --headless --path . --editor --quit
- godot --headless --path . --script res://tests/topdown_smoke.gd
- godot --headless --path . --script res://tests/td_modular_tower_assets_smoke.gd
- python tools/generate_necro_modular_candidates.py --verify
- python -m unittest discover -s tests -p 'test_necro_weapon_silhouettes.py' -v
- python -m unittest discover -s tests -p 'test_necro_modular_preview.py' -v
- python -m unittest discover -s tests -p 'test_necro_modular_vfx.py' -v

Важно: обычный запуск generator перезаписывает все 12 candidate PNG. Если изменён только один атлас, проверь diff и не коммить случайно пересозданные файлы. Отличия Pillow могут влиять на байты. Запуск --verify ничего не изменяет.

Motion Preview:
- 1/2/3 — уровень основания;
- B/R/L — base/Reaper/Legion;
- NumPad 8/9/6/3/2/1/4/7 — зафиксировать направление;
- A — автоматическое наведение;
- H — направляющие;
- F — выстрел и анимация попадания;
- Z — масштаб 1×/2×/2.5×/4×.

Windows Release: https://github.com/DoctorStrangeSH/Last-Ritual/releases/tag/windows-preview

## PR-аудит и открытые запросы

Проверена история PR #1–#355 по списку, заголовкам, статусам и датам; последние изменения #354/#355 проверены подробно. Не утверждать, что каждый исторический diff и каждый старый комментарий перечитан построчно.

- #355 — merged, документация после #354.
- #354 — merged, Reaper/Legion weapon v4 candidate.
- #295 — единственный оставленный открытым Draft review snapshot Frost Obelisk. Не включать эти PNG в production без отдельной художественной приёмки.
- #289 закрыт как superseded более поздними Soul Altar assets; ветка остаётся в истории.
- Других открытых Issues на момент аудита не найдено.

## Формат следующего отчёта владельцу

Указать: что сделано, номер PR и commit, exact-head CI, post-merge CI, что проверено автоматически, что осталось проверить вручную и один следующий шаг.
