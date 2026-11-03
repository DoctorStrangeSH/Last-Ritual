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
- Candidate-набор: 3 основания, 3 восьминаправленных оружейных атласа и 6 VFX атласов. Легион v5 (PR #365 merged), Жнец v5 (PR #367 merged, exact-head CI #41486462092 SUCCESS), base v4 (PR #357 merged). Следующее — сравнить полный состав на 1× и получить художественную оценку владельца.
- Последняя итерация: Жнец и Легион v4 (PR #354), base weapon v4 — гранёная фиолетовая призма и золотая корона (PR #357 merged). Битый PNG восстановлен из кодового генератора; временный recovery workflow удалён.
- Candidate manifest runtime_enabled=false. Художественная приёмка владельцем не выполнена.
- Основания L1–L3 обновлены до candidate v4: индивидуальные шпили PR #360 и золотые/фиолетовые акценты PR #363 merged (exact-head CI #41481076084 SUCCESS). Следующее задание — ручная оценка 1× и читаемость Жнеца/Легиона. Художественная приёмка владельца ещё не проведена.

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

- Нет зафиксированной ручной приёмки текущего candidate Pixel Art владельцем.
- Модульный runtime Алтаря душ выключен.
- Полная миграция всех башен, врагов, окружения и UI на Pixel Art не завершена.
- Самостоятельные gameplay ID spark/pulse ещё не интегрированы.
- Нужен повторный ручной playtest актуальной Windows-сборки после последних изменений.

## Актуальный контрольный пункт после PR #370

- PR #369: компактный лист `soul_altar_9_compositions_1x.png` опубликован в `windows-preview`, main workflow #41506868156 SUCCESS.
- PR #370: автоматический запрет случайного продвижения candidate-арта в production, exact-head CI #41507365642 SUCCESS, merged `9ec0683855e1fa342938c7768caf8a251711d0eb`.
- Специализации: base weapon v4 (#357), Legion v5 (#365), Reaper v5 (#367); основания L1–L3 с контрастными рунами (#363).
- Художественная приёмка на масштабе 1× **не получена**. `runtime_enabled=false`, отсутствуют шесть production PNG; не включать без согласования.

## Следующее действие

Попросить владельца оценить 9-композиционный лист на 1× и полный лист 72 направлений. При замечаниях — один art PR на одну проблему; при одобрении — отдельный PR для production integration с Windows QA. Не менять баланс и сохранения в арт-PR.

## Проверка полного художественного листа — 03.11.2026

- PR #374 merged: `0d63e80662ca8762a1b3475bb3d5d4e166c7b302`.
- Exact-head CI #41578037939 SUCCESS: новый `tests/test_soul_altar_full_sheet_integrity.py` проверяет пиксели всех 72 вариантов (L1–L3 × base/Reaper/Legion × восемь направлений) против исходных кандидатных PNG.
- Production manifest не переключать: `runtime_enabled=false`, шесть production PNG отсутствуют; ручная художественная приёмка владельца ещё не получена.
- Следующий шаг: просмотреть `soul_altar_9_compositions_1x.png` и `soul_altar_modular_contact_sheet_1x.png` из релиза `windows-preview`, записать замечания/одобрение; только после одобрения отдельный PR production integration.
