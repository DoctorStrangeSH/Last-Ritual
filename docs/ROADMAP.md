# Last Ritual — единая актуальная дорожная карта

**Снимок на 03.11.2026. Main: `687473f3cd7a1426a8bf3f2190530d83b3dc7f2a`.** PR #376–#383 merged; Fire Turret exact-head CI #41589195484 и post-merge Windows Preview #41589363962 SUCCESS.

Старые этапы платформера закрыты исторически. Активная разработка — top-down roguelite + Tower Defense.

## 1. Проверенная основа — реализовано в main

- [x] Главная сцена run_loop.tscn объединяет день, ночь, награды и финал.
- [x] Пятидневная кампания с автоматическим чередованием дневной защиты и ночного исследования.
- [x] Дневная TD: восемь площадок, шесть волн, строительство, улучшение, продажа, ремонт, приоритет целей и герой-защитник.
- [x] Состояние построек и ресурсы крепости переносятся между днями.
- [x] Ночная top-down арена с комнатами, дверями, seed-генерацией, боями, наградами, магазинами и боссом.
- [x] Три сложности, мета-прогресс и достижения.
- [x] Прокачка башни: L1 → L2 → L3 → специализация четвёртым улучшением (PR #307).
- [x] Каталог, характеристики, подсказки, синергии и отдельные TD helper-модули.
- [x] Godot smoke tests, Python asset tests и Windows Preview workflow.
- [x] Алтарь душ: исходники и утверждённые цельные PNG сохранены в Git; текущий renderer имеет безопасный fallback.
- [x] Модульный manifest/loader, проверка восьми направлений, проверка отсутствующих файлов и изолированный Motion Preview.
- [x] Контактные листы 72 композиций в 1× и 2×, шесть candidate-only VFX атласов и отдельный Art Preview EXE.
- [x] PR #354: новые силуэты оружия Жнеца и Легиона v4; PR #355: запись результата в документации.

## 2. Production-интеграция Алтаря душ — завершена, ручной QA впереди

Владелец одобрил основания L1–L3 и три восьминаправленных оружейных атласа 03.11.2026. PR #376 объединён; интеграция в main завершена без изменения gameplay и сохранений.

- [x] Сохранён воспроизводимый источник `tools/generate_necro_modular_candidates.py`.
- [x] Подготовлены и проверены основания L1–L3 и оружие base/Reaper/Legion (PR #357, #360, #363, #365, #367).
- [x] Сравнительные листы 9 и 72 композиций; пиксельные тесты проверяют состав и наложение.
- [x] Получено явное одобрение владельца на production-интеграцию (03.11.2026).
- [x] Шесть PNG скопированы в production-пути байт-в-байт из approved source archive; candidate originals сохранены.
- [x] Root manifest в main: `owner_approved_production` / `runtime_enabled=true`.
- [x] Существующие production VFX переиспользуются; candidate VFX остаются вне runtime.
- [x] Добавлены/обновлены тесты manifest, alpha, 8-way и включённого runtime; старые цельные спрайты оставлены как fallback.
- [x] PR #376: exact-head CI #41579876954 и post-merge main/Windows Preview #41580061364 SUCCESS.
- [ ] Windows EXE QA: L1→L2→L3, выбор base/Reaper/Legion, восемь направлений, projectile/impact, сохранение/загрузка.
- [ ] Только после успешного QA рассмотреть удаление legacy assets отдельным PR после полного поиска ссылок.

### Production paths

- `assets/spire/towers/necro/base/level_1.png`, `level_2.png`, `level_3.png`
- `assets/spire/towers/necro/weapon/base/weapon_8way.png`
- `assets/spire/towers/necro/weapon/reaper/weapon_8way.png`
- `assets/spire/towers/necro/weapon/legion/weapon_8way.png`

Все шесть production PNG — точные копии одобренных исходников; кандидатный архив остаётся в `candidate/`. Production VFX пути не менялись. Root manifest в main включает runtime. Свежий EXE опубликован; ручной QA владельца впереди.

## 3. Следующие крупные этапы

- [x] PR #378 merged: модульный Pixel Art candidate pack Ледяного обелиска — 3 основания, 3 восьминаправленных оружейных атласа, 6 VFX strips и листы 9/72 композиций; production runtime выключен.
- [x] Manifest contract поддерживает индивидуальные ветви специализаций на башню; старое соответствие siege→reaper / swarm→legion для Алтаря душ сохранено.
- [x] Общий TD renderer учитывает отдельные ground anchor основания и pivot оружия; добавлены Godot/Python регрессионные тесты.
- [ ] Владелец: визуальная приёмка Ледяного обелиска на 1× (силуэт L1–L3, Мороз, Метель, 8 направлений и VFX); листы опубликованы в windows-preview.
- [ ] После одобрения — отдельный runtime PR Frost с сохранением текущего экспериментального fallback и ручным Windows QA.
- [x] PR #380 merged: Ballista modular Pixel Art candidate pack — 3 основания, base/siege_bolt/bone_volley 8-way оружие и 6 VFX strips; runtime выключен. Review sheets опубликованы в windows-preview.
- [ ] Художественная приёмка Frost и Ballista на 1×; оба candidate pack остаются вне runtime.
- [ ] После одобрения Frost — отдельный runtime PR; после одобрения Ballista — отдельный runtime PR. Не менять игровые ID `bone`/`frost` и не удалять Foozle fallback до ручного Windows QA.
- [x] PR #382 merged: Fire Turret modular Pixel Art candidate — 3 основания, base/inferno/sparks 8-way оружие, 6 VFX strips и 9/72 review sheets; runtime выключен.
- [x] Fire Turret exact-head CI #41589195484 и post-merge Windows Preview #41589363962 SUCCESS; review sheets опубликованы.
- [ ] Получить художественную приёмку Fire на 1×. Не заменять текущие Foozle assets до отдельного runtime PR и Windows QA.
- [ ] Отдельно подтвердить игровые ID, механики и баланс Искрового разрядника и Импульсного излучателя; сейчас это design identities, а не два самостоятельных игровых типа.
- [x] Подготовлен enemy roster review candidate: 6 ролей × 8 направлений × 4 кадра ходьбы; native 1×/2× review sheets. Generator run #41605211560 SUCCESS.
- [ ] Enemy roster PR CI/merge и post-merge Windows Preview; owner visual approval at 1× before any runtime integration.
- [ ] Перенести единый Pixel Art стиль на героя, землю, стены, TD-маршруты, комнаты, UI, предметы и эффекты.
- [ ] Провести полный ручной пятидневный playtest: Normal, Hard и Nightmare; победа, поражение, сохранения, повторный забег.
- [ ] Поэтапно заменить и удалить старые спрайты только после сканирования всех прямых и динамических ссылок, успешного CI и Windows QA.
- [ ] После каждого этапа обновлять этот файл, PROJECT_STATE и оба handoff.

## 4. Что не считать завершённым

- Headless CI не подтверждает художественное качество, баланс или реальное прохождение.
- Публикация Art Preview EXE не означает, что модульный арт включён в игровую сборку.
- Наличие шести названий в каталоге не означает шесть реализованных боевых систем.
- Исторические PR и старые пункты прежних дорожных карт не являются активной очередью.

## 5. Правила выполнения

1. Начинать с первого незакрытого пункта активного этапа.
2. Один PR — одна понятная цель; отдельная ветка от актуального main.
3. Добавлять регрессионные тесты, запускать exact-head CI и проверять post-merge workflow.
4. Не менять сохранения, баланс или боевой код в чисто художественном PR.
5. Не удалять ресурсы без поиска использования и отдельного безопасного PR.
6. Обновлять документацию в том же PR, в котором меняется фактическое состояние.
