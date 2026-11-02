# Last Ritual — ревизия репозитория

Снимок на 02.11.2026.

## Текущее состояние

- Репозиторий: DoctorStrangeSH/Last-Ritual, публичный, default branch main.
- HEAD: 587304e2a82b1979fff91394fd638e39c2452f89.
- Рекурсивное дерево main: 489 путей; дерево не обрезано GitHub API.
- История PR #1–#355 просмотрена по спискам, названиям и статусам. Последние PR #354/#355 и их CI проверены подробно.
- Открытые Issues на момент проверки не найдены.
- #289 закрыт как устаревший snapshot, заменённый более поздними Soul Altar source/approved assets.
- #295 остаётся открытым Draft review snapshot Frost Obelisk; его PNG — кандидатные материалы, не production.

## Release и CI

- Главный workflow: .github/workflows/windows-build.yml.
- Последний main CI #41438238070 — SUCCESS.
- Rolling Release windows-preview публикует игровой EXE, отдельный Art Preview EXE и contact sheets. Предпочитать release assets вместо большого числа Actions artifacts, чтобы не возвращать проблему quota.

## Безопасная очистка

- Не удалять архивы, PNG, SVG, fallback или source folders пакетно.
- Перед удалением искать прямые и динамические ссылки, manifest entries, preload/load paths и тестовые ссылки.
- Сначала отдельный PR на замену и переключение runtime, затем CI и Windows QA, затем отдельный cleanup PR.
- Сохранять provenance, лицензии и воспроизводимые исходники.
- Не удалять ветки и старые PR без проверки, что в них нет уникальных source assets или полезного аудита.
- Сохранять candidate/approved/rejected разделение арта.

## Документы

README, ROADMAP, PROJECT_STATE, AI_HANDOFF, AI_HANDOFF_PIXEL_ART, ARCHITECTURE и QA документы должны описывать main, а не исторический платформер. Исторические решения хранить в DECISIONS и Git history; текущие handoff-файлы держать компактными.
