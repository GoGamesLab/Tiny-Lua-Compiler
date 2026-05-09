local loadstring = (loadstring or load)
local tlc = require("tlc")

return function(suite)
  suite:describe("BytecodeEmitter", function()
    suite:it("matches the high-level compile API", function()
      local code = "local x = 1 + 2; return x"
      local proto = tlc.compileToProto(code)

      suite:assertEqual(tlc.compile(code), tlc.emit(proto))
    end)

    suite:it(
      "matches the high-level compile API for nested closures",
      function()
        local code = [[
        local function outer(x)
          return function(y)
            return x + y
          end
        end

        return outer(3)(4)
      ]]
        local proto = tlc.compileToProto(code)

        suite:assertEqual(tlc.compile(code), tlc.emit(proto))
      end
    )

    suite:it("emits the expected Lua 5.1 chunk header", function()
      local bytecode = tlc.compile("return 42")

      suite:assertEqual("\27Lua", bytecode:sub(1, 4))
      suite:assertEqual(0x51, string.byte(bytecode, 5))
      suite:assertEqual(0, string.byte(bytecode, 6))
      suite:assertEqual(1, string.byte(bytecode, 7))
      suite:assertEqual(4, string.byte(bytecode, 8))
      suite:assertEqual(8, string.byte(bytecode, 9))
      suite:assertEqual(4, string.byte(bytecode, 10))
      suite:assertEqual(8, string.byte(bytecode, 11))
      suite:assertEqual(0, string.byte(bytecode, 12))
    end)

    suite:it("returns a non-empty binary chunk", function()
      local bytecode = tlc.compile("return 'hello'")

      suite:assertEqual("string", type(bytecode))
      suite:assertEqual(false, bytecode == "")
    end)

    suite:itIf(
      _VERSION == "Lua 5.1",
      "loads emitted constants through the standard Lua loader",
      function()
        local bytecode = tlc.compile([[return 42, "ok", 3.5]])
        local func, err = loadstring(bytecode)
        if not func then
          error(err, 0)
        end

        suite:assertDeepEqual({ 42, "ok", 3.5 }, { func() })
      end,
      "requires a Lua 5.1 bytecode loader"
    )

    suite:itIf(
      _VERSION == "Lua 5.1",
      "preserves nested closures when loaded as bytecode",
      function()
        local bytecode = tlc.compile([[
          local function outer(x)
            return function(y)
              return x + y
            end
          end

          return outer(10)(5)
        ]])

        local func, err = loadstring(bytecode)
        if not func then
          error(err, 0)
        end

        suite:assertEqual(15, func())
      end,
      "requires a Lua 5.1 bytecode loader"
    )

    suite:itIf(
      _VERSION == "Lua 5.1",
      "preserves empty and multiline string constants",
      function()
        local bytecode = tlc.compile([=[return "", [[line1
line2]]]=])
        local func, err = loadstring(bytecode)
        if not func then
          error(err, 0)
        end

        suite:assertDeepEqual({ "", "line1\nline2" }, { func() })
      end,
      "requires a Lua 5.1 bytecode loader"
    )

    suite:itIf(
      _VERSION == "Lua 5.1",
      "preserves method declarations and implicit self in loaded bytecode",
      function()
        local bytecode = tlc.compile([[
          local t = {x = 10}
          function t:add(y)
            return self.x + y
          end
          return t:add(5)
        ]])
        local func, err = loadstring(bytecode)
        if not func then
          error(err, 0)
        end

        suite:assertEqual(15, func())
      end,
      "requires a Lua 5.1 bytecode loader"
    )
  end)
end
