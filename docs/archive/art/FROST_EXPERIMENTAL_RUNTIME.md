# Ледяной обелиск: экспериментальное включение графики

**Статус:** PNG-кандидаты подключены для проверки в игре. Не считать финально утверждённым артом.

8 PNG перенесены **по точным Git blob SHA** из успешно экспортированного snapshot `art/frost-png-preview-88932a1cf8d8`:
- `assets/spire/towers/frost/experimental/base_level_{1,2,3}.png`: 3 основания, 128×128;
- `assets/spire/towers/frost/experimental/weapon_level_{1,2,3}.png`: 3 кристалла, 128×128;
- `assets/spire/towers/frost/vfx/ice_shard_projectile_8f.png`: атлас 256×32, 8 кадров 32×32;
- `assets/spire/towers/frost/vfx/ice_burst_impact_8f.png`: атлас 512×64, 8 кадров 64×64.

Графика активна через `FROST_EXPERIMENTAL_ART := true` в `scripts/td/td_tower_visuals.gd`. Для немедленного отката к предыдущей Spark-графике сменить на `false` и пересобрать EXE. База и кристалл рисуются в одном 128-пиксельном координатном пространстве, кадры атаки проигрываются по ходу существующего trail.

`necro`, `bone`, `fire`, gameplay IDs, баланс, управление и сохранения не изменены. Автотест проверяет каждый уровень, размеры и восьмой кадр атаки. **Художественное QA в Windows и сравнение с референсами всё ещё обязательны**. Исходники SVG находятся в `assets/spire/towers/frost/source/`.
