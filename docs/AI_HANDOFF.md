> **2026-10-31 PR #270:** Connect original six-tower SVG specialization art to existing four gameplay ID slots via `scripts/td/td_specialization_icons.gd` mapping `bone→ballista`, `fire→fire`, `necro→pulse`, `frost→spark`. The selection modal and placed towers show corresponding 64×64 icon and badge. Existing stats/saves are unchanged. Tests load all eight active SVG icons. Remaining two tower IDs, distinct specialty weapon overlays and manual Windows preview are pending.

> **2026-10-31 SOURCE ART IMPORT:** `tools/import_source_art.py` restores four original PNG concepts unchanged from the Library ZIP using SHA256/size/ZIP CRC/signature verification; `tests/test_source_art_import.py` runs in CI. Originals are currently **not committed in git**; restore from Library `/Last Ritual/Art Sources/LastRitual_Art_Source_2026-10-31.zip` (or user download), then add `docs/art/source/concepts/*.png` in a dedicated PR. Do not substitute resized copies or pretend the manifest is a binary upload.

> **2026-10-31 source-art archive:** Four original approved large PNG concepts were preserved byte-for-byte in `LastRitual_Art_Source_2026-10-31.zip` under personal Library `/Last Ritual/Art Sources/` (libfile_93652e51e27c819189ea8175f359ae85). See `docs/art/source/README.md` and `docs/art/source/manifests/source_art_manifest.json` for exact sha256, filenames and restore steps. Large PNG binary files ARE NOT yet in git; do not claim they are. Owner also has downloadable ZIP via chat. 12 specialty icon SVGs remain committed in GitHub.

> **31.10.2026 ART STANDARD:** The user approved a cohesive dark-fantasy pixel-art concept for six towers. Mandatory art handoff documents now live under `docs/art/`: STYLE_BIBLE.md, ASSET_SPEC.md, PROMPT_LIBRARY.md, SIX_TOWER_VISUAL_IDENTITY.md. Use the 12 actual icon.svg files in `assets/spire/towers/{ballista,fire,spark,pulse,necro,frost}/specializations/{siege,swarm}/` as reproducible local references. Large concept-board PNGs are from chat but NOT yet committed to repo; do not misrepresent them as production-ready sprites. Four gameplay IDs remain; six-tower expansion is pending. No gameplay/visual engine code changed by this documentation-only PR.

> **31.10.2026 fire splash stage:** Added `scripts/td/td_fire_splash.gd`; fire now uses up to two extra nearby targets within 32px of main target after existing TD_MULTIHIT selection. Existing cooldown, damage, burn, saving and type ID stay intact; UI display name temporarily stays «ОГНЕННАЯ» due to shop-card hover regression; rename together with card layout later. Check exact-head CI and manual Windows balance. Six-tower roster remains pending; no migration performed.

> **31.10.2026 — PR #263 (visual-only):** Godot existing gameplay IDs remain `bone/fire/necro/frost` for save compatibility. Layered renderer maps them to original Foozle folders `ballista/fire/pulse/spark`; selects base and weapon per upgrade level 1–3; shows static pose (first sprite sheet cell) instead of endless atlas cycling. Original sources are preserved in assets/spire/towers. Projectile/impact are not wired yet. New necro/frost additions remain pending; old IDs are not renamed in runtime. Exact-head CI and Windows playtest needed before claiming success.

## 31.10.2026 — audit of user-uploaded tower PNGs

Four original uploaded Foozle tower sets in PR #262 inspected by their actual sprite sheets:
- original `bone` → `ballista`, physical crossbow and arrows;
- original `fire` → `fire`, flame turret with fire shots (intended small-area fire);
- original `frost` → `spark`, electric emitter with green spark bullets (not ice);
- original `necro` → `pulse`, prism emitter with circular shockwave (not necromancy).
- new `necro` and `frost` are **additional** towers, currently blank upload slots pending integration of generated art.

PR #262 source tree temporarily lacked many tracked main files; it must be reconciled with current main before merging. Rebuilding its tree on main restores gameplay/docs while preserving all the uploaded PNG blobs. See `assets/spire/towers/README.md` for folder mapping and pending gameplay migration; never change save IDs without backwards compatibility.

