# Инструкции для ИИ и разработчиков

## Источник истины

Работай только в репозитории DoctorStrangeSH/Last-Ritual; перед изменениями проверяй фактическую видимость и доступ. Сначала проверь текущую ветку main, открытые PR и свежие GitHub Actions. Если документация противоречит исходникам или CI, сначала установи фактическое состояние, затем исправь документацию.

Перед каждой задачей прочитай:
1. docs/AI_HANDOFF.md — правила передачи работы.
2. docs/PROJECT_STATE.md — проверенный снимок текущего состояния.
3. docs/ROADMAP.md — единственная очередность этапов.
4. docs/GAME_DESIGN.md и docs/ARCHITECTURE.md — замысел и устройство.
5. Соответствующие записи в docs/DECISIONS.md.

## Порядок работы

1. Выбери **первый незакрытый этап** в docs/ROADMAP.md. Не перепрыгивай вперёд. Если этап заблокирован, объясни причину и не начинай несвязанную фичу.
2. Уточни актуальный код, тесты и workflow до редактирования. Делай небольшое изменение с одной понятной целью.
3. Создай отдельную ветку от актуального main. Не коммить напрямую в main. Один этап — один небольшой PR; не смешивай рефакторинг, контент и баланс без необходимости.
4. Добавляй регрессионный тест для каждой исправленной ошибки или новой механики, если это можно проверить автоматизированно.
5. Запусти доступные проверки и проверь PR workflow. Не объявляй проверку успешной, пока GitHub Actions действительно не завершился с conclusion=success. Проверь также push-workflow после объединения.
6. Не объединяй PR при красном, ожидающем или отсутствующем обязательном CI. После успешных проверок используй принятый в проекте squash merge и проверь результат в main.
7. В той же задаче обнови docs/PROJECT_STATE.md, docs/AI_HANDOFF.md и отметку в docs/ROADMAP.md. Отмечай этап завершённым только после выполнения его критериев.
8. В итоговом сообщении укажи: что сделано, PR/коммит, результат CI, что не проверено вручную и следующий этап.

## Безопасность изменений

- Сохраняй обратную совместимость с существующими сохранениями. Изменение формата требует явной версии, валидации и тестов миграции.
- Тесты не должны читать, перезаписывать или удалять пользовательское сохранение; используй отдельный тестовый путь.
- Не удаляй файлы, ресурсы или документацию, пока поиском по проекту не подтверждено, что они не используются. Очистку делай отдельным обзорным изменением.
- Не добавляй сторонние зависимости без необходимости. Сохраняй совместимость с Godot 4.4.1 и текущим Windows workflow.
- Не заявляй, что визуальная часть или баланс проверены, только на основании headless CI.
- Не добавляй хронологические простыни в README, AI_HANDOFF или PROJECT_STATE. Исторические решения кратко сохраняй в docs/DECISIONS.md; текущее состояние должно быть компактным.
- Не меняй управление, цены, сохранения и баланс в чисто визуальном PR без отдельного обоснования.

## Определение готовности этапа

Этап готов, когда выполнены все его критерии из ROADMAP, тесты обновлены и проходят, CI зелёный, документация отражает фактический код, а оставшиеся ручные проверки явно записаны. «Код написан» не означает «этап завершён».

## Pixel Art migration and recurring handoff

- The owner approved a whole-game, detailed dark-fantasy Pixel Art direction. Read `docs/AI_HANDOFF_PIXEL_ART.md` and `docs/art/PIXEL_ART_STYLE_GUIDE.md` before art or tower-renderer work.
- After every meaningful PR, asset import, implementation stage or QA result, update the current summary in `docs/AI_HANDOFF.md`, the detailed handoff, `docs/PROJECT_STATE.md` and the first current section of `docs/ROADMAP.md`. Record decisions in `docs/DECISIONS.md` when the design changes. Do not let these documents drift.
- Owner permits old sprite deletion, but never use blanket deletion. Inventory exact references (including dynamically constructed paths), classify runtime/fallback/source/licence/test-only assets, and remove only proven-unused resources in a dedicated PR with Godot import, smoke and Windows checks. Preserve original Soul Altar source files and third-party licence/provenance.
- Do not mark visual QA complete based on headless CI. Record the owner's actual Windows feedback and update the handoff accordingly.
