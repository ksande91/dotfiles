local function reload_tweaks()
  package.loaded["pywal_tweaks"] = nil
  return require("pywal_tweaks")
end

return {
  { "rktjmp/lush.nvim", lazy = false, priority = 1000 },

  {
    "oncomouse/lushwal.nvim",
    dependencies = { "rktjmp/lush.nvim", "rktjmp/shipwright.nvim" },
    lazy = false,
    priority = 1000,
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "lushwal",
        callback = function() reload_tweaks().apply() end,
      })

      vim.api.nvim_create_user_command("PywalStyle", function(opts)
        local tweaks = reload_tweaks()
        if opts.args == nil or opts.args == "" then
          tweaks.pick_style()
        else
          tweaks.set_style(opts.args)
        end
      end, {
        nargs = "?",
        complete = function()
          return reload_tweaks().style_names()
        end,
        desc = "Pick or set the pywal_tweaks style (saturated/muted/etc)",
      })

      vim.api.nvim_create_user_command("PywalApply", function()
        reload_tweaks().apply()
      end, { desc = "Re-apply pywal_tweaks overrides" })
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "lushwal" },
  },
}
