## Текущий приоритет разработки (решение владельца, 03.11.2026)

Графику и Pixel Art migration временно не развивать. Приоритет — TD Roguelike gameplay. Следующая реализация должна связать процедурные маршруты и площадки строительства в единую seed-based карту забега.

На main `277b95dc56597775d20555c9c1b3e9c688fdce39` seed создаётся в `scripts/run_loop.gd` и передаётся дневной сцене. В PR `feature/seeded-td-run-map` добавлен `scripts/td/td_run_map_generator.gd`, который генерирует маршруты и площадки из одного seed; TD сцена применяет их через `set_fortress_map_seed()`. Этап ожидает CI. Стабильные ID площадок 0–7 сохраняют привязку башен при импорте fortress state с тем же seed.

Очередь: (1) seed-based генерация извилистых маршрутов и площадок, (2) проверка геометрии и воспроизводимости на множестве seed, (3) сохранение башен на стабильных площадках между днями, (4) тактические ветвления волн и разведка, (5) связка дневной обороны с ночными наградами и более продолжительным roguelike-прогрессом. Подробные критерии — в `docs/ROADMAP.md` и `docs/AI_HANDOFF.md`.

# Last Ritual — текущий снимок проекта

Дата: 03.11.2026  
HEAD main: `277b95dc56597775d20555c9c1b3e9c688fdce39` (PR #386 merged). Main workflow #41630081283 — SUCCESS.

## Запускаемая игра

- Движок: Godot 4.4.1.
- Главная сцена: scenes/run_loop.tscn.
- Оркестратор: scripts/run_loop.gd.
- День: scenes/topdown_td_prototype.tscn + scripts/topdown_td_prototype.gd.
- Ночь: scenes/topdown_night_prototype.tscn + scripts/topdown_night_prototype.gd.
- Генератор комнат: scripts/dungeon_floor_graph.gd.
- Мета-прогресс: scripts/meta_progression.gd.

Пять дневных и пять ночных этапов связаны автоматическими переходами. Дневная TD содержит шесть волн и восемь площадок. Ночной граф включает десять связанных комнат с обязательными ролями, включая вход и босса. Seed фиксируется на забег.

## Боевые башни

Игровой магазин использует четыре ID: bone, fire, necro, frost. Прокачка: L1→L2 (20 золота), L2→L3 (40), затем выбор одной специализации (60). Состояние построек сохраняется между днями.

Каталог дизайна описывает шесть идентичностей. spark и pulse пока имеют статус art_ready_combat_pending и не являются самостоятельными боевыми системами. Не переименовывать legacy IDs и не менять формат сохранений без отдельной миграции.

## Алтарь душ — фактический статус

- Владелец явно одобрил основание L1–L3 и три восьминаправленных оружейных атласа (base, Жнец, Легион) 03.11.2026.
- В main шесть production PNG скопированы из approved source archive без изменения байтов; SHA blob каждой пары candidate/production совпадает.
- Root production manifest в main имеет `status=owner_approved_production`, `runtime_enabled=true`; candidate manifest сохранён как `approved_source_archive` и остаётся runtime-disabled.
- Существующие шесть production projectile/impact strips переиспользуются и проверяются. Новые candidate VFX не продвигаются этим PR.
- `scripts/topdown_td_prototype.gd` уже включает модульный рендер автоматически через `runtime_ready(manifest)`; gameplay, tower IDs, баланс и формат сохранений не менялись.
- Reaper соответствует specialization `siege`, Legion — `swarm`; основание неподвижно, оружие выбирает одну из восьми поз.
- Отдельного Aseprite проекта нет. Не создавать фиктивный файл; воспроизводимый источник геометрии — `tools/generate_necro_modular_candidates.py`.
- Старые цельные спрайты и fallback не удалялись: при неготовности production manifest renderer продолжает использовать прежний путь.

## Ледяной обелиск — модульный кандидат (отдельная ветка)

- PR #378 merged (`00c122a0`); exact-head CI #41583127652 SUCCESS; post-merge main/Windows Preview #41583281398 SUCCESS.
- Root manifest: `assets/spire/towers/frost/manifest.json`, статус `review_candidate`, `runtime_enabled=false`.
- Кандидат содержит 3 основания 128×128, три 8-way оружейных атласа (`base`, `frost_lance`, `blizzard`) и шесть восьмикадровых VFX strips. Review sheets 9/72 at 1×/2× опубликованы в `windows-preview`.
- Ветви специализаций: `siege → frost_lance` («Мороз: сильнее»), `swarm → blizzard` («Метель: быстрее»). Gameplay IDs и баланс не меняются.
- Воспроизводимый исходник: `tools/generate_frost_modular_candidates.py`; review renderer: `tools/render_frost_modular_preview.py`; PNG и контактные листы — в `assets/spire/towers/frost/candidate/`. Python tests: `tests/test_frost_modular_candidates.py`.
- Текущий экспериментальный Frost арт остаётся действующим. Новый набор не включён в live renderer и не считается одобренным.
- Общий manifest contract теперь допускает branch mapping на каждую башню; стандартное mapping Алтаря душ не меняется.
- TD renderer позиционирует основание по ground_anchor, а оружие — по собственному pivot. Добавлены проверки, что preview/runtime anchors не расходятся.

## Костяная баллиста — модульный кандидат (отдельная ветка)

- PR #380 merged (`5f34cc1c`); exact-head CI #41585101342 и post-merge Windows Preview #41585253951 SUCCESS.
- Root manifest: `assets/spire/towers/ballista/manifest.json`; `status=review_candidate`, `runtime_enabled=false`.
- 3 основания 128×128; 3 оружейных 8-way атласа: `base`, `siege_bolt`, `bone_volley`; 6 восьмикадровых VFX strips (projectile 32×32, impact 64×64).
- Mapping: `siege → siege_bolt` (тяжёлый одиночный болт), `swarm → bone_volley` (залп из трёх болтов). Labels сохраняют текущие design IDs и русские названия.
- Воспроизводимый источник: `tools/generate_ballista_modular_candidates.py`; review renderer: `tools/render_ballista_modular_preview.py`; Python tests: `tests/test_ballista_modular_candidates.py`.
- Review sheets: 9 композиций 1×, 72 позы 1×/2×; PNG находятся в `assets/spire/towers/ballista/candidate/` и опубликованы в `windows-preview` как `ballista_9_compositions_1x.png`, `ballista_modular_contact_sheet_1x.png`, `ballista_modular_contact_sheet.png`.
- Gameplay ID остаётся `bone`, folder ID — `ballista`; stats, damage, cooldown, economy, saves и текущие Foozle PNG не менялись.
- Новый набор не включён в runtime и не считается одобренным. Текущие исходные Foozle assets остаются рабочими до отдельного production PR и ручного QA.

## Огненная турель — модульный кандидат (отдельная ветка)

- PR #382 merged; exact-head CI #41589195484 и post-merge Windows Preview #41589363962 SUCCESS.
- Root manifest: assets/spire/towers/fire/manifest.json; status=review_candidate, runtime_enabled=false.
- 3 основания 128×128; 3 оружейных 8-way атласа: base, inferno, sparks; 6 восьмикадровых VFX strips (projectile 32×32, impact 64×64).
- Mapping: siege → inferno (тяжёлый огненный выстрел и взрыв), swarm → sparks (залп искр по нескольким целям). Существующие labels: ИНФЕРНО: ПЛАМЯ / ИСКРЫ: 3 ЦЕЛИ.
- Воспроизводимый источник: tools/generate_fire_turret_modular_candidates.py; review renderer: tools/render_fire_turret_modular_preview.py; tests: tests/test_fire_turret_modular_candidates.py.
- Review sheets: 9 композиций 1×, 72 позы 1×/2× в assets/spire/towers/fire/candidate/review/; опубликованы в windows-preview как fire_turret_9_compositions_1x.png, fire_turret_modular_contact_sheet_1x.png и fire_turret_modular_contact_sheet.png.
- Gameplay ID остаётся fire; stats, damage, cooldown, economy, saves и исходные Foozle PNG не менялись.
- Новый набор не включён в runtime и не считается одобренным. Оригинальные assets/spire/towers/fire/base, weapon, projectiles и weapon_impact сохранены.

## Враги осады и Страж ритуала — review candidate (отдельная ветка)

- PR #384 merged (`35e719e4`); exact-head CI #41605666907 and post-merge Windows Preview #41605855395 SUCCESS.
- Manifest: `assets/enemies/manifest.json`, `review_candidate` / `runtime_enabled=false`.
- Six roles: runner, brute, captain, healer, ranged, boss. Each atlas contains 8 directions × 4 walk frames at 8 FPS; regular enemies 48×48, boss 96×96.
- Mapping: TD runner/brute/captain/healer/boss; night regular/flanker→runner, ranged→ranged, champion→brute, boss→boss.
- Source/preview/tests: `tools/generate_enemy_roster_pixel_art.py`, `tools/render_enemy_roster_preview.py`, `tests/test_enemy_roster_pixel_art.py`.
- Review sheets: native 1× and enlarged 2× overview and walk-cycle sheets under `assets/enemies/candidate/review/`, also published in `windows-preview` as `enemy_roster_8way_1x.png`, `enemy_roster_8way_2x.png`, `enemy_walk_cycles_1x.png`, `enemy_walk_cycles_2x.png`.
- Generator run #41605211560 passed; previous duplicate boss frame and edge-clipping issues are fixed.
- Existing vector enemy renderer remains live. No gameplay stats, hitboxes, movement, attacks, waves or saves changed. Owner visual approval and separate runtime integration remain mandatory.

## Текущие инструменты просмотра

Release windows-preview:
https://github.com/DoctorStrangeSH/Last-Ritual/releases/tag/windows-preview

В релизе есть игровой LastRitual.exe, отдельный LastRitual-ArtPreview.exe и контактные листы 72 композиций в исходном 1× и увеличенном 2× размере. Art Preview не является игровым EXE.

## Проверки

Основной workflow: .github/workflows/windows-build.yml. Он импортирует проект в Godot 4.4.1, выполняет Python asset tests, Godot headless smoke tests и Windows export.

Ключевые тесты:
- tests/topdown_smoke.gd
- tests/td_modular_tower_assets_smoke.gd
- tests/soul_altar_art_gate.gd
- tests/soul_altar_assembled_review_smoke.gd
- tests/soul_altar_modular_candidate_smoke.gd
- tests/soul_altar_modular_motion_preview_smoke.gd
- tests/test_frost_modular_candidates.py
- tests/test_necro_weapon_silhouettes.py
- tests/test_necro_modular_preview.py
- tests/test_necro_modular_vfx.py

CI не заменяет ручной запуск EXE и визуальную приёмку.

## Обновление 03.11.2026 — композиционный тест

- PR #372 merged (`e6f9ae202ed4259c47173e70409f262f9487f3ab`), exact-head CI #41575959537 SUCCESS.
- `tests/test_soul_altar_compact_review.py` сверяет все девять кадров 1× с соответствующими кандидатными основаниями и северной позой оружия; workflow запускает тест автоматически.
- На момент записи этого исторического пункта production integration ещё не была выполнена; сейчас PR #376 merged и post-merge CI #41580061364 SUCCESS.
- На момент записи production manifest был выключен; после одобрения владельца PR #376 включил его в main.

## Незакрытые риски

- PR #376 exact-head CI #41579876954 SUCCESS; post-merge main/Windows export #41580061364 SUCCESS.
- Нужен ручной игровой QA в Windows EXE: размещение, уровни L1–L3, смена специализаций, восемь направлений и эффекты выстрела/попадания.
- Frost modular art пока candidate-only; владелец ещё не утвердил его для production.
- Полная миграция всех башен, врагов, окружения и UI на Pixel Art не завершена.
- Самостоятельные gameplay ID spark/pulse ещё не интегрированы.
- Нужен повторный ручной playtest актуальной Windows-сборки после последних изменений.

## Исторический контрольный пункт после PR #370 (до одобрения и интеграции)

- PR #369: компактный лист `soul_altar_9_compositions_1x.png` опубликован в `windows-preview`, main workflow #41506868156 SUCCESS.
- PR #370: автоматический запрет случайного продвижения candidate-арта в production, exact-head CI #41507365642 SUCCESS, merged `9ec0683855e1fa342938c7768caf8a251711d0eb`.
- Специализации: base weapon v4 (#357), Legion v5 (#365), Reaper v5 (#367); основания L1–L3 с контрастными рунами (#363).
- Художественная приёмка владельца получена 03.11.2026; модульный renderer включён в main после PR #376.

## Текущее следующее действие — Pixel Art review

Просмотреть контактные листы Frost и Ballista на 1× и получить художественную приёмку владельца. Оба candidate pack runtime-disabled; старые рабочие ресурсы остаются нетронутыми. После одобрения — отдельный runtime PR для каждой башни и ручной Windows QA.

## Следующее действие

Попросить владельца запустить свежий LastRitual.exe из windows-preview и проверить Алтарь душ в TD: L1→L2→L3, Reaper/Legion, восемь направлений, выстрел/попадание, центрирование и save/load. При дефектах — отдельные fix PR; не удалять legacy fallback до успешного QA.

## Проверка полного художественного листа — 03.11.2026

- PR #374 merged: `0d63e80662ca8762a1b3475bb3d5d4e166c7b302`.
- Exact-head CI #41578037939 SUCCESS: новый `tests/test_soul_altar_full_sheet_integrity.py` проверяет пиксели всех 72 вариантов (L1–L3 × base/Reaper/Legion × восемь направлений) против исходных кандидатных PNG.
- PR #376 merged (`5a219a3c`); exact-head CI #41579876954 и post-merge Windows workflow #41580061364 SUCCESS; EXE опубликован в windows-preview.
- Следующий шаг: вручную проверить свежий LastRitual.exe из `windows-preview`; художественное одобрение уже получено, теперь нужен gameplay QA.

## Production-интеграция Алтаря душ — 03.11.2026

- Шесть production PNG созданы как байт-в-байт копии утверждённых файлов из `candidate/`; все шесть SHA совпадают.
- Временный workflow копирования удалён после успешного выполнения; production assets и candidate archive сохранены отдельно.
- Root manifest включает runtime только при полном наборе слоёв и проверенных существующих VFX.
- Обновлены Godot smoke tests и Python promotion gate: теперь они ожидают production-ready manifest и подтверждают, что candidate archive остаётся выключенным.
- PR #376 merged, post-merge Windows build #41580061364 SUCCESS. Следующий ИИ: помочь владельцу выполнить ручной QA EXE; legacy fallback не удалять до успешного прохождения.
