# neutron

Core API for ExpidusOS

## Multi-target Support

Neutron aims to be highly compatible and as it is currently in development,
we've made this list of working targets.

### Working

- `aarch64-linux-gnu`
- `aarch64-linux-musl`
- `arm-linux-musleabihf`
- `x86_64-linux-gnu`
- `x86_64-linux-musl`
- `riscv64-linux-musl`

### Partially Working

- `x86-windows-gnu` (**requires**: `-Ddocs=false`)
- `x86_64-windows-gnu` (**requires**: `-Ddocs=false`)
- `x86_64-macos-none` (**requires**: `-Ddocs=false`)
- `wasm32-freestanding-musl` (**requires**: `-Ddocs=false`)

### Broken

- `arm-linux-gnueabi` (**problem**: `blx` instruction used but not supported)
- `arm-linux-gnueabihf` (**problem**: static assert fails in libdrm)
- `arm-linux-musleabi` (**problem**: instruction requires armv5t)
- `arm-windows-gnu` (**problem**: functions use arm instructions but arm is not supported)
- `x86-linux-gnu` (**problem**: static assert fails in libdrm)
- `x86-linux-musl` (**problem**: `-fPIC` required but still causes issues)
- `x86_64-linux-gnux32` (**problem**: `-fPIC` required but still causes issues)
- `wasm32-wasi-musl` (**problem**: `wasm-ld: ~/.cache/zig/o/8b851326a8ea1aa1038ed95edb355938/libc.a(~/.cache/zig/o/375e64c994ce951a58e8e144063929cd/__main_void.o): undefined symbol: main`)
