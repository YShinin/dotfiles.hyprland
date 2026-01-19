return {
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = { "neovim/nvim-lspconfig", "mfussenegger/nvim-dap", "mfussenegger/nvim-dap-python" },
    opts = {
      -- Настройки поиска venv (обычно ищет в папке проекта или в ~/.virtualenvs)
      name = { "venv", ".venv" }, 
      -- Автоматически перезапускать LSP и дебаггер при смене окружения
      dap_enabled = true,
    },
    keys = {
      -- Хоткей: <Leader>lv (LSP -> Venv)
      { "<leader>lv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
  },
}
