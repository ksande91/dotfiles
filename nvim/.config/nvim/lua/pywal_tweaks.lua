local M = {}

-- Named style transforms.  Each is a function taking one HSL color and
-- returning a modified HSL color.  Applied uniformly to every "accent"
-- slot in the derived palette (bg/fg/greys are preserved).
M.styles = {
  default = function(c) return c end,
  punchy  = function(c) return c.saturate(20) end,
  vivid   = function(c) return c.saturate(35).darken(2) end,
  muted   = function(c) return c.desaturate(25).lighten(4) end,
  pastel  = function(c) return c.desaturate(45).lighten(18) end,
  dim     = function(c) return c.darken(10).desaturate(12) end,
}

-- Slots whose color should NOT be passed through the style transform.
-- Greys and bg/fg should stay anchored so contrast math keeps working.
local PRESERVE = {
  bg = true, fg = true, grey = true, br_grey = true, comment = true,
  white = true, br_white = true,
}

local function active_style()
  local name = vim.g.pywal_tweaks_style or "default"
  return M.styles[name] or M.styles.default, name
end

-- Pywal-derived palette, expanded via HSL rotations into ~30 differentiated
-- slots.  See README in this directory or the conversation that produced it.
local function derive_palette(c)
  -- Greys are computed from bg/fg mixes rather than pywal's wallpaper-derived
  -- greys, which often land too close to fg and make comments unreadable.
  -- Fixed mixes guarantee contrast regardless of wallpaper.
  return {
    bg       = c.background,
    fg       = c.foreground,
    grey     = c.background.mix(c.foreground, 30),
    br_grey  = c.background.mix(c.foreground, 55),
    comment  = c.background.mix(c.foreground, 70),
    white    = c.white,
    br_white = c.br_white,

    yellow_warm   = c.yellow,
    yellow_cool   = c.yellow.rotate(-12).saturate(5),
    gold          = c.yellow.rotate(-25).lighten(3),
    orange        = c.orange,
    orange_dark   = c.orange.darken(8).saturate(5),
    brown         = c.brown,

    red           = c.red,
    red_soft      = c.red.lighten(8).desaturate(10),
    red_hot       = c.br_red.saturate(10),
    amaranth      = c.amaranth,

    purple        = c.purple,
    purple_warm   = c.purple.rotate(-15).saturate(5),
    purple_cool   = c.purple.rotate(15),
    pink          = c.pink,
    pink_soft     = c.pink.lighten(8).desaturate(5),
    magenta       = c.magenta,
    magenta_bright= c.br_magenta,

    blue          = c.blue,
    blue_deep     = c.blue.rotate(-12).saturate(5),
    blue_light    = c.br_blue.lighten(5),
    cyan          = c.cyan,
    cyan_warm     = c.cyan.rotate(-15).desaturate(5),
    cyan_cool     = c.br_cyan.rotate(8),
    teal          = c.cyan.rotate(15).saturate(10),

    green         = c.green,
    green_warm    = c.green.rotate(-25).saturate(5),
    green_cool    = c.green.rotate(20),
    olive         = c.green.rotate(-35).desaturate(15),
  }
end

local function styled_palette(c)
  local p = derive_palette(c)
  local fn = active_style()
  local out = {}
  for k, v in pairs(p) do
    if PRESERVE[k] then
      out[k] = v
    else
      out[k] = fn(v)
    end
  end
  return out
end

