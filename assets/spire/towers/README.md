# Структура PNG башен Last Ritual

ID папок совпадают с игровыми ID в Godot. Не переименовывайте их.

| ID | Башня | Специализации |
|---|---|---|
| bone | Костяная | siege = Баллиста; swarm = Рой |
| fire | Огненная | siege = Инферно; swarm = Искры |
| necro | Некромант | siege = Жнец; swarm = Легион |
| frost | Ледяная | siege = Мороз; swarm = Метель |

У каждой башни предусмотрены три уровня для четырёх независимых наборов:
- base/level_1..level_3 — основание/корпус башни.
- weapon/level_1..level_3 — оружие на башне.
- projectiles/level_1..level_3 — летящий снаряд.
- weapon_impact/level_1..level_3 — эффект попадания оружия.

Специализации: specializations/siege/ и specializations/swarm/.
Общие эффекты: assets/spire/animations/{construction,destruction,idle,muzzle_flash}/.

## Как загружать
Клади PNG в папку нужного уровня. Например: assets/spire/towers/bone/weapon/level_2/.
Рекомендуемые имена: bone_weapon_level_2.png, bone_projectile_level_2.png, bone_weapon_impact_level_2.png.
Можно присылать цельный SpriteSheet — не разрезай вручную.
Сохраняй RGBA/прозрачность, исходное разрешение и пропорции. Не растягивай и не пересохраняй с потерей качества. Если есть README/LICENSE, приложи их в assets/spire/licenses/ и укажи источник.

## Важно: разные типы изображений
- projectiles — сам снаряд во время полёта.
- weapon_impact — отдельная анимация в точке попадания.
- muzzle_flash — вспышка у дула при выстреле.
- construction/destruction — эффекты строительства/разрушения корпуса.

Папки подготовлены для загрузки исходников. Наличие PNG само по себе не подключает его в игру. После загрузки я проверю размеры, кадры, pivot/центр, прозрачность и соответствие уровня, затем подключу слои в Godot. Текущая визуальная система слоёв ещё требует реализации; игровой код этим PR не меняется.
