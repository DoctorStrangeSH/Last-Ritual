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

## Следующий порядок работ

1. [x] Владелец одобрил Алтарь душ L1–L3 и base/Reaper/Legion 03.11.2026.
2. [x] Алтарь душ интегрирован в main через PR #376; exact-head CI #41579876954 и post-merge Windows workflow #41580061364 SUCCESS.
3. [x] Candidate archive Алтаря душ сохранён; candidate VFX не продвигались; legacy fallback оставлен.
4. [x] Frost candidate PR #378 merged; exact-head and post-merge Windows checks SUCCESS; runtime remains disabled.
5. [x] Подготовлен Frost Obelisk modular candidate pack: 3 основания, 3 восьминаправленных оружия, 6 VFX strips и review sheets.
6. [x] Manifest contract расширен per-tower specialization branches; TD renderer позиционирует weapon по pivot отдельно от base ground anchor.
7. [x] Добавлены Python/Godot тесты для Frost manifest, восьми направлений, VFX, воспроизводимости и pivot alignment.
8. [ ] Получить визуальное одобрение Frost и Ballista candidate на 1×.
9. [ ] Только после одобрения — отдельный Frost runtime PR и Windows QA; сохранить текущий experimental fallback до проверки.
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
