# Pixel Art Handoff — Last Ritual

Снимок: 02.11.2026. Это текущая инструкция, не журнал всех исторических PR. Решения и история — в docs/DECISIONS.md и GitHub PR.

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
| Основания L1–L3 | Candidate v4 (PR #363 merged): шпили L1–L3, золотые скобы и укрупнённые фиолетовые руны; художественная оценка 1× ещё нужна |
| Base weapon | Candidate v4; гранёный фиолетовый кристалл и золочёная корона; 8 направлений, PR #357 merged, визуальная приёмка ожидается |
| Reaper weapon | Candidate v4; длинное древко и изогнутая фиолетовая коса, 8 направлений |
| Legion weapon | Candidate v5: три черепа с уменьшенным визуальным шумом (PR #365 merged), художественная приёмка 1× не проведена |
| Projectile/impact | 6 candidate атласов, по 8 кадров для base/Reaper/Legion |
| Preview | 72 композиции, контактные листы 1× и 2×, отдельный Windows EXE |
| Production | Модульный renderer выключен; текущая игра использует цельные спрайты и production fallback |

Последняя арт-итерация: PR #357 merged (base weapon v4), squash main `b4e3c128a4ba6fb86d294a2aff37c71b37a39d68`. Проблема повреждённого PNG решена регенерацией из исходника; временный workflow удалён. Exact-head CI #41476104817 SUCCESS. Предыдущая уборка PR #358 merged, main CI #41474757990 SUCCESS.

## Следующий порядок работ

1. [x] Base weapon v4: заменён «брусок» на кристаллическую призму/руническую корону, 8 уникальных силуэтов и технические проверки пройдены (PR #357). Художественная оценка 1× ещё не подтверждена.
2. [x] Основания L1–L3 candidate v3: добавлены более высокие силуэтные детали, PR #360 merged, exact-head CI #41477386582 SUCCESS. Ручная приёмка 1× всё ещё ожидается.
3. [x] Контраст золота и фиолетовых рун в основаниях обновлён в candidate (PR #363 merged, exact-head CI #41481076084 SUCCESS); следующий шаг — ручная оценка 1× и упрощение специализаций. Материальная палитра остальных башен не утверждена. 3–5 тонов на материал, тёмная обводка, контролируемые фиолетовые руны и светящиеся акценты.
4. Пересмотреть Reaper/Legion по читаемости на 1×; убрать шум и неясные детали.
5. Показать полный контактный лист и Art Preview владельцу. Зафиксировать feedback отдельно.
6. Только после художественной приёмки создать production PNG по шести обязательным путям, включить manifest/runtime, пройти Godot CI, Windows export и ручной игровой QA.

## Production gate

Сейчас отсутствуют:
- assets/spire/towers/necro/base/level_1.png
- assets/spire/towers/necro/base/level_2.png
- assets/spire/towers/necro/base/level_3.png
- assets/spire/towers/necro/weapon/base/weapon_8way.png
- assets/spire/towers/necro/weapon/reaper/weapon_8way.png
- assets/spire/towers/necro/weapon/legion/weapon_8way.png

Эти пути проверяются scripts/td/td_modular_tower_assets.gd. Шесть VFX atlas уже существуют в candidate. runtime_ready остаётся false, пока не будет полного набора. Candidate art не заменяет production files.

## Контрольные листы и preview

Release: https://github.com/DoctorStrangeSH/Last-Ritual/releases/tag/windows-preview

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
