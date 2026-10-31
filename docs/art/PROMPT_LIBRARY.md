# Last Ritual — промпты для последующих ИИ

Используйте **этот файл + STYLE_BIBLE.md + ASSET_SPEC.md** вместе. Генерация концепта и генерация прозрачного игрового ассета — разные задачи. Не обещайте идентичного результата одной лишь формулировкой: сверяйтесь с сохранёнными референсами и утверждёнными PNG.

## Базовый стиль (включать в каждый промпт)
> Dark fantasy hand-crafted pixel art for a top-down 3/4-view roguelike tower defense. Obsidian stone, engraved bronze, hard clustered pixel edges, readable silhouette at native resolution, palette-controlled glowing magic, consistent angle, coherent material lighting. Crisp alpha, no text, no logos, no UI background, no blurry edges. Subject centered over a consistent ground anchor. Design matching the six-tower visual identities of Last Ritual. Do not imitate a specific copyrighted game's art.

## Шаблон: базовая башня
> [BASE STYLE]. Produce ONE isolated transparent tower base for [TOWER ID / ELEMENT / MATERIAL], upgrade level [1/2/3], empty weapon socket at specified anchor. Keep viewpoint/pixel grid identical across all levels. No weapon, no projectile. Clear negative space for the separate weapon layer.

## Шаблон: оружие
> [BASE STYLE]. Isolated transparent weapon mounted on [TOWER NAME] at [ANCHOR]. Upgrade level [1/2/3]; keep its silhouette compatible with the provided base. If an animation is needed, output individually identified frames with verified grid and a stable idle frame, not a poster.

## Шаблон: снаряд и impact
> [BASE STYLE]. Produce a distinct flying projectile for [TOWER] with direction/pivot marked separately in metadata, followed by a separate one-shot hit impact with [N] frames. Transparent pixel-art frames, same pixel scale, no background or labels.

## Шаблон: специализация
> [BASE STYLE]. One isolated 64×64 transparent ability icon for [TOWER] specialization [SIEGE OR SWARM]. Visual identifier [ICON SYMBOL]. Use [MAGIC COLOR] and a dark-metal rim. No text. Create a separate weapon/base overlay with the same palette after approving the icon; no new unrelated tower silhouette.

## Шаблон: враг
> [BASE STYLE]. One top-down/3-4 enemy [ROLE]. Transparent, idle + walk + attack + death on separately verified sheets. Clear movement direction and anchor. Silhouette should remain visible against stone floors. No background.

## Шаблон: UI
> Dark fantasy pixel-art UI, charcoal-black slate panel, warm bronze linework, strong readable Cyrillic typographic space, restrained elemental highlights, consistent tower icons. Produce UI chrome as separate 9-slice PNG / SVG components, not a screenshot of an entire menu.

## Negative prompt / ограничения
> photorealism, 3D render, bloom blur, watercolor, smooth-vector cartoon, modern flat UI, inconsistent isometric angle, letters baked into sprites, watermark, opaque colored background, cropped silhouette, different scale between upgrade tiers.

## Процесс для другого ИИ
1. Уточни asset ID, слой, уровень и специализацию; проверь, что это одна из шести башен.
2. Открой `docs/art/STYLE_BIBLE.md`, существующий Foozle PNG и `icon.svg` того же ID.
3. Создай **отдельный** ассет + manifest. Сохрани исходный промпт и версию генерации.
4. Сверь с прочими уровнями и соседними башнями на contact-sheet.
5. Прогоняй image import/smoke/preview; коммить только проверенный ресурс вместе с документацией.
