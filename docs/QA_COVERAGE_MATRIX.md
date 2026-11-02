# QA coverage — Last Ritual

Снимок на 02.11.2026. CI run #41438238070 для актуального main завершился SUCCESS. Автоматическое прохождение тестов не подтверждает ручную приёмку графики, баланс или запуск EXE на компьютере владельца.

## Автоматические проверки

| Область | Тест / workflow | Статус |
|---|---|---|
| Импорт проекта и ресурсы | Godot 4.4.1 headless editor import + verify_png_assets.py | CI |
| Основной цикл, TD, ночь, награды | tests/topdown_smoke.gd | CI |
| Каталог модульных башен и 8-way aim | tests/td_modular_tower_assets_smoke.gd | CI |
| Контракт и готовность арта Алтаря душ | tests/soul_altar_art_gate.gd | CI |
| Сохранённый approved atlas | tests/soul_altar_assembled_review_smoke.gd | CI |
| Candidate base/weapon/VFX и 72 сочетания | tests/soul_altar_modular_candidate_smoke.gd | CI |
| Motion Preview, направления и pivot | tests/soul_altar_modular_motion_preview_smoke.gd | CI |
| Reaper/Legion силуэты | tests/test_necro_weapon_silhouettes.py | CI |
| Контактные листы и candidate VFX | tests/test_necro_modular_preview.py, test_necro_modular_vfx.py, test_necro_vfx_contact_sheet.py | CI |
| Windows export | .github/workflows/windows-build.yml | CI |

## Обязательная ручная проверка владельцем

- [ ] Запустить именно LastRitual.exe, не LastRitual-ArtPreview.exe.
- [ ] Проверить хаб, сложность и автоматический переход день/ночь.
- [ ] Пройти дневную оборону: строительство, улучшения L1→L2→L3→специализация, ремонт, продажа, приоритет цели, шесть волн.
- [ ] Проверить перенос построек и состояния крепости между днями.
- [ ] Пройти ночные комнаты: движение, атака, рывок, двери, укрытия, награды, магазин, элита и босс.
- [ ] Проверить победу, поражение, новый забег и постоянный мета-прогресс.
- [ ] Проверить актуальную графику башен на площадке при 1×, читаемость и отсутствие перекрытий.
- [ ] Оценить Soul Altar candidate contact sheets и Art Preview при 1×; дать отдельное художественное одобрение или список правок.
- [ ] Проверить EXE на реальной Windows-системе и записать run/commit/разрешение/результат.

## Правила статусов

- CI PASS — только автоматические проверки.
- Art approved — только явное решение владельца после просмотра.
- Playtest passed — только реальный ручной прогон.
- Не заменять один статус другим.
