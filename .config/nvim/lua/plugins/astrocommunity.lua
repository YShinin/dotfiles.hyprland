return {
  -- 1. Подключаем сам репозиторий AstroCommunity
  "AstroNvim/astrocommunity",
  -- 2. Сразу импортируем готовый пак для Python
  -- Это автоматически настроит Debugger, LSP и Formatter
  { import = "astrocommunity.pack.python" },
}
