# zagclear

zagclear is a combination of a remote static library and a host executable that
allows for using [Cold Clear](https://github.com/MinusKelvin/cold-clear) on a
device that is either not supported by Rust or not powerful enough to run Cold
Clear itself, but can communicate with Rust-supported or stronger devices.

## Building

First, you'll want to build `cold-clear`. _TODO: how_

To build the Zig project, you will want to call
`zig build -Drelease-fast=true -Dhost-target=<host> -Dremote-target=<remote>`
where `<host>` and `<remote>` are LLVM triples. For example, if compiling on
Linux, and the intended host is 64-bit Windows, and the intended remote is
Nintendo Switch, you would install MinGW headers, set
`-Dhost-target=x86_64-windows-gnu`, and set
`-Dremote-target=aarch64-freestanding`.

## Usage

On the host, all you will have to do is run the executable Zig provides in
`zig-cache/bin`. For the remote, Zig will generate a static library in
`zig-cache/lib` and a header in `zig-cache/include`.