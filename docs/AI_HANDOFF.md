# AI HANDOFF — Last Ritual

Обновлено: 03.11.2026  
Репозиторий: https://github.com/DoctorStrangeSH/Last-Ritual  
Main snapshot: 96d25c3785958eba5a2d1fe490512025ee92a19f  
Последний main CI: #41583706343 — SUCCESS. Активная ветка кандидата: feat/ballista-modular-pixel-art-candidate.

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

## Текущий художественный этап: модульный Pixel Art башен

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
- Branch: feat/ballista-modular-pixel-art-candidate.
- Root manifest: assets/spire/towers/ballista/manifest.json; review_candidate / runtime_enabled=false.
- 3 bases, base/siege_bolt/bone_volley 8-way weapon atlases, 6 VFX strips.
- Mapping: siege → siege_bolt (heavy single target), swarm → bone_volley (three-bolt volley).
- Gameplay ID stays bone; asset folder is ballista. No stats, balance, save IDs or live Foozle PNGs changed.
- Source: tools/generate_ballista_modular_candidates.py; preview: tools/render_ballista_modular_preview.py; tests: tests/test_ballista_modular_candidates.py.
- Review sheets: candidate/review/contact_sheet_9_1x.png, contact_sheet_72_1x.png, contact_sheet_72_2x.png.
- Candidate remains disabled pending owner visual approval and a separate runtime PR.

### Next art work
- Complete exact-head CI for the Ballista candidate PR, merge only after checks pass.
- Owner reviews Frost and Ballista at 1×. CI/contact sheets are not artistic approval.
- After explicit approval, prepare separate runtime PR per tower, preserving current fallback until Windows QA.
- Fire Turret Pixel Art candidate follows Ballista; then enemies/world/UI.

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
