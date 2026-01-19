return {
{
  "mfussenegger/nvim-dap-python",
  dependencies = "mfussenegger/nvim-dap",
  ft = "python", -- Грузим только для питона
  config = function(_, opts)
    -- Указываем путь к дебаггеру, который установил Mason
    local path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
    require("dap-python").setup(path)
  end,
},
}
