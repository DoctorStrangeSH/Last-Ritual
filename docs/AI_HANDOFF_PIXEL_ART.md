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

## Следующий порядок работ

1. [x] Владелец одобрил L1–L3 и base/Reaper/Legion 03.11.2026.
2. [x] Скопировать шесть одобренных base/weapon PNG в production paths, сохранить source archive и подтвердить идентичность SHA.
3. [x] Включить root manifest в main; candidate manifest оставить disabled.
4. [x] Переиспользовать шесть существующих production VFX strips; candidate VFX не включать.
5. [x] Обновить Godot smoke tests и Python promotion gate для runtime-enabled production kit.
6. [x] PR #376 merged; exact-head CI #41579876954 и post-merge Windows workflow #41580061364 SUCCESS; EXE опубликован.
7. [ ] Протестировать Windows EXE: L1/L2/L3, base/Reaper/Legion, восемь направлений, projectile/impact, save/load.
8. [ ] Не удалять legacy sprites до отдельного PR с поиском всех ссылок и подтверждённого QA.

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
