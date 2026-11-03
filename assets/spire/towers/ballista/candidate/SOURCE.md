# Костяная баллиста — исходники модульного Pixel Art

Статус: **review candidate**, не production. Владелец ещё не утверждал этот набор.

Редактируемый воспроизводимый источник: tools/generate_ballista_modular_candidates.py. Он создаёт три основания 128×128, три восьминаправленных оружейных атласа и шесть VFX strips с прозрачным RGBA фоном.

Оружейные ветви: base, siege_bolt (тяжёлый осадный болт), bone_volley (три быстрых болта). Runtime mapping: siege → siege_bolt, swarm → bone_volley. Pivot оружия (64,90), ground anchor основания (64,118), направления N, NE, E, SE, S, SW, W, NW.

Кандидатные ресурсы не загружаются игровым рендерером: runtime_enabled=false. Существующие Foozle PNG не изменены. Aseprite-файл не создан и не заявляется.
