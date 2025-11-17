export const rootTscn = `[gd_scene load_steps=0 format=3]

[node name="Game" type="Game"]`

export const projectGodot = `config_version=5

[application]
config/name="GodotProject"
run/main_scene="root.tscn"`

export const gdextension = `[configuration]
entry_symbol = "swift_entry_point"
compatibility_minimum = 4.2

[libraries]
macos.debug = "res://bin/libSwiftRunner.dylib"
linux.debug.x86_64 = "res://bin/libSwiftRunner.so"
windows.debug.x86_64 = "res://bin/SwiftRunner.dll"`