function M.apply()
  local ok, lw = pcall(require, "lushwal")
  if not ok then return end
  local c = lw.colors
  if not c or not c.foreground then return end

  local p = styled_palette(c)
  local set = vim.api.nvim_set_hl
  local bg, fg = p.bg, p.fg

  local cursor_bg    = bg.mix(fg, 12).hex
  local cursor_nr_bg = bg.mix(fg, 22).hex

  set(0, "CursorLine",   { bg = cursor_bg })
  set(0, "CursorColumn", { bg = cursor_bg })
  set(0, "CursorLineNr", { fg = p.gold.hex, bg = cursor_nr_bg, bold = true })
  set(0, "LineNr",       { fg = p.br_grey.hex, bg = bg.hex })
  set(0, "SignColumn",   { bg = bg.hex })
  set(0, "Visual",       { bg = bg.mix(fg, 25).hex })
  set(0, "Search",       { fg = bg.hex, bg = p.yellow_warm.hex, bold = true })
  set(0, "IncSearch",    { fg = bg.hex, bg = p.orange.hex,      bold = true })
  set(0, "MatchParen",   { fg = p.gold.hex, bold = true, underline = true })
  set(0, "Pmenu",        { fg = fg.hex, bg = bg.mix(fg, 12).hex })
  set(0, "PmenuSel",     { fg = bg.hex, bg = p.blue.hex, bold = true })
  set(0, "Folded",       { fg = p.br_grey.hex, bg = bg.mix(fg, 10).hex, italic = true })

  set(0, "Comment",                { fg = p.comment.hex, italic = true })
  set(0, "@comment",               { link = "Comment" })
  set(0, "@punctuation",           { fg = p.br_grey.hex })
  set(0, "@punctuation.bracket",   { fg = p.br_grey.hex })
  set(0, "@punctuation.delimiter", { fg = p.brown.hex })

  set(0, "Keyword",              { fg = p.purple.hex })
  set(0, "@keyword",             { fg = p.purple.hex })
  set(0, "Conditional",          { fg = p.purple_warm.hex, bold = true })
  set(0, "@keyword.conditional", { link = "Conditional" })
  set(0, "Repeat",               { fg = p.purple_cool.hex })
  set(0, "@keyword.repeat",      { link = "Repeat" })
  set(0, "@keyword.return",      { fg = p.red_hot.hex, bold = true })
  set(0, "@keyword.function",    { fg = p.purple.hex, italic = true })
  set(0, "@keyword.operator",    { fg = p.purple_warm.hex })
  set(0, "@keyword.import",      { fg = p.pink.hex })
  set(0, "Label",                { fg = p.pink_soft.hex })

  set(0, "Include",    { fg = p.pink.hex })
  set(0, "Define",     { fg = p.pink.hex, bold = true })
  set(0, "PreProc",    { fg = p.pink_soft.hex })
  set(0, "Macro",      { fg = p.magenta_bright.hex })
  set(0, "@attribute", { fg = p.magenta.hex, italic = true })
  set(0, "@decorator", { fg = p.magenta.hex, italic = true })

  set(0, "Type",             { fg = p.yellow_warm.hex, bold = true })
  set(0, "@type",            { fg = p.yellow_warm.hex })
  set(0, "Typedef",          { fg = p.yellow_cool.hex })
  set(0, "@type.builtin",    { fg = p.yellow_cool.hex, italic = true })
  set(0, "@type.definition", { fg = p.yellow_warm.hex, bold = true })
  set(0, "Structure",        { fg = p.gold.hex, bold = true })
  set(0, "StorageClass",     { fg = p.brown.hex })
  set(0, "@storageclass",    { link = "StorageClass" })
  set(0, "@constructor",     { fg = p.gold.hex, bold = true })
  set(0, "Tag",              { fg = p.cyan_cool.hex })
  set(0, "@tag",             { fg = p.cyan_cool.hex })
  set(0, "@tag.attribute",   { fg = p.cyan_warm.hex, italic = true })

  set(0, "Statement",  { fg = p.red.hex })
  set(0, "Exception",  { fg = p.red_soft.hex, bold = true })
  set(0, "@exception", { link = "Exception" })
  set(0, "Debug",      { fg = p.amaranth.hex })

  set(0, "Function",          { fg = p.blue.hex, bold = true })
  set(0, "@function",         { fg = p.blue.hex, bold = true })
  set(0, "@function.call",    { fg = p.blue.hex })
  set(0, "@function.builtin", { fg = p.blue_light.hex, bold = true })
  set(0, "@function.macro",   { fg = p.magenta_bright.hex })
  set(0, "@method",           { fg = p.blue_deep.hex, bold = true })
  set(0, "@method.call",      { fg = p.blue_deep.hex })

  set(0, "Identifier",          { fg = p.cyan.hex })
  set(0, "@variable",           { fg = fg.hex })
  set(0, "@variable.builtin",   { fg = p.red_soft.hex, italic = true })
  set(0, "@variable.parameter", { fg = p.gold.hex, italic = true })
  set(0, "@parameter",          { fg = p.gold.hex, italic = true })
  set(0, "@property",           { fg = p.cyan_warm.hex })
  set(0, "@field",              { fg = p.teal.hex })
  set(0, "@namespace",          { fg = p.cyan_cool.hex, italic = true })
  set(0, "@module",             { link = "@namespace" })

  set(0, "String",             { fg = p.green.hex })
  set(0, "@string",            { fg = p.green.hex })
  set(0, "@string.escape",     { fg = p.green_warm.hex, bold = true })
  set(0, "@string.special",    { fg = p.olive.hex, italic = true })
  set(0, "@string.regex",      { fg = p.olive.hex })
  set(0, "Character",          { fg = p.green_cool.hex })
  set(0, "@character",         { fg = p.green_cool.hex })
  set(0, "@character.special", { fg = p.amaranth.hex, bold = true })

  set(0, "Number",            { fg = p.orange.hex })
  set(0, "@number",           { fg = p.orange.hex })
  set(0, "Float",             { fg = p.orange_dark.hex })
  set(0, "@number.float",     { fg = p.orange_dark.hex })
  set(0, "Boolean",           { fg = p.yellow_cool.hex, bold = true })
  set(0, "@boolean",          { fg = p.yellow_cool.hex, bold = true })
  set(0, "Constant",          { fg = p.orange.hex })
  set(0, "@constant",         { fg = p.orange.hex })
  set(0, "@constant.builtin", { fg = p.yellow_cool.hex, bold = true })

  set(0, "Operator",    { fg = p.br_grey.hex })
  set(0, "@operator",   { fg = p.br_grey.hex })
  set(0, "Delimiter",   { fg = p.brown.hex })
  set(0, "Special",     { fg = p.cyan.hex })
  set(0, "SpecialChar", { fg = p.amaranth.hex, bold = true })

  set(0, "DiagnosticError", { fg = p.red_hot.hex })
  set(0, "DiagnosticWarn",  { fg = p.gold.hex })
  set(0, "DiagnosticInfo",  { fg = p.cyan_cool.hex })
  set(0, "DiagnosticHint",  { fg = p.blue_light.hex })
  set(0, "DiagnosticOk",    { fg = p.green.hex })

  set(0, "DiffAdd",    { fg = p.green.hex, bg = bg.mix(p.green, 12).hex })
  set(0, "DiffChange", { fg = p.gold.hex,  bg = bg.mix(p.gold, 12).hex })
  set(0, "DiffDelete", { fg = p.red.hex,   bg = bg.mix(p.red, 12).hex })
  set(0, "DiffText",   { fg = p.cyan.hex,  bg = bg.mix(p.cyan, 18).hex, bold = true })
end

-- Set the active style and re-apply.  Persists in vim.g so module reloads
-- (e.g. when wallpaper changes trigger ColorScheme) don't lose the choice.
function M.set_style(name)
  if not M.styles[name] then
    vim.notify("pywal_tweaks: unknown style '" .. tostring(name) .. "'",
      vim.log.levels.WARN)
    return
  end
  vim.g.pywal_tweaks_style = name
  M.apply()
  vim.notify("pywal style: " .. name, vim.log.levels.INFO)
end

function M.style_names()
  local names = vim.tbl_keys(M.styles)
  table.sort(names)
  return names
end

function M.current_style_name()
  return select(2, active_style())
end

-- Open a picker (vim.ui.select) to choose a style interactively.
function M.pick_style()
  vim.ui.select(M.style_names(), {
    prompt = "Pywal style (current: " .. M.current_style_name() .. ")",
  }, function(choice)
    if choice then M.set_style(choice) end
  end)
end

return M
