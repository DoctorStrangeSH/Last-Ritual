# Pixel Art Handoff — Last Ritual

Снимок: 03.11.2026. Это текущая инструкция, не журнал всех исторических PR. Решения и история — в docs/DECISIONS.md и GitHub PR.

## Подтверждённое направление владельца

- Вся игра переходит на единый детальный тёмно-фэнтезийный Pixel Art.
- Готическая архитектура, камень, состаренное золото, кость, магические кристаллы, выразительные силуэты.
- Алтарь душ — эталон качества для будущей миграции остальных башен.
- У Алтаря душ основание неподвижно; вращается только оружие.
- Прогрессия: основание L1→L2→L3, затем выбор Жнец (siege) или Легион (swarm).
- Нужны восемь вручную нарисованных направлений, не вращение всей башни.
- Весь игровой UI и текст — на русском.

## Источники и правила

- Стиль: docs/art/PIXEL_ART_STYLE_GUIDE.md и docs/art/STYLE_BIBLE.md.
- Инвентарь: docs/art/PIXEL_ART_MIGRATION_INVENTORY.md.
- Approved original/provenance: assets/spire/towers/necro/source/ и assets/spire/towers/necro/approved_renders/.
- Воспроизводимый источник candidate-модулей: tools/generate_necro_modular_candidates.py.
- Candidate manifest: assets/spire/towers/necro/candidate/manifest.json.
- Candidate source notes: assets/spire/towers/necro/candidate/SOURCE.md.

Не выдумывать Aseprite-файлы. Candidate art создаётся кодом на Python/Pillow. Не менять производственные спрайты в candidate-only PR. Не удалять оригиналы и лицензии.

## Текущее состояние Алтаря душ

| Часть | Состояние |
|---|---|
| Основания L1–L3 | Владелец одобрил; production PNG созданы, 128×128 RGBA |
| Base weapon | Владелец одобрил; production atlas 8×128×128 создан |
| Reaper weapon | Владелец одобрил; production atlas 8×128×128 создан; runtime branch `siege` |
| Legion weapon | Владелец одобрил; production atlas 8×128×128 создан; runtime branch `swarm` |
| Projectile/impact | 6 candidate атласов, по 8 кадров для base/Reaper/Legion |
| Preview | 72 композиции, контактные листы 1× и 2×, отдельный Windows EXE |
| Production | Модульный renderer включён в main; post-merge Windows Preview #41580061364 SUCCESS; legacy fallback сохранён; ручной QA pending |

Последняя арт-итерация: PR #357 merged (base weapon v4), squash main `b4e3c128a4ba6fb86d294a2aff37c71b37a39d68`. Проблема повреждённого PNG решена регенерацией из исходника; временный workflow удалён. Exact-head CI #41476104817 SUCCESS. Предыдущая уборка PR #358 merged, main CI #41474757990 SUCCESS.

## Ледяной обелиск — следующий арт-кандидат

- PR #378 merged (`00c122a0`); exact-head CI #41583127652 and post-merge Windows Preview #41583281398 SUCCESS.
- Root manifest: `assets/spire/towers/frost/manifest.json`; `status=review_candidate`, `runtime_enabled=false`. Не включать до явного одобрения владельца.
- 3 основания: `candidate/base/level_1..3.png`, 128×128 RGBA.
- Оружие: `candidate/weapon/base/weapon_8way.png`, `frost_lance/weapon_8way.png`, `blizzard/weapon_8way.png`; каждый атлас 8×128×128, порядок N, NE, E, SE, S, SW, W, NW.
- VFX: по 8 кадров projectile (32×32) и impact (64×64) для base/Frost Lance/Blizzard.
- Mapping: `siege → frost_lance` («МОРОЗ: СИЛЬНЕЕ»), `swarm → blizzard` («МЕТЕЛЬ: БЫСТРЕЕ»). Игровые ID остаются `frost`, специализации — `siege`/`swarm`.
- Reproducible source: `tools/generate_frost_modular_candidates.py`; renderer: `tools/render_frost_modular_preview.py`; candidate source notes: `assets/spire/towers/frost/candidate/SOURCE.md`.
- Review sheets: `candidate/review/contact_sheet_9_1x.png`, `contact_sheet_72_1x.png`, `contact_sheet_72_2x.png`; also published as `frost_obelisk_9_compositions_1x.png`, `frost_obelisk_modular_contact_sheet_1x.png` and `frost_obelisk_modular_contact_sheet.png` in the `windows-preview` release.
- Existing `experimental/` Frost art and `vfx/` remain untouched. `FROST_EXPERIMENTAL_ART=true` still selects the existing experimental set; the new modular candidate is not used by the live game.
- Shared manifest contract supports per-tower `specialization_branches`; legacy Soul Altar defaults remain `siege → reaper`, `swarm → legion`.
- TD renderer now positions base via `ground_anchor` and weapon via its manifest `pivot`; the review composition uses the same alignment rule.
- No Aseprite project or SVG source is claimed. The procedural Python generator is the editable source.

