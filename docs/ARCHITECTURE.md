# Архитектура Last Ritual

Актуально на 02.11.2026. Godot 4.4.1, main scene — scenes/run_loop.tscn.

## Точки входа

- project.godot — конфигурация и main scene.
- scenes/run_loop.tscn / scripts/run_loop.gd — хаб, выбор сложности, автоматический цикл пяти дней и ночей, переходы, награды, состояние крепости и мета-прогресс.
- scenes/topdown_td_prototype.tscn / scripts/topdown_td_prototype.gd — дневная защита, волны, башни, враги, герой, эффекты и TD UI.
- scenes/topdown_night_prototype.tscn / scripts/topdown_night_prototype.gd — ночная арена, комнаты, враги, бой, награды, двери и магазины.
- scripts/dungeon_floor_graph.gd — воспроизводимый граф комнат.
- scripts/meta_progression.gd — версионированный постоянный профиль.
- scripts/td/ — характеристики, каталог, targeting, damage, synergy, tower visuals, tooltip, VFX и модульный art contract.

## Состояние архитектуры

Крупная игровая логика дневной и ночной сцен всё ещё сосредоточена в больших Node2D scripts, значительная часть рендеринга выполняется через _draw(). Вынесены отдельные helper-модули для независимых правил и тестируемых расчётов. Не переписывать большие сцены одним PR; выносить один компонент за раз, с regression tests.

## Башни и ресурсы

Игровые ID магазина: bone, fire, necro, frost. Каталог дизайна содержит ещё spark и pulse, но их боевые системы не подключены отдельно. Не менять legacy IDs, структуру сохранений и asset aliases без тестов и миграции.

Для Алтаря душ:
- цельные approved sprites и production fallback используются текущим рендером;
- модульный renderer загружает manifest и включается только через runtime_ready;
- candidate art лежит отдельно в assets/spire/towers/necro/candidate;
- candidate runtime выключен, пока не созданы шесть обязательных production base/weapon файлов и владелец не одобрил набор.

## Тестирование и сборка

Главный workflow: .github/workflows/windows-build.yml. Используется Godot 4.4.1; workflow выполняет импорт, Python tests, headless Godot tests и Windows export.

Ключевые smoke tests:
- tests/topdown_smoke.gd
- tests/td_modular_tower_assets_smoke.gd
- tests/soul_altar_art_gate.gd
- tests/soul_altar_assembled_review_smoke.gd
- tests/soul_altar_modular_candidate_smoke.gd
- tests/soul_altar_modular_motion_preview_smoke.gd

## Правила изменений

- Сначала читать AGENTS.md, PROJECT_STATE, ROADMAP и соответствующий handoff.
- Не изменять пользовательские сохранения тестами.
- Любое изменение формата save требует versioning, validation и migration tests.
- Не удалять ресурсы без поиска динамических и статических ссылок.
- Не считать headless тесты ручной проверкой визуала.
