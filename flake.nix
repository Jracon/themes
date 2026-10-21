{
  description = "Colour palettes and the theme files generated from them.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      inherit (nixpkgs) lib;

      forAllSystems =
        f:
        lib.genAttrs [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ] (system: f nixpkgs.legacyPackages.${system});

      palettes = builtins.fromJSON (builtins.readFile ./palettes.json);
      names = builtins.attrNames palettes;

      # signature hue -> its ANSI colour; orange and pink have no terminal slot
      ansiNames = {
        blue = "blue";
        cyan = "cyan";
        green = "green";
        purple = "magenta";
        red = "red";
        yellow = "yellow";
      };

      # the 16 terminal slots: 0/8 are the dark neutrals and 7/15 the light ones in both modes;
      # bright hues reuse the normal ones
      ansiSlots =
        p: mode:
        let
          c = p.${mode};
          hues = [
            c.red
            c.green
            c.yellow
            c.blue
            c.purple
            c.cyan
          ];
        in
        if mode == "dark" then
          [ c.selection ]
          ++ hues
          ++ [
            c.muted
            c.comment
          ]
          ++ hues
          ++ [ c.bright ]
        else
          [ c.fg ]
          ++ hues
          ++ [
            c.selection
            c.comment
          ]
          ++ hues
          ++ [ c.bg ];

      # a palette by name, plus what tools derive from it
      resolve =
        name:
        assert lib.assertMsg (
          palettes ? ${name}
        ) "unknown palette '${name}', choose from: ${toString names}";
        let
          p = palettes.${name};
        in
        assert lib.assertMsg (
          ansiNames ? ${p.signature}
        ) "palette '${name}': signature '${p.signature}' has no ANSI colour";
        {
          inherit name;
          inherit (p) dark light signature;

          ansi = {
            dark = ansiSlots p "dark";
            light = ansiSlots p "light";
          };
          signatureAnsi = ansiNames.${p.signature};
        };

      kebab = lib.stringAsChars (c: if c != lib.toLower c then "-${lib.toLower c}" else c);

      cssVars =
        indent: palette: mode:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (key: value: "${indent}--${kebab key}: ${value};") (
            palette.${mode} // { accent = palette.${mode}.${palette.signature}; }
          )
          ++ [ "${indent}color-scheme: ${mode};" ]
        );

      # light by default, dark through the OS preference or an explicit data-theme
      css =
        palette:
        lib.concatStringsSep "\n" [
          ":root {"
          (cssVars "  " palette "light")
          "}"
          ""
          "@media (prefers-color-scheme: dark) {"
          "  :root:not([data-theme=\"light\"]) {"
          (cssVars "    " palette "dark")
          "  }"
          "}"
          ""
          ":root[data-theme=\"dark\"] {"
          (cssVars "  " palette "dark")
          "}"
          ""
        ];

      weztermScheme =
        palette: mode:
        let
          c = palette.${mode};
          ansi = palette.ansi.${mode};
          signature = c.${palette.signature};
        in
        {
          ansi = lib.take 8 ansi;
          background = c.bg;
          brights = lib.drop 8 ansi;
          cursor_bg = signature;
          cursor_border = signature;
          cursor_fg = c.onAccent;
          foreground = c.fg;
          scrollbar_thumb = c.border;
          selection_bg = c.selection;
          selection_fg = c.bright;
          split = c.border;
        };

      weztermSchemes = palette: {
        "${palette.name}-dark" = weztermScheme palette "dark";
        "${palette.name}-light" = weztermScheme palette "light";
      };

      # `colors/themes.lua` plus the palette it reads, baked in at build time
      neovimPlugin =
        pkgs: palette:
        pkgs.vimUtils.buildVimPlugin {
          pname = "themes-nvim-${palette.name}";
          version = "0";

          postInstall = ''
            mkdir -p $out/lua/themes
            cp ${pkgs.writeText "palette.lua" "return ${lib.generators.toLua { } palette}"} $out/lua/themes/palette.lua
          '';
          src = ./neovim;
        };
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      lib = {
        inherit
          css
          names
          neovimPlugin
          palettes
          resolve
          weztermSchemes
          ;
      };

      packages = forAllSystems (
        pkgs:
        let
          tomlFormat = pkgs.formats.toml { };
          perPalette = f: lib.genAttrs names (name: f (resolve name));
        in
        {
          css = pkgs.linkFarm "themes-css" (
            map (name: {
              name = "${name}.css";
              path = pkgs.writeText "${name}.css" (css (resolve name));
            }) names
          );

          json = pkgs.linkFarm "themes-json" (
            map (name: {
              name = "${name}.json";
              path = pkgs.writeText "${name}.json" (builtins.toJSON (resolve name));
            }) names
          );

          # drop into ~/.config/wezterm/colors/
          wezterm = pkgs.linkFarm "themes-wezterm" (
            lib.concatMap (
              name:
              lib.mapAttrsToList (scheme: colors: {
                name = "${scheme}.toml";
                path = tomlFormat.generate "${scheme}.toml" {
                  inherit colors;

                  metadata.name = scheme;
                };
              }) (weztermSchemes (resolve name))
            ) names
          );
        }
        // lib.mapAttrs' (name: palette: lib.nameValuePair "neovim-${name}" (neovimPlugin pkgs palette)) (
          perPalette lib.id
        )
      );
    };
}
