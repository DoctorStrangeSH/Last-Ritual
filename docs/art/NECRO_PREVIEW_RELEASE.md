# Просмотр игровых PNG-кандидатов Алтаря душ

На успешных сборках `main` в rolling GitHub Release `windows-preview` публикуются два разных файла:

- `LastRitual.exe` — сама игра (runtime-графика пока не заменена на исходники из PR #281).
- `SoulAltar-art-preview.zip` — 11 **кандидатных** PNG, полученных в Godot 4.4.1 из сохранённых в Git SVG.

ZIP содержит 3 основания, 3 оружия, 3 собранных башни и 2 специальных облика третьего уровня. `SHA256SUMS.txt` позволяет проверить целостность каждого PNG; `README.txt` содержит SHA коммита сборки.

Где скачать: https://github.com/DoctorStrangeSH/Last-Ritual/releases/tag/windows-preview

Важные ограничения: это **QA-preview, не финальные спрайты**. Их нельзя считать художественно утверждёнными без сравнения с эталонными пользовательскими концептами. Оригинальный большой PNG-концепт v0.5 всё ещё не добавлен в Git; отслеживание в `docs/art/NECRO_SOURCE_V05.md`. ZIP создаётся после успешного Godot-экспорта и Windows-сборки, публикуется через Release assets вместо GitHub Actions artifacts (не расходует их квоту).

Для самостоятельного воспроизведения:

```bash
godot --headless --path . --script res://tools/export_necro_layers.gd
```

Файлы появляются в `build/art-preview/necro/`. Чтобы редактировать художественные формы, изменяйте **исходные SVG**, а не PNG, и сохраняйте оригиналы.
