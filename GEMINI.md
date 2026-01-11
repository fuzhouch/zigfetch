# Project: Zig fetch command line tool

## General instruction

- Ensure the generated code compiles with Zig compiler version 0.15.2.
- Don't edit build.zig and build.zig.zon. They are maintainted by developers.
- Ensure no external dependency is added to build.zig.zon.
- Unit tests are added to main.zig.
- Main application entry point is in main.zig.

## Coding style

- Use zig fmt command line to maintain coding style.

## Specification

The command line application is named as ``zf``. It supports the following
command line as an example:

```
    zf fetch https://github.com/Hejsil/zig-clap/archive/refs/tags/0.11.0.zip
    zf fetch --save https://github.com/Hejsil/zig-clap/archive/refs/tags/0.11.0.zip
```

The zf command line does the following functions:

- Download the package from Internet by given URL. We assume 
  the package refers to a source code release of a 3rd 
  party dependency.
- Extract the package to zig's local cache.
- If ``--save`` is specified, update the build.zig.zon in the current
  directory if it exists. When updating build.zig.zon, it adds the given
  URL as a dependency recognized by zig.
