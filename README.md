<div align="center">

![Tiny Lua Compiler (TLC)](https://github.com/bytexenon/Tiny-Lua-Compiler/assets/125568681/41cf5285-e31d-4b27-a8a8-ee83a7300f1f)

**An educational Lua 5.1 compiler, bytecode emitter, and VM in one Lua file**

_Inspired by [Jamie Kyle's The Super Tiny Compiler](https://github.com/jamiebuilds/the-super-tiny-compiler)_

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Lua](https://img.shields.io/badge/Lua-5.1--5.5-blue)

</div>

**_Tiny Lua Compiler (TLC)_** is a complete Lua 5.1 compiler written in pure Lua.
It tokenizes source code, builds an AST (Abstract Syntax Tree), lowers it into
Lua 5.1 function prototypes, emits real Lua 5.1 bytecode, and can execute those
prototypes in its own register-based VM. The whole core lives in [tlc.lua](tlc.lua).

Most compiler learning material falls into one of two buckets. On one side are
toy compilers that are easy to finish but skip the parts that make real
languages interesting. On the other are production compilers that are real, but
so large that the main ideas get buried under architecture and history. TLC is
meant to sit in the middle. It is small enough that you can read it in a
weekend, but real enough to deal with lexical scoping, closures, upvalues,
varargs, multiple returns, method calls, loops, tail calls, bytecode encoding,
and execution.

It is not a production compiler, and it is not trying to replace the standard
Lua implementation. It is an educational compiler that tries to stay honest:
small enough to understand, complete enough to be worth studying.

## It can compile itself

TLC can compile its own source code and run the result inside its own VM:

```lua
local tlc  = require("tlc")
local tlc2 = tlc.run(io.open("tlc.lua"):read("*a"))
tlc2.run("print('Hello from a compiler running inside itself')")
```

That means a compiler written in Lua is compiling a compiler written in Lua,
and then the compiled compiler is running new Lua code, all without leaving
the host process.

## Try it

```bash
git clone https://github.com/bytexenon/Tiny-Lua-Compiler.git
cd Tiny-Lua-Compiler

# Run the code inside TLC's own VM.
lua5.1 -e "require('tlc').run(\"print('Hello from TLC!')\")"

# Compile to a binary .luac chunk and run it with the standard Lua VM.
lua5.1 -e "io.open('out.luac','wb'):write(require('tlc').compile('print(42)'))"
lua5.1 out.luac

lua5.1 tests/test.lua
```

You can also use TLC as a library, at whatever level of detail you need:

```lua
local tlc = require("tlc")

-- One-liner: compile and run.
tlc.run("print('Hello from TLC!')")

-- Compile to a binary .luac chunk that the standard Lua VM can load.
local bytecode = tlc.compile("return 21 * 2")
-- io.open("out.luac", "wb"):write(bytecode) -- Save to disk if you want.

-- Walk the pipeline stage by stage.
local tokens = tlc.tokenize("local x = 1 + 2; return x")
local ast    = tlc.parseTokens(tokens)
local proto  = tlc.generate(ast)
local value  = tlc.execute(proto)

print(value) -- 3
```

## Why this file is worth reading

The code runs in a straight line. Utilities first, then the tokenizer, the
parser, the code generator, the bytecode emitter, the VM, and the public API -
in that order, nothing out of place. You can trace a single source program
through every stage without losing the thread.

The implementation also keeps the details that toy compilers skip. Character
classification uses precomputed lookup tables. Operator matching uses a trie for
longest-prefix matching - no hand-rolled lookahead. Expressions go through
precedence climbing rather than a grammar rule per level. Concatenation chains
are flattened into a single `CONCAT`. Floating-point numbers are packed to
IEEE 754 by hand, without `string.pack`. Upvalue capture and `OP_CLOSE` are
handled explicitly.

These are not polish. They are where real compiler behavior starts to show up.
Skip them and you learn the shape of compilation. Keep them and you learn how
it actually works.

## What TLC covers, and what it does not

TLC covers a large enough slice of Lua 5.1 to feel real:

- Lexical scoping, closures, upvalue capture and closing
- Numeric and generic `for`, `while`, `repeat`, `do`, `break`, `return`
- `if` / `elseif` / `else`
- Method calls (`:` syntax), table constructors
- Multiple returns, varargs (`...`), tail call optimization
- Long strings, string escapes, hex numbers, scientific notation
- Full Lua 5.1 bytecode emission - output loads in the standard VM

What it deliberately leaves out is just as important. No constant folding. No
debug information - that is the table mapping each instruction to a source line;
without it, error messages show no line numbers, but the bytecode is otherwise
correct.

The biggest omission is metamethod dispatch. Write `a + b` when `a` is a table
and standard Lua checks for `__add`. TLC's VM skips this entirely - operators
work only on native types. That removes a real feature, but it keeps the VM
from becoming an object system.

The tradeoff is deliberate. TLC is trying to be a real compiler you can
actually finish reading.

## Correctness

The test suite compiles each case with both TLC and standard Lua, then compares
the results side by side. No mock expectations - if TLC produces different
output, the test fails.

This catches the mistakes educational compilers usually get away with: wrong
operator precedence, broken closure semantics, multi-return adjustment errors,
loop control flow bugs, and incorrect literal parsing, among others.

## API

```lua
local tlc = require("tlc")

tlc.run(code, env?, ...?)
tlc.compile(code)
tlc.compileToProto(code)
tlc.parse(code)
tlc.tokenize(code)

tlc.parseTokens(tokens)
tlc.generate(ast)
tlc.emit(proto)
tlc.execute(proto, env?, ...?)
```

[docs/api.md](docs/api.md) documents the public API and
[docs/ast.md](docs/ast.md) documents the AST shape.

## Where to start

Read this file for the big picture, then read [tlc.lua](tlc.lua) from top to
bottom. After that, [docs/api.md](docs/api.md) and [docs/ast.md](docs/ast.md)
fill in the reference material, and [tests](tests) show the behavioral surface
area.

TLC runs on Lua 5.1 through 5.5, although the generated bytecode targets Lua
5.1.

Contributions are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). If you
report a bug, please include the input code, expected behavior, actual
behavior, and Lua version.

## See also

- [The Super Tiny Compiler](https://github.com/jamiebuilds/the-super-tiny-compiler) - the original inspiration; a compiler written in JavaScript in ~200 lines
- [FiOne](https://github.com/Rerumu/FiOne) - a Lua-in-Lua VM, more complete than TLC's but less focused on readability
- [Lua 5.1 source](https://www.lua.org/source/5.1/) - the reference implementation; `llex.c`, `lparser.c`, and `lvm.c` are the most relevant files

## License

MIT. See [LICENSE](LICENSE).