> **31.10.2026 — asset licensing update:** PR #260 merged (`113d759`); exact-head PR CI and main CI succeeded. `docs/FREE_ASSET_CATALOG.md` is the current shortlist. Verified official sources: Kenney Tower Defense Top-Down / Roguelike Caves & Dungeons / Tiny Dungeon / Roguelike-RPG (CC0; RPG pack is 16x16 and 3/4 perspective), Screaming Brain Top Down Dungeon Pack (2,256 tiles, CC0) and Tiny Top Down Pack (100 32x32 tiles, CC0). These are candidates only; not imported. Preserve Foozle as primary tower visual style. Next: extract BuilderPack PNGs with their Readme/license, create Godot preview, verify frame order/FPS, then test dungeon packs in isolated preview before selecting. Main CI after #260 succeeded: 41200309274.\n\n> **31.10.2026 update:** PR #259 merged (`629f1f8`), exact-head CI success. It adds verified Foozle BuilderPack sheet geometry and contact-sheet generator; this does not yet import original animation PNGs or confirm frame order/FPS. `docs/FREE_ASSET_CATALOG.md` lists vetted external asset candidates and licensing rules (Kenney CC0, Screaming Brain CC0, LPC CC-BY-SA/GPL). Next: check main CI run 41200095541, then preview original Foozle animation sheets in Godot and selectively add external assets with source/license files. Never claim manual QA without running the game.

> **Текущий статус 31.10.2026:** PR #253 и #254 объединены; #254 merge commit `aed18a2`. Main CI после #253 success; после #254 запущен новый workflow. Процедурные эффекты строительства/продажи (0,42 с) есть в main. Это НЕ оригинальные покадровые BuilderPack-анимации. #217 остаётся открытым, конфликтует с main и требует переноса; не мержить как есть. Ручная Windows QA не подтверждена. Следующие задачи: проверить main CI после #254, затем реализовать оригинальные BuilderPack construction/collapse и подключить наземных/летающих врагов с лицензиями.

> **31.10.2026 — #254 актуализация:** PR переведён на main после merge #253. Атлас и лицензия остаются из main; в #254 переносится только визуальный эффект покупки/продажи (0,42 с). Оригинальные BuilderPack PNG пока не подключены. Exact-head CI и Windows QA обязательны.

> **Текущая ревизия 31.10.2026:** #251, #252, #255 merged; main CI 41193468399 success. #253 blocked by corrupt tower PNG (CI 41194045372 failure); #254 зависит от #253; #217 требует оценки. Подробности в `docs/REPOSITORY_HYGIENE.md`.

> **31.10.2026, #251:** #250 merged 7040893. Тестовый PR на урон попадания (4 школы × 3 уровня × 3 специализации), стоимость и аффинитеты. Не путать с реальным DPS; ночь не менять, merge после exact-head CI.

> **31.10.2026 — PR #252:** CI cost reduction: PR = headless Godot editor import + smoke; main/manual = checks then Windows export & rolling release. Editor/templates cached, Actions artifacts removed, cancel stale workflows. GitHub budget $0 blocks execution; do not merge without green exact-head CI after unblocking. PR #251 still open. No gameplay changes.

> **31.10.2026, #250:** #249 merged 1ff5f31. Новый тестовый PR на сохранение идентичности школ fire/frost/bone/necro; CI обязателен, ночь не менять; баланс требует ручного Windows-плейтеста.

> **31.10.2026, #249:** #248 merged d3b4f98 после CI success. Тестовый PR: стоимость постройки/улучшений каждого типа башни + прогноз максимального дохода всех 5 дней × 6 волн. Ночь не менять, merge только после exact-head CI.

> **31.10.2026, #248:** #247 merged e062691 после CI success. Test-only PR на все 5 дней × 6 волн: бюджет/роли/численность, дорожная карта обновлена. Ночь не менять, merge после exact-head CI.

> **31.10.2026, #247:** #246 merged 81c1780. Next PR adds contextual one-line tip to forecast (boss/captain/armor/runner/healer priority), smoke tests; no night changes. Merge only on exact-head green CI.

