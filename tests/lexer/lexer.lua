local tlc = require("tlc")

return function(suite)
  local function assertTokens(source, expected)
    suite:assertDeepEqual(expected, tlc.tokenize(source))
  end

  suite:describe("Tokenizer", function()
    suite:describe("Token shapes", function()
      suite:it(
        "tokenizes keywords, identifiers, punctuation, and EOF",
        function()
          assertTokens("local answer = foo.bar[2]", {
            { kind = "Keyword", value = "local" },
            { kind = "Identifier", value = "answer" },
            { kind = "Equals" },
            { kind = "Identifier", value = "foo" },
            { kind = "Dot" },
            { kind = "Identifier", value = "bar" },
            { kind = "LeftBracket" },
            { kind = "Number", value = 2, raw = "2" },
            { kind = "RightBracket" },
            { kind = "EOF" },
          })
        end
      )

      suite:it(
        "distinguishes keywords from similarly named identifiers",
        function()
          assertTokens("and and_then _and end_", {
            { kind = "Keyword", value = "and" },
            { kind = "Identifier", value = "and_then" },
            { kind = "Identifier", value = "_and" },
            { kind = "Identifier", value = "end_" },
            { kind = "EOF" },
          })
        end
      )

      suite:it(
        "keeps numeric raw text while converting numeric values",
        function()
          assertTokens("0x2p3 .125 1. 5e-1", {
            { kind = "Number", value = 16, raw = "0x2p3" },
            { kind = "Number", value = 0.125, raw = ".125" },
            { kind = "Number", value = 1, raw = "1." },
            { kind = "Number", value = 0.5, raw = "5e-1" },
            { kind = "EOF" },
          })
        end
      )

      suite:it("tokenizes complex numeric values", function()
        assertTokens("6.022e23 1.e3 .5e-1", {
          { kind = "Number", value = 6.022e23, raw = "6.022e23" },
          { kind = "Number", value = 1000, raw = "1.e3" },
          { kind = "Number", value = 0.05, raw = ".5e-1" },
          { kind = "EOF" },
        })
      end)

      suite:it(
        "tokenizes short strings and resolves escape sequences",
        function()
          assertTokens([=["\65\n" 'ok']=], {
            { kind = "String", value = "A\n" },
            { kind = "String", value = "ok" },
            { kind = "EOF" },
          })
        end
      )

      suite:it(
        "tokenizes long strings and skips the opening newline",
        function()
          assertTokens("[[\nhello]] [=[world]=]", {
            { kind = "String", value = "hello" },
            { kind = "String", value = "world" },
            { kind = "EOF" },
          })
        end
      )

      suite:it("prefers the longest matching symbolic operator", function()
        assertTokens("... .. . ~= == <= >=", {
          { kind = "Vararg" },
          { kind = "Operator", value = ".." },
          { kind = "Dot" },
          { kind = "Operator", value = "~=" },
          { kind = "Operator", value = "==" },
          { kind = "Operator", value = "<=" },
          { kind = "Operator", value = ">=" },
          { kind = "EOF" },
        })
      end)

      suite:it(
        "distinguishes decimal-start numbers from standalone dots",
        function()
          assertTokens(".5 . .. ...", {
            { kind = "Number", value = 0.5, raw = ".5" },
            { kind = "Dot" },
            { kind = "Operator", value = ".." },
            { kind = "Vararg" },
            { kind = "EOF" },
          })
        end
      )

      suite:it("skips short comments, long comments, and whitespace", function()
        assertTokens(
          [==[
          local x = 1 -- short comment
          --[=[ long comment ]=]
          return x
        ]==],
          {
            { kind = "Keyword", value = "local" },
            { kind = "Identifier", value = "x" },
            { kind = "Equals" },
            { kind = "Number", value = 1, raw = "1" },
            { kind = "Keyword", value = "return" },
            { kind = "Identifier", value = "x" },
            { kind = "EOF" },
          }
        )
      end)

      suite:it(
        "handles long comments with nested-looking delimiters",
        function()
          assertTokens(
            [===[
          --[==[
            fake nested comment start --[[ still inside outer ]]
          ]==]
          return 42
        ]===],
            {
              { kind = "Keyword", value = "return" },
              { kind = "Number", value = 42, raw = "42" },
              { kind = "EOF" },
            }
          )
        end
      )

      suite:it("handles comments at EOF without a trailing newline", function()
        assertTokens("return 1 -- no newline", {
          { kind = "Keyword", value = "return" },
          { kind = "Number", value = 1, raw = "1" },
          { kind = "EOF" },
        })
      end)
    end)

    suite:describe("Errors", function()
      suite:it("errors on unterminated short strings", function()
        suite:assertError(function()
          tlc.tokenize([["hello]])
        end, "Unclosed string")
      end)

      suite:it("errors on unterminated long comments", function()
        suite:assertError(function()
          tlc.tokenize("--[[ nope")
        end, "Unclosed long comment")
      end)

      suite:it("errors on malformed hexadecimal numbers", function()
        suite:assertError(function()
          tlc.tokenize("0xG1")
        end, "malformed number")
      end)

      suite:it("errors on out-of-range numeric escapes", function()
        suite:assertError(function()
          tlc.tokenize([["\256"]])
        end, "escape sequence too large")
      end)
    end)
  end)
end