## Костяная баллиста — следующий модульный арт-кандидат

- PR #380 merged (`5f34cc1c`); exact-head CI #41585101342 and post-merge Windows Preview #41585253951 SUCCESS.
- Root manifest: `assets/spire/towers/ballista/manifest.json`; `status=review_candidate`, `runtime_enabled=false`.
- Gameplay ID остаётся `bone`; asset folder ID — `ballista`. Не переименовывать сохранения и не менять баланс.
- 3 основания: `candidate/base/level_1..3.png`, 128×128 RGBA.
- Оружие: `candidate/weapon/base/weapon_8way.png`, `siege_bolt/weapon_8way.png`, `bone_volley/weapon_8way.png`; каждый атлас 8×128×128, порядок N, NE, E, SE, S, SW, W, NW.
- Mapping: `siege → siege_bolt` (тяжёлый одиночный болт), `swarm → bone_volley` (три быстрых болта). Это сохраняет текущие специализации; никаких combat values не менялось.
- VFX: по 8 кадров projectile (32×32) и impact (64×64) для base/siege_bolt/bone_volley.
- Source: `tools/generate_ballista_modular_candidates.py`; renderer: `tools/render_ballista_modular_preview.py`; tests: `tests/test_ballista_modular_candidates.py`.
- Contact sheets: `candidate/review/contact_sheet_9_1x.png`, `contact_sheet_72_1x.png`, `contact_sheet_72_2x.png`; also published in `windows-preview` as `ballista_9_compositions_1x.png`, `ballista_modular_contact_sheet_1x.png`, `ballista_modular_contact_sheet.png`.
- Existing Foozle base/weapon/projectile/impact files remain untouched. No runtime promotion until explicit owner approval and a separate integration PR.
- No Aseprite project is claimed; the procedural Python generator is the editable reproducible source.

## Огненная турель — текущий модульный арт-кандидат

- PR #382 merged; exact-head CI #41589195484 and post-merge Windows Preview #41589363962 SUCCESS.
- Root manifest: assets/spire/towers/fire/manifest.json; status=review_candidate, runtime_enabled=false.
- Gameplay ID remains fire. Existing labels: ИНФЕРНО: ПЛАМЯ (siege), ИСКРЫ: 3 ЦЕЛИ (swarm); branch mapping: siege → inferno, swarm → sparks.
- 3 bases: candidate/base/level_1..3.png, 128×128 RGBA.
- Weapon: candidate/weapon/base/weapon_8way.png, inferno/weapon_8way.png, sparks/weapon_8way.png; each atlas is 8×128×128, N, NE, E, SE, S, SW, W, NW.
- VFX: 8-frame projectile (32×32) and impact (64×64) strips for base/inferno/sparks.
- Source: tools/generate_fire_turret_modular_candidates.py; renderer: tools/render_fire_turret_modular_preview.py; tests: tests/test_fire_turret_modular_candidates.py.
- Contact sheets: candidate/review/contact_sheet_9_1x.png, contact_sheet_72_1x.png, contact_sheet_72_2x.png; also published in windows-preview as fire_turret_9_compositions_1x.png, fire_turret_modular_contact_sheet_1x.png and fire_turret_modular_contact_sheet.png.
- Original Foozle base/weapon/projectiles/weapon_impact resources remain untouched; no runtime promotion until explicit approval and a separate integration PR.
- No Aseprite project is claimed; the procedural Python generator is the reproducible editable source.

## Враги осады и Страж ритуала — review candidate