> **31.10.2026, #246:** #245 merged e327611 после CI success. Следующий PR показывает разведку следующей волны (brute/runner/support/captain/boss), вычисляемую из существующих функций. Ночь без изменений; merge после exact-head CI.

> **31.10.2026, #245:** #244 merged fa9997f. Новый небольшой этап: капитан 4–5 дня на маршруте первого лекаря (если есть), чтобы аура и лечение создавали тактическую цель. Проверить exact-head CI и баланс, ночь не трогать.

> **31.10.2026, #244:** #243 merged f8142fb. Командир уже имеет ауру +20% скорости союзникам в радиусе 130; PR #244 показывает тонкий круг влияния только у активных командиров, справку. Нет изменения баланса и ночи; CI обязателен.

> **31.10.2026, #243:** #242 merged a1fda93. Следующий PR: щит над late-day brute и краткая справка о контрмере огнём. Урон и ночь не меняются; не merge без CI.

> **31.10.2026, #242:** #241 merged ee2f8df. Следующий PR: поздние brute получают -1 входящий неогненный урон башни, огонь игнорирует броню, минимальный урон 1. Smoke и ручной баланс. Ночь не менять.

> **31.10.2026, #241:** #240 merged 1a4b5a9 после CI. PR #241: синергия двух даров — термальный удар +1 splash только по охлаждённым, если оба дара накоплены за забег; smoke-тест. Никаких изменений ночи, merge только после exact-head CI.

> **31.10.2026, #240:** #239 merged ca8dbb0. Следующий этап — три из четырёх случайных реально доступных наград на Военном совете, новый Blood Pact (-15 HP, +1 tower damage), smoke, старые сейвы. До CI не мержить.

> **31.10.2026, #239:** #238 merged 2bae264. Новый дар Eternal Frost активируется через repair Военного совета, не заменяет +20 HP, +1 по chilled; тесты сейва/урона. До exact-head CI и Windows QA не считать завершённым.

> **31.10.2026, #238:** #237 merged f9823ec после CI success. Военный совет предлагает 3 работающих выбора в разном seeded-порядке; непроверенные catalog-only боевые дары не активируем. Тесты seed/уникальности/совпадения клика с отрисовкой. Windows QA нужен.

> **31.10.2026, #237:** #236 merged 65b1f39 после CI success. В работе VFX огненного кольца (лимит 12, автоочистка, smoke-тест). Ночь не менять, визуальный Windows QA не подтверждён.

> **31.10.2026:** #235 merged 7954700, #236 в работе: «Пепельное сердце» открывается через «Обоз» Военного совета, без новых модальных окон; тесты AOE, экономики, переноса состояния. Не сливать без exact-head success; ночную фазу не менять.

> **31.10.2026, #235:** #234 merged 076f8e5. Подключаем первый экономический дар в текущем Военном совете с тестами, не заявляя, что случайные дары уже активны. Дальше боевые реликвии, UI и ручной плейтест пяти дней; ночь не менять.

> **31.10.2026, #234:** #233 merged после CI 36427ad. Начат каталог 6 Даров Бездны без применения эффектов: чистое детерминированное API, чтобы будущий этап мог аккуратно интегрироваться в существующий Военный совет. Проверить CI, далее постепенно подключать эффекты с сохранением совместимости.

> **31.10.2026, #233:** #232 успешно merged 97f64ab. Следующий баг: магазин последней башни пересекается с «Улучшить/Продать», hitbox конфликты; вынести действия выше магазина, smoke test. До CI и ручного Windows QA не считать завершённым.

> **31.10.2026:** #231 merged 93be61c после exact-head CI success; postmerge run 41168891585 ожидается. В работе #232: сброс hover на выходе курсора за окно и smoke-тесты. Ручной Windows QA не подтверждён.

> **31.10.2026, #231:** продолжаем приоритет дневной TD: компактная карточка hover, границы HUD/магазина, проверка ухода курсора. PR ожидает exact-head CI и Windows QA; далее новые роли врагов и баланс 5 дней. #217 устарел и не готов к слиянию.

