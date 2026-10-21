# themes

Colour palettes and the theme files generated from them. `palettes.json` is the one source of truth; everything else is derived from it.

Each palette has `dark` and `light` sets (`bg`, `surface`, `raised`, `selection`, `border`, `comment`, `muted`, `fg`, `bright`, `onAccent`, and the hues `blue cyan green orange pink purple red yellow`), a `signature` hue for the accent, and a `meta` block recording the settings it was designed with. The signature must be a hue that has an ANSI slot (not orange or pink). Keep keys A–Z.

| Palette  | Signature | For                         |
| -------- | --------- | --------------------------- |
| `moss`   | green     | warm wood, green desk       |
| `violet` | purple    | everything else             |

`workbench.html` is the playground the palettes were designed in: sliders for tint, lightness and chroma, previews of an editor, terminal and site, and a Nix export. Open it in a browser.

## Use it

**Any tool** — build a package and copy the files:

```bash
nix build github:jracon/themes#css      # moss.css, violet.css (custom properties, light + dark)
nix build github:jracon/themes#json     # resolved palettes incl. the 16 ANSI slots
nix build github:jracon/themes#wezterm  # <palette>-<mode>.toml for ~/.config/wezterm/colors/
```

Or read `palettes.json` directly.

**Nix** — add it as a flake input and use `themes.lib`:

| Output                                  | What                                                              |
| --------------------------------------- | ----------------------------------------------------------------- |
| `lib.names`, `lib.palettes`             | palette names and the raw data                                    |
| `lib.resolve name`                      | the palette plus `ansi.{dark,light}` and `signatureAnsi`          |
| `lib.weztermSchemes resolved`           | `<name>-dark` / `<name>-light` colour scheme tables               |
| `lib.css resolved`                      | the CSS text                                                      |
| `lib.neovimPlugin pkgs resolved`        | a vim plugin providing `:colorscheme themes` for that palette     |
| `packages.<system>.neovim-<name>`       | the same plugin, prebuilt                                         |

## Conventions

Terminal tools should name ANSI colours instead of hardcoding hex, so they follow whichever terminal scheme is active. Only the terminal emulator and editors need real hex values.
