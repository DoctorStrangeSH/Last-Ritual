# AI HANDOFF — Last Ritual

Обновлено: 02.11.2026  
Репозиторий: https://github.com/DoctorStrangeSH/Last-Ritual  
Текущий main: 587304e2a82b1979fff91394fd638e39c2452f89  
Последний main CI: #41438238070 — SUCCESS.

## Как продолжить

Перед изменениями прочитать:
1. AGENTS.md
2. docs/PROJECT_STATE.md
3. docs/ROADMAP.md
4. docs/AI_HANDOFF_PIXEL_ART.md
5. docs/art/SOUL_ALTAR_ART_NEXT_STEPS.md
6. docs/DECISIONS.md и соответствующий модульный код/тесты.

Работать только от актуального main. Создавать отдельную ветку и PR. Не коммитить прямо в main. Проверять exact-head CI и post-merge main workflow. Обновлять PROJECT_STATE, ROADMAP и handoff при каждом значимом изменении.

## Видение владельца

- Только top-down roguelike + Tower Defense. Старый платформенный прототип не возвращать.
- Днём — стратегическая защита крепости; ночью — исследование комнат и бои в духе Isaac.
- Пять дней/ночей, автоматические переходы, новые карты на каждый забег.
- Длинные, вариативные и стратегические забеги; не сводить игру к короткому прототипу.
- Мрачный детальный Pixel Art для всей игры, единая перспектива и читаемые силуэты.
- Русский UI и понятные мышиные взаимодействия.
- Башни улучшаются L1→L2→L3, четвёртый шаг — выбор специализации.
- Приоритет качества: не включать черновой арт в production ради формального прогресса.

## Проверенное текущее состояние

- Main scene: scenes/run_loop.tscn.
- Day TD: scenes/topdown_td_prototype.tscn; шесть волн, восемь площадок, строительство/улучшение/продажа/ремонт, герой и приоритет целей.
- Night: scenes/topdown_night_prototype.tscn; комнаты, двери, враги, награды, магазины, босс, рывок.
- Campaign: пять циклов дня/ночи; переходы автоматические.
- Meta: scripts/meta_progression.gd.
- Магазин сейчас имеет четыре игровых башни: bone/fire/necro/frost.
- Каталог дополнительно содержит spark/pulse, но их самостоятельная боевая интеграция не завершена.
- Tower helpers находятся в scripts/td/. Основные TD/night scripts всё ещё крупные Node2D scripts; не считать архитектуру полностью компонентной.

## Текущий художественный этап: Алтарь душ

Candidate-арт находится в assets/spire/towers/necro/candidate/. Воспроизводимый источник — tools/generate_necro_modular_candidates.py. Набор содержит три основания L1–L3, три 8-way оружейных атласа и шесть VFX атласов.

PR #354 добавил силуэты Жнеца и Легиона v4. PR #355 записал успешный результат. Последний CI для PR #354: #41437657879 SUCCESS; main после PR #354: #41437819641 SUCCESS; актуальный main после PR #355: #41438238070 SUCCESS.

Production manifest остаётся runtime_enabled=false. Боевой renderer продолжает использовать цельные утверждённые спрайты/production fallback. Кандидатные слои не подключены к игре.

Следующий шаг по плану: base weapon v4 — заменить слабый силуэт золотого бруска на выразительную призму/руническую корону. Затем переработать основания L1–L3 и общую палитру. Детали — docs/art/SOUL_ALTAR_ART_NEXT_STEPS.md.

## Ограничения и безопасность

- Не включать модульный runtime, пока отсутствуют все шесть production PNG и владелец не принял полный набор в Windows.
- Не считать контактный лист, smoke test или CI художественным одобрением.
- Не менять боевые характеристики, цены, сохранения или UI в арт-only PR.
- Не вращать всю башню: основание неподвижно, оружие имеет 8 hand-authored направлений.
- Не удалять старые PNG/SVG/атласы без поиска прямых и динамических ссылок.
- Не придумывать Aseprite-исходники. Источник candidate PNG — Python/Pillow generator.
- Не менять legacy gameplay IDs и save schema без отдельной миграции и тестов.

## Проверки и сборка

Godot: 4.4.1 Standard. Главный workflow: .github/workflows/windows-build.yml.

Локальные команды:
- godot --headless --path . --editor --quit
- godot --headless --path . --script res://tests/topdown_smoke.gd
- godot --headless --path . --script res://tests/td_modular_tower_assets_smoke.gd
- python tools/generate_necro_modular_candidates.py --verify
- python -m unittest discover -s tests -p 'test_necro_weapon_silhouettes.py' -v
- python -m unittest discover -s tests -p 'test_necro_modular_preview.py' -v
- python -m unittest discover -s tests -p 'test_necro_modular_vfx.py' -v

Важно: обычный запуск generator перезаписывает все 12 candidate PNG. Если изменён только один атлас, проверь diff и не коммить случайно пересозданные файлы. Отличия Pillow могут влиять на байты. Запуск --verify ничего не изменяет.

Motion Preview:
- 1/2/3 — уровень основания;
- B/R/L — base/Reaper/Legion;
- NumPad 8/9/6/3/2/1/4/7 — зафиксировать направление;
- A — автоматическое наведение;
- H — направляющие;
- F — выстрел и анимация попадания;
- Z — масштаб 1×/2×/2.5×/4×.

Windows Release: https://github.com/DoctorStrangeSH/Last-Ritual/releases/tag/windows-preview

## PR-аудит и открытые запросы

Проверена история PR #1–#355 по списку, заголовкам, статусам и датам; последние изменения #354/#355 проверены подробно. Не утверждать, что каждый исторический diff и каждый старый комментарий перечитан построчно.

- #355 — merged, документация после #354.
- #354 — merged, Reaper/Legion weapon v4 candidate.
- #295 — единственный оставленный открытым Draft review snapshot Frost Obelisk. Не включать эти PNG в production без отдельной художественной приёмки.
- #289 закрыт как superseded более поздними Soul Altar assets; ветка остаётся в истории.
- Других открытых Issues на момент аудита не найдено.

## Формат следующего отчёта владельцу

Указать: что сделано, номер PR и commit, exact-head CI, post-merge CI, что проверено автоматически, что осталось проверить вручную и один следующий шаг.
