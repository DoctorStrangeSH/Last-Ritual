# Foozle Spire — каталог исходных ассетов

Источник: архивы Foozle Spire, предоставленные владельцем проекта 31.10.2026.
Все восемь пакетов содержат `Readme.txt` с лицензией **Creative Commons Zero (CC0 1.0)**, автор/исполнитель Baldur, распространитель Foozle. Проверять оригинальный Readme каждого пакета при новых импортированных файлах.

## Откуда брать графику

| Назначение | Исходный архив | Файлы | Целевое расположение |
|---|---|---|---|
| Кости | `Foozle_2DS0017_Spire_TowerPack_1.zip` | `Tower 01.png`, `Tower 01 - Level 01/02/03 - Weapon.png` | `assets/spire/towers/bone/` |
| Огонь | `Foozle_2DS0018_Spire_TowerPack_2.zip` | `Tower 03.png`, `Tower 03 - Level 01/02/03 - Weapon.png` | `assets/spire/towers/fire/` |
| Некромантия | `Foozle_2DS0019_Spire_TowerPack_3.zip` | `Tower 05.png`, `Tower 05 - Level 01/02/03 - Weapon.png` | `assets/spire/towers/necro/` |
| Лёд | `Foozle_2DS0020_Spire_TowerPack_4.zip` | `Tower 07.png`, `Tower 07 - Level 01/02/03 - Weapon.png` | `assets/spire/towers/frost/` |
| Стройка | `Foozle_2DS0021_Spire_BuilderPack.zip` | `Tower Construction.png`, `Tower - Collapse.png`, `Wisp - Animations.png` | `assets/spire/builder/` |
| Наземные враги | `Foozle_2DC0028_Spire_EnemyPack_2_Ground.zip` | `Firebug.png`, `Leafbug.png`, `Magma Crab.png`, `Scorpion.png` | `assets/spire/enemies/ground/` |
| Летающие враги | `Foozle_2DC0027_Spire_EnemyPack_1_Flying.zip` | `Clampbeetle.png`, `Firewasp.png`, `Flying Locust.png`, `Voidbutterfly.png` | `assets/spire/enemies/flying/` |
| Карта | `Foozle_2DT0012_Spire_Tileset_1.zip` | `Grass Tileset.png`, `Animated water tiles.png` | `assets/spire/terrain/` |

**Не включать**: ZIP-архивы, PSD/Aseprite, видео/GIF-превью, дубликаты экспорта и неиспользуемые вариации. Сохранять оригинальные `Readme.txt` пакетов в `assets/spire/licenses/` при добавлении PNG. Оригиналы можно повторно получить у владельца из перечисленных архивов.

## Статус и инструкция для следующего ИИ

- Этот документ — карта источников, **не подтверждение импорта** перечисленных PNG в репозиторий.
- PR #253 содержит экспериментальный `assets/spire/towers_atlas.png`, который ранее не импортировался в Godot (`ERR_FILE_CORRUPT`). Не считать исправленным без нового успешного CI.
- Следующий шаг: из оригинальных `Tower 01/03/05/07` собрать читаемый PNG-атлас; сохранить кадры/размеры в metadata, запустить Godot 4.4.1 editor import + smoke, проверить 4 анимации вручную.
- PR #254 основан на #253; настоящие BuilderPack-анимации ещё необходимо подключить.
- Добавлять контент небольшими отдельными PR, без изменения баланса/управления и сохранений. Не merge при красном CI.

## Оригинальный атлас специализаций Last Ritual (авторская пиксельная графика)

Файл: `res://assets/spire/variants/specialization_icons_atlas.png` — прозрачный PNG RGBA **256×32**, восемь клеток **32×32**, кадры слева направо:

| Индекс | Школа | Вариант | Символ |
|---|---|---|---|
| 0 | bone | siege / Баллиста | тяжёлый костяной болт |
| 1 | bone | swarm / Рой | три стрелы |
| 2 | fire | inferno / Инферно | большое пламя |
| 3 | fire | sparks / Искры | три искры |
| 4 | necro | reaper / Жнец | коса |
| 5 | necro | legion / Легион | три черепа |
| 6 | frost | strong / Мороз | ледяной кристалл |
| 7 | frost | blizzard / Метель | три снежинки |

Это **новые оригинальные иконки**, подготовленные для будущих визуальных эффектов, а не готовые 3-уровневые спрайты башен Foozle. Код игры пока не использует атлас. При интеграции использовать `Rect2(index * 32, 0, 32, 32)` и ближайшую фильтрацию текстур (nearest), а специализации связывать с фактическими значениями из gameplay-кода, не подменяя механику.
