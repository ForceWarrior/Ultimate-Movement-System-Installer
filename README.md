# Ultimate Movement System Installer

A Roblox Studio plugin for the Ultimate Movement System. It installs the kit into your place, explains every setting,
matches and uploads your animations, saves and shares presets, documents the API and adds the optional extras.

The movement system itself is not in this repository. The plugin works on a place that already has the kit in it.

## Using it in your own Studio

You do not need to upload anything. Studio loads any plugin file you put in your local Plugins folder.

### From the file

1. Download `UltimateMovementSystemInstaller.rbxmx` from the `build` folder (or from the Releases page).
2. Open Roblox Studio, go to the **Plugins** tab and click **Plugins Folder**. This opens
   `%LOCALAPPDATA%\Roblox\Plugins` on Windows (`~/Documents/Roblox/Plugins` on Mac).
3. Put the `.rbxmx` file in that folder.
4. Restart Studio. A **UMS Installer** button appears in the Plugins tab.

### From Studio itself

1. Drag `UltimateMovementSystemInstaller.rbxmx` into the Explorer of any place.
2. Right click the `UltimateMovementSystemInstaller` folder it adds and choose **Save as Local Plugin**.
3. Delete the folder from the place again.

### From the source

The `src` folder is a [Rojo](https://rojo.space) project, one file per script.

```
rojo build -o "%LOCALAPPDATA%\Roblox\Plugins\UltimateMovementSystemInstaller.rbxmx"
```

Studio picks up the new file on its own.

## Setting up the kit

The kit comes as one folder with a group per place, each named `UNGROUP IN` and where it belongs. Either drag each
group into that place and ungroup it there, or open the plugin and use the **Install** tab, which does it for you.

## Layout

| Path | What it is |
| --- | --- |
| `src/Main.server.luau` | The plugin entry: toolbar button, window and tabs |
| `src/Tab*.luau` | One module per tab (About, Install, Presets, Config, API, Library) |
| `src/Installer.luau`, `src/Requirements.luau` | Finding the kit and placing its folders |
| `src/Animation*.luau` | Matching animation clips to config slots and uploading them |
| `src/Config*.luau` | Reading and safely editing MovementConfig |
| `src/Presets.luau`, `src/PresetCodec.luau` | Saving, loading and sharing presets |
| `src/Library` | The optional extras the Library tab adds |
| `src/Content` | Every text the plugin shows |

## License

MIT, see [LICENSE](LICENSE). Made by Force Warrior and Captain Cookie.

## Notes

- AI assistance was used
