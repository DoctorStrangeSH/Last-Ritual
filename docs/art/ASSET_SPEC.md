# Last Ritual — технические требования к игровым ресурсам

## Формат и размеры
- Исходник сохранять **без изменений** и с текстом лицензии. Рабочая копия — PNG RGBA 8-bit; SVG подходит для UI иконок (проверить корректный импорт Godot), но не подменяет спрайт-листы.
- Ориентир **целевых одиночных** картинок: основа 64×64 или 96×96, оружие 64×64 или 96×96; снаряд 16×16 / 32×32; impact 32×32 / 64×64; специализация/иконка 64×64. Это **рекомендуемые будущие размеры**, не спецификация существующих источников Foozle.
- Исходные размеры **разные**: например, в Foozle base бывает 62×128, weapon sheet 576×96, spark weapon sheet 2176×128. **Не предполагать**, что любой sheet — ровно 64×64 кадры. Точные `frame_size`, `columns`, `rows`, `fps`, `origin` записывать для каждого источника в `manifest.json`.
- Изображения pixel-art: фильтр Nearest, без mipmap, без автоантиалиасинга, только целочисленное масштабирование исходной сетки пикселей.
- Важные координаты: `base_anchor` (основание по центру клетки), `weapon_anchor` (посадка наверху основания), `muzzle_anchor`, `projectile_center`, `impact_center`. Снимать на реальном Godot preview, не угадывать из концепта.
- Для 3 уровней сохранять общий логический footprint. Отдельные оригиналы каждого уровня, без незаметного обрезания и растяжения.

## Папки
```text
assets/spire/towers/<ballista|fire|spark|pulse|necro|frost>/
  base/level_1..level_3/
  weapon/level_1..level_3/
  projectiles/level_1..level_3/
  weapon_impact/level_1..level_3/
  specializations/siege/
  specializations/swarm/
assets/spire/animations/{construction,destruction,idle,muzzle_flash}/
docs/art/{reference,approved,rejected}/
```
Обе ветки специализации используют общие идентификаторы `siege` и `swarm` для совместимости кода; в UI показывать их собственные русские имена.

## Минимальный манифест для нового ассета
```json
{
  "id": "ballista_weapon_lv1",
  "source": "оригинальный URL или архив",
  "license": "CC0-1.0 или иной точный SPDX",
  "author": "автор/источник",
  "file": "assets/spire/towers/ballista/weapon/level_1/...png",
  "source_dimensions": [576, 96],
  "frame_size": [96, 96],
  "frame_order": [0],
  "fps": 0,
  "loop": false,
  "base_anchor": [0, 0],
  "weapon_anchor": [0, 0],
  "status": "candidate"
}
```
Значения якорей выше — **шаблон-заглушка**, а не калибровка. Для `loop=false` одноразовая анимация заканчивается и переключается на статичный полный idle.

## Приёмка
1. Проверить лицензию/атрибуцию и CRC/валидность PNG.
2. Проверить настоящие границы кадра и альфу; прогнать автоматические smoke-тесты Godot.
3. Визуально проверить посадку base+weapon и привязку projectile к muzzle.
4. Убедиться, что impact не повторяется бесконечно и пропадает после столкновения.
5. Зафиксировать manifest и скриншот preview в `docs/art/approved/` только после подтверждения.
6. Пройти exact-head CI, затем Windows-playtest; не объявлять готовность по одному успешному headless import.
