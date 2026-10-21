-- themes colourscheme: every group is built from the palette module the flake bakes in (lua/themes/palette.lua),
-- picking the dark or light colours from 'background'
vim.cmd.highlight("clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd.syntax("reset")
end
vim.g.colors_name = "themes"

local palette = require("themes.palette")
local mode = vim.o.background == "light" and "light" or "dark"
local c = palette[mode]
local signature = c[palette.signature]

-- blend colour a toward b by t (0..1); used for tinted backgrounds
local function mix(a, b, t)
  local function channel(hex, i)
    return tonumber(hex:sub(i, i + 1), 16)
  end
  local out = "#"
  for _, i in ipairs({ 2, 4, 6 }) do
    out = out
      .. string.format("%02x", math.floor(channel(a, i) * (1 - t) + channel(b, i) * t + 0.5))
  end
  return out
end

local function hl(name, spec)
  vim.api.nvim_set_hl(0, name, spec)
end

for i, color in ipairs(palette.ansi[mode]) do
  vim.g["terminal_color_" .. (i - 1)] = color
end

-- editor
hl("Normal", { fg = c.fg, bg = c.bg })
hl("NormalFloat", { fg = c.fg, bg = c.surface })
hl("FloatBorder", { fg = c.border, bg = c.surface })
hl("FloatTitle", { fg = signature, bg = c.surface, bold = true })
hl("Cursor", { fg = c.onAccent, bg = signature })
hl("CursorLine", { bg = c.raised })
hl("CursorColumn", { bg = c.raised })
hl("ColorColumn", { bg = c.raised })
hl("LineNr", { fg = c.comment })
hl("CursorLineNr", { fg = signature, bold = true })
hl("SignColumn", { fg = c.comment })
hl("FoldColumn", { fg = c.comment })
hl("Folded", { fg = c.comment, bg = c.raised })
hl("EndOfBuffer", { fg = c.bg })
hl("NonText", { fg = c.border })
hl("Whitespace", { fg = c.border })
hl("SpecialKey", { fg = c.border })
hl("Conceal", { fg = c.comment })
hl("WinSeparator", { fg = c.border })
hl("VertSplit", { link = "WinSeparator" })
hl("Visual", { bg = c.selection })
hl("VisualNOS", { bg = c.selection })
hl("MatchParen", { fg = c.orange, bg = c.selection, bold = true })
hl("Search", { fg = c.bright, bg = mix(c.bg, c.yellow, 0.35) })
hl("CurSearch", { fg = c.onAccent, bg = c.yellow })
hl("IncSearch", { fg = c.onAccent, bg = c.yellow })
hl("Substitute", { fg = c.onAccent, bg = c.red })

-- menus, statusline, messages
hl("Pmenu", { fg = c.fg, bg = c.raised })
hl("PmenuSel", { fg = c.bright, bg = c.selection, bold = true })
hl("PmenuSbar", { bg = c.raised })
hl("PmenuThumb", { bg = c.border })
hl("StatusLine", { fg = c.muted, bg = c.surface })
hl("StatusLineNC", { fg = c.comment, bg = c.surface })
hl("TabLine", { fg = c.comment, bg = c.surface })
hl("TabLineSel", { fg = c.bright, bg = c.bg, bold = true })
hl("TabLineFill", { bg = c.surface })
hl("WinBar", { fg = c.muted })
hl("WinBarNC", { fg = c.comment })
hl("Title", { fg = signature, bold = true })
hl("Directory", { fg = c.blue })
hl("ErrorMsg", { fg = c.red })
hl("WarningMsg", { fg = c.yellow })
hl("ModeMsg", { fg = c.muted, bold = true })
hl("MoreMsg", { fg = c.green })
hl("Question", { fg = c.green })

-- syntax
hl("Comment", { fg = c.comment, italic = true })
hl("Constant", { fg = c.orange })
hl("String", { fg = c.green })
hl("Character", { fg = c.green })
hl("Number", { fg = c.orange })
hl("Boolean", { fg = c.orange })
hl("Float", { fg = c.orange })
hl("Identifier", { fg = c.fg })
hl("Function", { fg = c.blue })
hl("Statement", { fg = c.purple })
hl("Operator", { fg = c.cyan })
hl("PreProc", { fg = c.pink })
hl("Type", { fg = c.yellow })
hl("Special", { fg = c.cyan })
hl("SpecialChar", { fg = c.pink })
hl("Delimiter", { fg = c.muted })
hl("Tag", { fg = c.blue })
hl("Underlined", { underline = true })
hl("Error", { fg = c.red })
hl("Todo", { fg = c.onAccent, bg = c.blue, bold = true })

-- treesitter and LSP (the rest fall through to the groups above)
hl("@variable", { fg = c.fg })
hl("@variable.builtin", { fg = c.red })
hl("@variable.parameter", { fg = c.bright })
hl("@property", { fg = c.fg })
hl("@module", { fg = c.yellow })
hl("@constructor", { fg = c.yellow })
hl("@string.escape", { fg = c.pink })
hl("@punctuation.delimiter", { fg = c.muted })
hl("@punctuation.bracket", { fg = c.muted })
hl("@markup.heading", { fg = c.purple, bold = true })
hl("@markup.link", { fg = c.blue, underline = true })
hl("@markup.raw", { fg = c.green })
hl("@markup.strong", { bold = true })
hl("@markup.italic", { italic = true })
hl("LspReferenceText", { bg = c.raised })
hl("LspReferenceRead", { bg = c.raised })
hl("LspReferenceWrite", { bg = c.raised, underline = true })

-- diagnostics: coloured text, tinted virtual text, curly underlines
for name, color in pairs({
  Error = c.red,
  Warn = c.yellow,
  Info = c.blue,
  Hint = c.cyan,
  Ok = c.green,
}) do
  hl("Diagnostic" .. name, { fg = color })
  hl("DiagnosticVirtualText" .. name, { fg = color, bg = mix(c.bg, color, 0.1) })
  hl("DiagnosticUnderline" .. name, { undercurl = true, sp = color })
end

-- diff and git
hl("DiffAdd", { bg = mix(c.bg, c.green, 0.18) })
hl("DiffChange", { bg = mix(c.bg, c.blue, 0.14) })
hl("DiffDelete", { fg = c.red, bg = mix(c.bg, c.red, 0.18) })
hl("DiffText", { bg = mix(c.bg, c.blue, 0.32) })
hl("Added", { fg = c.green })
hl("Changed", { fg = c.orange })
hl("Removed", { fg = c.red })
hl("GitSignsAdd", { fg = c.green })
hl("GitSignsChange", { fg = c.orange })
hl("GitSignsDelete", { fg = c.red })