- PR #384 merged (`35e719e4`); exact-head CI #41605666907 and post-merge Windows Preview #41605855395 SUCCESS.
- Root manifest: `assets/enemies/manifest.json`; `status=review_candidate`, `runtime_enabled=false`.
- Six roles: `runner`, `brute`, `captain`, `healer`, `ranged`, `boss`.
- Every role has 8 distinct facing directions × 4 distinct walk frames at 8 FPS. Normal roles use 48×48 cells; Ritual Guardian uses 96×96.
- Atlas layout: 4 columns (walk frames) × 8 rows (N, NE, E, SE, S, SW, W, NW).
- TD mapping: runner/brute/captain/healer/boss. Night mapping: regular/flanker → runner, ranged → ranged, champion → brute, boss → boss. The current runtime remains the existing vector enemy renderer.
- Reproducible source: `tools/generate_enemy_roster_pixel_art.py`; preview: `tools/render_enemy_roster_preview.py`; tests: `tests/test_enemy_roster_pixel_art.py`.
- Review sheets: `candidate/review/enemy_roster_8way_1x.png`, `enemy_walk_cycles_1x.png`, and matching `_2x.png` sheets; all four are published in `windows-preview`.
- Boss duplicate-frame bug fixed by adding a four-pose mantle/core animation. Boss size/pivot fit was corrected so no atlas-cell corner is touched. CI test asserts all 4 frames differ for all 8 directions and all cells remain transparent at corners.
- Generation workflow #41605211560 passed all five Python tests and committed the reproducible candidate. The temporary write-enabled workflow is removed before PR.
- No runtime promotion, no stats/hitbox/movement/attack/wave/save changes. Owner visual approval at 1× and a separate runtime PR are required.

## Следующий порядок работ

1. [x] Владелец одобрил Алтарь душ L1–L3 и base/Reaper/Legion 03.11.2026.
2. [x] Алтарь душ интегрирован в main через PR #376; exact-head CI #41579876954 и post-merge Windows workflow #41580061364 SUCCESS.
3. [x] Candidate archive Алтаря душ сохранён; candidate VFX не продвигались; legacy fallback оставлен.
4. [x] Frost candidate PR #378 merged; exact-head and post-merge Windows checks SUCCESS; runtime remains disabled.
5. [x] Подготовлен Frost Obelisk modular candidate pack: 3 основания, 3 восьминаправленных оружия, 6 VFX strips и review sheets.
6. [x] Manifest contract расширен per-tower specialization branches; TD renderer позиционирует weapon по pivot отдельно от base ground anchor.
7. [x] Добавлены Python/Godot тесты для Frost manifest, восьми направлений, VFX, воспроизводимости и pivot alignment.
8. [ ] Получить визуальное одобрение Frost, Ballista, Fire и enemy roster candidate на 1×.
9. [ ] Только после одобрения — отдельный runtime PR для каждой башни и Windows QA; сохранить текущие fallback assets до проверки.
10. [ ] Протестировать Алтарь душ в свежем Windows EXE: L1/L2/L3, base/Reaper/Legion, восемь направлений, projectile/impact, save/load.
11. [ ] Не удалять legacy sprites до отдельного PR с поиском ссылок и успешного ручного QA.

## Production gate — завершён

В main все шесть обязательных файлов присутствуют:
- `assets/spire/towers/necro/base/level_1.png`
- `assets/spire/towers/necro/base/level_2.png`
- `assets/spire/towers/necro/base/level_3.png`
- `assets/spire/towers/necro/weapon/base/weapon_8way.png`
- `assets/spire/towers/necro/weapon/reaper/weapon_8way.png`
- `assets/spire/towers/necro/weapon/legion/weapon_8way.png`

Root manifest: `status=owner_approved_production`, `runtime_enabled=true`. Candidate manifest: `status=approved_source_archive`, `runtime_enabled=false`. Candidate PNGs remain preserved. Production reuses the existing six validated VFX strips; candidate VFX are not promoted. Aseprite project does not exist; do not fabricate one. The reproducible source is `tools/generate_necro_modular_candidates.py`.

PR #376 merged (`5a219a3c`); exact-head CI #41579876954 SUCCESS, post-merge main/Windows export #41580061364 SUCCESS. Свежий LastRitual.exe опубликован в windows-preview. Следующий шаг — ручной QA владельца; CI не заменяет игру.

## Контрольные листы и preview

Release: https://github.com/DoctorStrangeSH/Last-Ritual/releases/tag/windows-preview

