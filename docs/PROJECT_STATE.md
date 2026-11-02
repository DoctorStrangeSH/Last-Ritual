# Last Ritual — текущий снимок проекта

Дата: 02.11.2026  
Ветка: main  
HEAD (проверенный main после PR #357): b4e3c128a4ba6fb86d294a2aff37c71b37a39d68  
PR #357 exact-head проверка GitHub Actions #41476104817 — SUCCESS. Последний отдельно подтверждённый post-merge main workflow (после PR #358): #41474757990 — SUCCESS.

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

- В main присутствуют утверждённые цельные PNG, production pack и VFX.
- Текущий боевой renderer использует цельный спрайт Алтаря душ (approved render, production fallback для отсутствующего approved варианта).
- Модульный renderer существует, но gated: modular_necro_enabled определяется runtime_ready(manifest) и сейчас false.
- Candidate-набор: 3 основания, 3 восьминаправленных оружейных атласа и 6 VFX атласов.
- Последняя итерация: Жнец и Легион v4 (PR #354), base weapon v4 — гранёная фиолетовая призма и золотая корона (PR #357 merged). Битый PNG восстановлен из кодового генератора; временный recovery workflow удалён.
- Candidate manifest runtime_enabled=false. Художественная приёмка владельцем не выполнена.
- Следующий арт-пункт: основания L1–L3; ручная оценка base v4 на масштабе 1× всё ещё не проведена.

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
- tests/test_necro_weapon_silhouettes.py
- tests/test_necro_modular_preview.py
- tests/test_necro_modular_vfx.py

CI не заменяет ручной запуск EXE и визуальную приёмку.

## Незакрытые риски

- Нет зафиксированной ручной приёмки текущего candidate Pixel Art владельцем.
- Модульный runtime Алтаря душ выключен.
- Полная миграция всех башен, врагов, окружения и UI на Pixel Art не завершена.
- Самостоятельные gameplay ID spark/pulse ещё не интегрированы.
- Нужен повторный ручной playtest актуальной Windows-сборки после последних изменений.

## Следующее действие

Начать отдельный PR для более высоких и компактных оснований L1–L3 в tools/generate_necro_modular_candidates.py и соответствующих тестов. Не менять production manifest, renderer, баланс и сохранения.
