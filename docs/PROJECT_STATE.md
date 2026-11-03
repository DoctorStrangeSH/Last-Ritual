# Last Ritual — текущий снимок проекта

Дата: 03.11.2026  
HEAD main: `5a219a3ca17c85c3727766fa5042674fdc7bc18e` (PR #376 merged). Post-merge workflow #41580061364 — SUCCESS; Windows export опубликован.

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

## Обновление 03.11.2026 — композиционный тест

- PR #372 merged (`e6f9ae202ed4259c47173e70409f262f9487f3ab`), exact-head CI #41575959537 SUCCESS.
- `tests/test_soul_altar_compact_review.py` сверяет все девять кадров 1× с соответствующими кандидатными основаниями и северной позой оружия; workflow запускает тест автоматически.
- Основная ветка после merge требует отдельной post-merge проверки; ручная художественная приёмка владельца не проведена.
- Production manifest остаётся `runtime_enabled=false`; запрещено включать модульный арт до явного одобрения.

## Незакрытые риски

- PR #376 exact-head CI #41579876954 SUCCESS; post-merge main/Windows export #41580061364 SUCCESS.
- Нужен ручной игровой QA в Windows EXE: размещение, уровни L1–L3, смена специализаций, восемь направлений и эффекты выстрела/попадания.
- Полная миграция всех башен, врагов, окружения и UI на Pixel Art не завершена.
- Самостоятельные gameplay ID spark/pulse ещё не интегрированы.
- Нужен повторный ручной playtest актуальной Windows-сборки после последних изменений.

## Актуальный контрольный пункт после PR #370

- PR #369: компактный лист `soul_altar_9_compositions_1x.png` опубликован в `windows-preview`, main workflow #41506868156 SUCCESS.
- PR #370: автоматический запрет случайного продвижения candidate-арта в production, exact-head CI #41507365642 SUCCESS, merged `9ec0683855e1fa342938c7768caf8a251711d0eb`.
- Специализации: base weapon v4 (#357), Legion v5 (#365), Reaper v5 (#367); основания L1–L3 с контрастными рунами (#363).
- Художественная приёмка владельца получена 03.11.2026; модульный renderer включён в main после PR #376.

## Следующее действие

Попросить владельца запустить свежий LastRitual.exe из windows-preview и проверить Алтарь душ в TD: L1→L2→L3, Reaper/Legion, восемь направлений, выстрел/попадание, центрирование и save/load. При дефектах — отдельные fix PR; не удалять legacy fallback до успешного QA.

## Проверка полного художественного листа — 03.11.2026

- PR #374 merged: `0d63e80662ca8762a1b3475bb3d5d4e166c7b302`.
- Exact-head CI #41578037939 SUCCESS: новый `tests/test_soul_altar_full_sheet_integrity.py` проверяет пиксели всех 72 вариантов (L1–L3 × base/Reaper/Legion × восемь направлений) против исходных кандидатных PNG.
- PR #376 merged (`5a219a3c`); exact-head CI #41579876954 и post-merge Windows workflow #41580061364 SUCCESS; EXE опубликован в windows-preview.
- Следующий шаг: просмотреть `soul_altar_9_compositions_1x.png` и `soul_altar_modular_contact_sheet_1x.png` из релиза `windows-preview`, записать замечания/одобрение; только после одобрения отдельный PR production integration.

## Production-интеграция Алтаря душ — 03.11.2026

- Шесть production PNG созданы как байт-в-байт копии утверждённых файлов из `candidate/`; все шесть SHA совпадают.
- Временный workflow копирования удалён после успешного выполнения; production assets и candidate archive сохранены отдельно.
- Root manifest включает runtime только при полном наборе слоёв и проверенных существующих VFX.
- Обновлены Godot smoke tests и Python promotion gate: теперь они ожидают production-ready manifest и подтверждают, что candidate archive остаётся выключенным.
- До merge ветки `main` не считать интеграцию опубликованной. Следующий ИИ: проверить PR/CI, исправить тесты при необходимости, дождаться post-merge Windows build, затем вручную проверить EXE.
