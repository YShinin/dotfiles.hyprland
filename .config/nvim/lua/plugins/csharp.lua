-- -- костыль для си шарпа
-- -- требует в указанной локации собранный csharp-language-server из 11й версии
return {
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      -- Явно говорим AstroLSP, какие серверы активировать
      servers = { "csharp_ls" },
      config = {
        csharp_ls = {
          -- Убедись, что путь и регистр (CSharpLanguageServer) совпадают
          cmd = { "/home/yshine/csharp-language-server/publish/CSharpLanguageServer" },
          -- Функция для поиска корня проекта
          root_dir = function(fname)
            local util = require "lspconfig.util"
            return util.root_pattern("*.sln", "*.csproj", ".git")(fname)
          end,
        },
      },
    },
  },
}