> **ЭТАП #230 (31.10.2026):** #229 CI success и merged (7fa8ed8) — сбалансированное псевдослучайное распределение обычных врагов по 2/3 маршрутам. В работе #230: UI-тексты и визуальные связи ледяных синергий, боевые smoke-тесты всех шести прямых пар и совпадение damage инспектора с реальным расчётом. QA/CI ожидается; важнейшие следующие задачи — новые роли врагов, графика, Windows playtest всех пяти дней. Не объявлять игру «идеальной» без playtest.

> **ЭТАП 229 — 31.10.2026:** #228 exact-head CI success и squash merged в main 8f34d7a. Каталог теперь 8 вариантов (6×2, 2×3 дороги), геометрические тесты. В работе #229 — seeded случайность распределения обычных врагов по маршрутам без перекоса одной линии; результаты только после CI. После — аудит баланса/синергий, новые роли и визуальный Windows QA. Ночь потом.

> **ТЕКУЩИЙ ЭТАП 31.10.2026:** #226 и #227 объединены после exact-head CI; main c90dbabb39b8557bfd1316bb2216cafa74d59db9 (postmerge CI success). #227 — пятидневная кампания 10 фаз, дни 4–5 с отдельными угрозами; пока без ручного баланс QA. Следующий PR #228 расширяет дороги с 3 до 8 схем (включая три линии на части карт) и проверяет безопасные дистанции; CI ещё необходим. После маршрутов — синергии/визуальная полировка, ночь позже.

> **ПРОДОЛЖЕНИЕ РАБОТ — 31.10.2026:** #226 (hover-интерфейс) прошёл exact-head CI и объединён в main 1fe983bf; ручной визуальный QA ещё открыт. Текущий PR #227 (после #226) — реальная пятидневная кампания, 10 фаз и особые составы осад 4–5, с полным smoke-прогоном. Следом разнообразие маршрутов, аудит синергий/баланса, визуальная графика. Не выдавать ручной плейтест за факт.

