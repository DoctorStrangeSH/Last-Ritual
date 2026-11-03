# Прозрачные PNG эффектов некроманта — хранение в Git

Исходники эффектов хранятся в `assets/spire/towers/necro/source/vfx/`:

- `soul_projectile_8f.svg` — 8 кадров × 32×32, воспроизводимый PNG-атлас 256×32.
- `soul_impact_8f.svg` — 8 кадров × 64×64, воспроизводимый PNG-атлас 512×64.

Workflow `.github/workflows/necro-png-snapshot.yml` после рендера 12 превью башен запускает `tools/export_necro_vfx.gd`, проверяет два PNG и сохраняет их в ту же **отдельную Git review-ветку** в `assets/spire/towers/necro/source/generated-preview/vfx/`.

Snapshot содержит SHA исходного коммита и `SHA256SUMS.txt` для всех **14 PNG**. Ветки review являются историческими снимками; не подменяют production assets. Оригиналы SVG не меняются, авторский PNG-концепт v0.5 сохраняется отдельно до бинарной загрузки.

Следующий шаг — художественная приёмка эффекта, затем копирование утверждённых PNG на постоянные игровые пути и замена runtime-фолбэка с сохранением проверок кадров.
