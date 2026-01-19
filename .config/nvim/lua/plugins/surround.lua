return {
  {
    "kylechui/nvim-surround",
    version = "*", -- Использовать стабильную версию
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup({
            -- Здесь можно настроить, но дефолт идеален
        })
    end,
  },
}