> **ТЕКУЩИЙ ПРИОРИТЕТ (31.10.2026):** владелец просит сначала полностью отполировать 5 дневных TD-осад, затем ночь. Первый баг — постоянная большая карточка башни поверх дороги (требуется hover-only, правильный порядок отрисовки и ограничения геометрии). Фактический `main` на старте аудита a16124f8 (PR #225 merged, post-merge CI success); открытый старый PR #217 не объединять без перепроверки. Обнаружено: `run_loop.gd` заканчивает игру на 6 фазах (вместо целевых 10), `siege_day` ограничен 3, а `td_path_layouts.gd` содержит 3 карты по 2 линии. Задачи и критерии см. в начале ROADMAP. Старый текст ниже — архив.

> **СНАЧАЛА ЧИТАЙ ЭТО (29.10.2026):** старые записи ниже относятся к удалённому платформеру и историческим PR. Текущая игра — Godot 4.4.1 top-down TD + ночные комнаты. `main` на PR #101 merge b1dbed0e6fc46148605ea292e951feeb38d7f8d2, post-merge CI 40912423173 success. Текущая приоритетная задача **G1 — настоящие извилистые пути TD**; далее G2–G8 по [GAMEPLAY_OVERHAUL.md](GAMEPLAY_OVERHAUL.md) и [ROADMAP.md](ROADMAP.md). Сохранять текущие save schema и tests/topdown_smoke.gd. **Не считать написанный дизайн реализованной функцией**; проверять CI актуального HEAD и ручной QA отдельно. Не продолжать RC/S0 и не возвращать scripts/main.gd.

---

# AI Handoff — Last Ritual

## Главная задача

Продолжать игру небольшими, проверяемыми этапами, не теряя контекст между ИИ-сессиями. Работай только в DoctorStrangeSH/Last-Ritual. Полные правила — в корневом AGENTS.md; порядок работ — в docs/ROADMAP.md.

## Как начать следующую сессию

1. Прочитай AGENTS.md, этот файл, docs/PROJECT_STATE.md и docs/ROADMAP.md.
2. Проверь актуальный main, открытые PR и последние workflow runs. Не полагайся только на статусы, записанные в документации.
3. Возьми первый незакрытый этап дорожной карты. Сначала устрани блокирующие ошибки/проверки; не добавляй новую механику, пока предыдущий этап не завершён.
4. Создай отдельную ветку, внеси минимальный набор изменений, добавь тесты и обнови документы.
5. Открой PR, дождись зелёного CI, проверь результат после merge. Не объявляй ручной игровой проход состоявшимся без реального подтверждения.

## Текущее состояние

- Игра: Godot 4, GDScript; основной игровой код пока находится в одном большом scripts/main.gd и рисует часть интерфейса через Node2D._draw().
- Цикл: пять дневных осад, пять ночных уровней, промежуточные алтари/награды, затем финальный 45-секундный штурм.
- В main реализованы меню, продолжение кампании, выбор сложности, достижения, постоянные улучшения/таланты, выбор даров, синергии, контрольные сохранения и настройки звука.
- RC67 добавил Проклятого громилу с предупреждаемым рывком.
- RC68 добавил Проклятого стрелка с фиолетовым предупреждением, зафиксированным прицелом и магическими снарядами. RC68 объединён в main после успешного PR CI.
- CI для PR RC68 и post-merge push workflow main прошли успешно ([run #40816997661](https://github.com/DoctorStrangeSH/Last-Ritual/actions/runs/40816997661)). Ручное прохождение и визуальная проверка в Godot не подтверждены.

## Проверка следующего шага
Игрок сообщил 2026-10-29, что прошёл игру до финала. Основной цикл отмечен пройденным в docs/QA_SMOKE_TEST.md; точная версия/ОС и отдельная проверка всего UI-чеклиста неизвестны. S0 закрыт по основному прохождению, но не заявлять, что проверены все визуальные сценарии.

## Текущий целевой review
PR #12 и #13 объединены после успешного CI: загрузчик кампании строго проверяет типы и диапазоны полей башен, бонусов и легендарного дара. Следующая задача PR #14 — строгая валидация постоянного прогресса (`ritual_legacy.json`) и регрессионные тесты. Тесты используют отдельный `user://meta_smoke_test.json`, а не пользовательское сохранение. Проверить CI и результат PR перед отметкой выполненным.

## Главные технические ограничения

- Основная сцена — scenes/main.tscn; игровой код — scripts/main.gd.
- Автотесты — tests/campaign_smoke.gd; CI определён в .github/workflows/windows-build.yml и использует Godot 4.4.1.
- Сохранение кампании происходит на безопасной фазе алтаря; не считать его сохранением в любой момент.
- Smoke-тест проверяет игровые состояния и регрессии, но не заменяет ручную проверку управления, графики, баланса и полного прохождения.
- Не выполнять большой перенос кода в отдельные сцены одним PR. Модульный рефакторинг должен сохранять поведение и иметь тесты до/после.

## Завершение каждого этапа

Обнови PROJECT_STATE.md фактами, ROADMAP.md — только доказанным статусом, и этот handoff — следующей задачей. Не копируй сюда полный changelog: Git история и DECISIONS.md сохраняют историю. В финале сообщи ссылку на PR, результат CI, известные ограничения и точный следующий этап.

## S1 — сброс временных боевых эффектов (PR, ожидает CI)
При переходе в следующую ночь очищаются attack/hurt cooldown, индикатор удара, cooldown и след рывка, cooldown и VFX рассекателя; временный усиленный удар выключен. Добавлен регрессионный smoke-test. PR #14 с валидацией постоянного прогресса прошёл CI и объединён. Полный визуальный QA остаётся открытым.

## S2 — карта зависимостей (PR)
После зелёного CI PR #15 объединён. Подготовлена карта `docs/S2_DEPENDENCY_MAP.md`: следующий узкий шаг — вынести чистые функции названий и описаний даров в `scripts/reward_catalog.gd`, сохранив совместимость интерфейса и добавив тесты. Документ S2 требует зелёного CI и merge.

## S2 — первый малый вынос (PR #17, CI ожидается)
Добавлен `scripts/reward_catalog.gd` с чистыми статическими функциями названий и описаний пяти даров. `main.gd` оставляет совместимые обёртки, тест сравнивает все пять записей и неизвестный ID. Баланс и сохранения не меняются. Проверить CI, затем merge.

## S2 — следующий независимый компонент (PR #18)
После зелёного CI объединён PR #17 с каталогом даров Бездны. В PR #18 выделен чистый `scripts/tower_description.gd` для описаний способностей трёх башен; `main.gd` сохраняет прежний API. Добавлены тесты текстов на уровнях 1 и 3. Не считать PR #18 завершённым до CI и merge.

## S2 — PR #19
PR #18 прошёл CI и объединён. PR #19 переносит чистый расчёт возврата маны за продажу башни в `scripts/tower_economy.gd`. Публичный `tower_sell_refund` остаётся обёрткой. Добавлены регрессионные тесты для bone/fire/necro. Проверить CI до merge.

## S3 — элитный страж (PR #20, ждёт CI)
S2: три малых модуля #17–#19 после успешного CI находятся в main. S3: начиная с третьей ночи добавлен необязательный элитный страж; у него телеграфируемый удар по кругу радиусом 100 px, windup 1.0 с, cooldown 3.1 с, награда +45 маны/+5 душ только один раз. Страж не нужен для выхода с камнем. Smoke tests проверяют появление, телеграф, уклонение и однократность награды. Объединить только при зелёном CI.

## S4 — PR #21, ожидает CI
PR #20 прошёл CI и merged. Первый вертикальный срез реликвий: после убийства необязательного элитного стража выдаётся «Пепельный шаг» (cooldown рывка 1.25 вместо 2.5 с, только в текущем забеге). Поле `shadow_relic` — необязательный bool в старом формате checkpoint version=1; старые сохранения по умолчанию false. Поле строго проверяется при загрузке. Есть тесты получения, сброса, cooldown и сохранения. Проверить CI перед merge. Не объявлять ручную проверку выполненной.

## S4 — PR #22, ожидает CI
PR #21 прошёл CI и merged. В PR #22 добавлен «Кровавый покров», награда второго необязательного элитного боя после «Пепельного шага» начиная с ночи 4. За убийства обычных ночных врагов возвращает 6 HP (не более 100), один раз за врага; элиты не лечат. Поле `blood_mantle` — необязательный boolean в version=1 checkpoint, валидируется до сброса состояния. Есть smoke-тесты. Проверить CI и merge.

## S4 — PR #23, выбор реликвии
PR #22 merged после зелёного повторного CI. PR #23: элитный страж теперь показывает два варианта реликвии в компактном оверлее, выбор только кликом ЛКМ; симуляция не идёт до выбора. Полученную реликвию нельзя выбрать повторно. Тесты предыдущих PR обновлены на явный выбор, новые smoke assertions проверяют запрет дубликатов и сброс. Проверить Godot CI перед merge и не считать визуальный QA подтверждённым.

## S4 — PR #25, третья реликвия
PR #24 с защитой модального выбора прошёл CI и merged. PR #25 добавляет «Осколок ярости» (+25% урона ударов героя) в список из трёх кликабельных реликвий. Новое необязательное bool-поле `rage_shard` в checkpoint сохраняет обратную совместимость; проверяется до изменения состояния. Тесты сравнивают 24 и 30 урона базового удара, выбор и сброс. Проверить CI, затем merge; визуальный ручной QA ещё не выполнен.

## S5 — PR #26, точное предупреждение атаки хранителя
PR #25 прошёл повторный CI после исправления неверного присваивания Array в Array[Dictionary], merged. PR #26: у хранителя прямоугольный телеграф 174x100 px вместо круга, таймер до удара и единая функция `boss_strike_hits` для реального попадания. Тесты границ. Дождаться CI, затем merge, визуальный QA вручную отдельно.

## S5 — PR #27 (CI ожидается)
PR #26 прошёл CI и merged, прямоугольный телеграф босса теперь в main. PR #27 добавляет регрессионные тесты boss windup hit/dodge и одноразового получения Камня Бездны. Геймплей не менялся. Дождаться зелёного CI перед merge; ручная проверка карт не выполнена.

## S5 — PR #28: широкая волна поздних боссов
PR #27 CI green merged. Ночи 4–5: хранитель атакует расширенной зоной 260×100 px с телеграфом 1.1 с, на ночах 1–3 сохранена атака 174×100 px и 0.75 с. Геометрия, тайминг и видимый прямоугольник берутся из общих методов. Smoke tests проверяют радиус/длительность/доступность уклонения. PR #28 ожидает CI; визуальная ручная проверка отдельно.

## S5 — PR #29, проверка геометрии всех ночей
PR #28 после зелёного CI merged. PR #29: smoke checks по всем ночам 1–5 и маршрутам 0–2: 4 платформы, границы сцены, позиция тайника, наличие ловушек. Никакого изменения игровой механики. CI и merge ожидаются. Тесты не доказывают ручную проходимость всех платформ — нужен отдельный QA.

## S5 — PR #30, все пять Камней Бездны
PR #29 успешно прошёл CI и merged. PR #30 проверяет сбор камня у всех пяти ночных Хранителей и отсутствие повторной выдачи при следующем update_night. Без изменений механики. Дождаться CI перед merge. Ручная проверка пяти ночей не выполнена.

## S5 — PR #31, ритм ловушек
PR #30 CI green merged. PR #31: ночи 4–5 — ускоренные напольные ловушки (цикл 2.7 с, предупреждение 1.2 с, опасность 1.8 с). Более ранние ночи сохраняют 3.1/1.4/2.1 с. Методы `trap_cycle_duration`, `trap_warning_start`, `trap_danger_start`, `trap_phase`, `trap_is_dangerous` используются для синхронизации UI и урона. Smoke tests добавлены, CI ожидается.

## S5 — PR #32, вариант элиты финальной гробницы
После зелёного CI PR #31 в main. PR #32 меняет опциональную элиту пятой ночи на 240 HP и первую задержку 1.5 с; ранние ночи неизменны, получение Камня не требует элиты. Тесты параметров ночей 4–5 добавлены. Дождаться CI перед merge; ручной QA сложности ещё не выполнен.

## S6 — PR #33: меньше текста на ночном HUD
PR #32 CI green merged. В PR #33 длинная строка управления ночью появляется только первые 8 с первой ночи; после камня и на последующих ночах скрыта. Всплывающие подсказки/пауза и само управление без изменений. Smoke tests добавлены. Дождаться CI до merge.

## S6 — PR #34: компактный ночной индикатор
PR #33 merged после зелёного CI. PR #34 уменьшает блок способности Теневой рассекатель до 156×27, оставляя ПКМ, готовность или таймер и тонкую полоску. Метод `cleave_charge_ratio` проверяется smoke-тестами. CI/merge и ручной UI QA пока не подтверждены.

## S6 — PR #35: индикатор низкого HP
PR #34 CI green merged. PR #35: предупреждение о здоровье <=25 HP перемещено из центра арены в компактный чип рядом с HUD; лечение H подсказано, остальная механика не менялась. Метод `night_low_hp_warning_visible` протестирован. Требуется зелёный CI перед merge и визуальный QA.

## S6 — PR #36: компактная верхняя панель
PR #35 CI green merged. PR #36: ночной HUD высотой 117 вместо 156, компактные индикаторы HP, маны, душ, камня и ловушек; низкий HP вынесен вправо. Геймплей не меняется. Smoke tests добавлены. Дождаться CI и проверить визуально на всех ночах.

## S6 — PR #37, hitbox карточек наград
PR #36 merged с зелёным CI. PR #37 обновляет выбор Даров Бездны мышью: `reward_card_at` возвращает 0–2 только внутри реально отображаемой карточки, -1 вне; подсветка hover. Есть smoke-тесты, дождаться CI, затем merge. Визуальный QA не выполнен.

## S6 — PR #38, башни и мышь
PR #37 CI green merged. PR #38: метод `tower_at_point(pos)` объединяет попадание клика и hover-подсветки башни, предотвращая несовпадение областей. Золотая рамка остаётся только у выбранной башни, ненавязчивая голубая появляется на hover при отсутствии режима строительства. Smoke tests добавлены. CI/merge и ручной UI QA ожидаются.

## S6 — PR #39, карточки выбора башен
PR #38 CI green merged. PR #39 добавляет hover-подсветку трём карточкам строительства. Метод `build_card_at` проверяется на попадание и промежутки; выбранная карточка остаётся выделенной. CI/merge и ручной UI QA ожидаются.

## S6 — PR #40: индикатор доступности улучшения
PR #39 green CI merged. PR #40 добавляет `selected_tower_can_upgrade()` и использует его для цветового состояния кнопки улучшения: доступно, нехватка маны, максимальный уровень. При hover активная кнопка подсвечивается. Smoke tests добавлены; дождаться CI перед merge.

## S6 — PR #41, продажа башен
PR #40 merged после зелёного CI. PR #41: `selected_tower_can_sell` определяет доступность продажи, кнопка подсвечивается при наведении только при валидном выборе. Smoke tests проверяют без выбора, выбранную башню и неверный индекс. Дождаться CI и вручную оценить UI перед выпуском.

## RC61 — выбор ночного маршрута мышкой
Перед началом каждой ночи появляется экран выбора пути: Тропа теней (+20 маны), Тропа охотника (-15% здоровья ночного босса) и Тропа реликвий (+2 души). Путь выбирается только один раз за ночь, затем меняет размещение платформ и тайника в рамках существующих трёх безопасных вариантов. Мир не начинает двигаться, пока игрок не выбрал карту. Прежние вариации маршрута и тайники сохранены. Smoke-тесты проверяют бонусы и запрет повторного выбора.

## Ночные знамения — очередной этап roguelite
Каждую ночь случайно выбирается знамение. «Тихая гробница» — обычный баланс; «Осквернённый зал» — +22% здоровья начальным врагам и дополнительная ловушка; «Сокровищница теней» — +10% HP начальным врагам, зато секретный тайник даёт +50 маны и +3 души вместо +25/+1. Знамение показывается на экране выбора маршрута; сам выбор маршрута, обязательный Камень Бездны и портал сохраняются. Изменения только в рамках ночи, отдельного формата сохранения не требуется. Smoke-тесты проверяют оба варианта.

## Optional blood shrine (new)
Night dungeon routes now feature a risk/reward blood shrine at x=530 near the ground. After choosing a route, walk within 85 pixels, then left-click the shrine: trade 25 HP for 55 mana and 2 souls. Requires more than 25 HP and can only be claimed once per night; it disappears after use or when the ritual stone is collected. An unobtrusive contextual mouse hint appears only when nearby. `tests/campaign_smoke.gd` covers activation, one-time reward and run reset. Old saves are unaffected.

## RC — Спектральный патруль в подземельях
На сложности 2–4 (либо начиная с третьей ночи) в подземельях появляется циклический призрачный патруль. Перед появлением справа виден короткий янтарный предупредительный круг; затем призрак пересекает арену справа налево, причиняя контактный урон герою. Есть безопасный интервал между проходами. Ловушка не закрывает экран и не требует дополнительных кнопок. Урон зависит от сложности; smoke-тесты проверяют опасный и безопасный интервалы и отключение на ранней обычной сложности. Существующие пути, тайники и сохранения не затронуты.

## Дополнение: «Лунное затмение»
Добавлено четвёртое случайное знамение ночного подземелья: Лунное затмение. Обычные ночные враги имеют +30% HP, хранитель получает +25% HP, а за возвращённый камень игрок получает дополнительные +35 маны и +2 души. Существующие маршруты, сундуки, реликвии и Алтарь крови сохранены. Тесты проверяют название знамения и усиление противников. Требуется проверить актуальный CI и баланс вручную.

## S6 — синхронизированный PR подсветки меню (29.10.2026)
Подсветка четырёх пунктов главного меню перенесена на актуальную ветку main с отдельными smoke-проверками попадания и промежутков. Оригинальный PR #42 устарел относительно main; до зелёного CI и объединения новую задачу не считать завершённой. Ручная визуальная проверка обязательна отдельно.
