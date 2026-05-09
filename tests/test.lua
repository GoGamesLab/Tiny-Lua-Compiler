local Suite = require("tests.library")

local suite = Suite.new()
local modules = {
  "tests.lexer.lexer",
  "tests.parser.parser",
  "tests.bytecode_emitter.bytecode_emitter",
  "tests.language.semantics",
}

for _, moduleName in ipairs(modules) do
  require(moduleName)(suite)
end

os.exit(suite:summary())
