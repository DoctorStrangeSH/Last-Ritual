# Архитектура

Движок: Godot 4.2+, GDScript. Главная сцена: scenes/main.tscn (Node2D), скрипт scripts/main.gd.
Текущий v0.2 прототип монолитный. Состояния: title, day, night, ritual, win, lose. Процедурный рендер через _draw(); без внешних ассетов.
Рекомендуемые последующие компоненты: GameState, Fortress, Tower, Enemy, NightLevel, Player, Boss, Ritual, UI. Разделять только после проверки базового цикла.