- soul_altar_9_compositions_1x.png — компактное сравнение 9 сочетаний L1–L3 × base/Reaper/Legion (PR #369), удобно для ручной приёмки.
- soul_altar_modular_contact_sheet_1x.png — все 72 композиции в исходном размере.
- soul_altar_modular_contact_sheet.png — увеличенный 2× лист.
- LastRitual-ArtPreview.exe — изолированная сцена, не игровая сборка.

Motion Preview: 1/2/3 — уровень; B/R/L — ветка; NumPad — ручное направление; A — автонаведение; H — направляющие; F — выстрел; Z — масштаб 1×/2×/2.5×/4×.

## Важное для каждого art PR

- Один PR — один визуальный компонент.
- Сохранять generator и воспроизводимость.
- Проверять все 8 кадров, прозрачность, размеры, обрезку и отличия силуэтов.
- Не менять gameplay, damage, cooldown, economy, saves.
- После генерации смотреть git diff: generator может переписать все 12 PNG.
- Headless CI подтверждает техническую целостность, но не художественное качество.
- Владелец принимает art в Windows на 1× до переключения runtime.

## Поле боя крепости — в игре

- Root manifest: `assets/battlefield/manifest.json`; `status=owner_approved_production`, `runtime_enabled=true` (одобрено 04.11.2026). Файлы остаются в `candidate/`, куда пишет генератор.
- Спрайты (`assets/battlefield/candidate/`): земля 256×256 (бесшовная плитка), дорога 64×64 (брусчатка, UV по мировым координатам), площадки пустая/занятая 64×64, ритуальный алтарь 128×128, ворота 48×64, стена 48×66, 8 декораций 32×32 (черепа, надгробия, свечи, кости, камни, жаровня).
- Source: `tools/generate_battlefield_pixel_art.py` (`--verify`); тесты: `tests/test_battlefield_pixel_art.py`, Godot `tests/td_battlefield_art_smoke.gd`.
- Рендер: `scripts/td/td_battlefield_art.gd` + ветки `draw_pixel_battlefield_*` в `scripts/topdown_td_prototype.gd`; при выключенном manifest рисуется прежний процедурный фон. Декорации раскладываются по seed вне дорог и площадок.
- Скриншоты до/после: `candidate/review/td_{before,after}_{prep,wave}.png`; снимать `tools/capture_td_screenshot.gd` (нужен xvfb + opengl3, не headless).
- Любая перерисовка — снова кандидат: новые PNG показать владельцу до слияния.

## Иконки трофеев ночи — в игре

- `assets/trophies/trophy_icons_8x24.png`: 8 иконок 24×24 в порядке `scripts/run_trophies.gd` ORDER (череп с короной, могильный фонарь, сума, камень с руной-оберегом, пепел феникса, фонарь душ, проклятый идол, кровавый жернов). Палитра — общая с полем боя, обводка ink.
- Source: `tools/generate_trophy_icons.py` (`--verify`); тест `tests/test_trophy_icons.py` (воспроизводимость, порядок = каталог, прозрачные углы, обводка).
- Используются днём (верхняя панель, 1×) и ночью (карточки, 2×, nearest). Ночная сцена держит текстуру константой `TROPHY_ICONS`: текстура, загруженная только внутри `_draw()`, освобождается до отрисовки и выглядит белым квадратом.
- Скриншоты: `tools/capture_night_trophies.gd`, `tools/capture_td_screenshot.gd --trophies=...` (xvfb + opengl3).

## Торговец тьмы (ночь) — в игре

- `assets/night/dark_merchant_48.png` 48×48: фигура в фиолетовом капюшоне с золотой каймой, горящие глаза, посох с фонарём душ, мешок и череп на поясе. Рисуется 2× (nearest) в окне торговца.
- Source: `tools/generate_night_merchant.py` (`--verify`), тест `tests/test_night_merchant.py`. Скриншот: `tools/capture_night_trophies.gd --room=merchant`.

## События ночи — в игре

- `assets/night/event_icons_4x48.png`: 4 иллюстрации 48×48 (алтарь с фиолетовым пламенем и свечами, могила с черепом и лопатой, кровавый фонтан, золотое зеркало с тенью), рисуются 2× в окне события.
- Source: `tools/generate_night_events.py` (`--verify`), тест `tests/test_night_events_art.py`. Скриншот: `tools/capture_night_trophies.gd --room=event --event=...`.
- Правило стиля: без религиозных символов (крестов) — черепа, руны, пламя.

