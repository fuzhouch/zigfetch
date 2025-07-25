# ZF stands for Zig Fetch

This is an external tool to download Zig dependencies from Internet
and build local build cache. The motivation is to allow I download
dependencies when working on an environment that can't access Github
easily.

There are existing similar tools like
[zigfetch](https://zigcli.liujiacai.net/programs/zigfetch/) or
[zig-fetch-py](https://github.com/crosstyan/zig-fetch-py), they
do not always as expected.

[zigfetch](https://zigcli.liujiacai.net/programs/zigfetch/) tries to
solve the problem but it has a dependency to libCurl which is stuck
again. Sometimes I'm lucky to get Github randomly accessible, while
in most cases I have to download
[zig-fetch-py](https://github.com/crosstyan/zig-fetch-py) again.

[zig-fetch-py](https://github.com/crosstyan/zig-fetch-py) tries a
hardcore approach. It creates a Zon file parser written in
Python code, and try to mimic behavior of local cache behavior.
It works in most of the cases, with a small but annoying problem: it
skips downloading if hash is incorrect. This behavior blocks an
important trick for original ``zig fetch`` command when adding a new
dependency: we internally add a wrong hash to force ``zig fetch``
to tell us the correct hash.

I want to build a ``zig fetch`` tool without any external dependency,
so I can download and use it directly.

This effort may fail due to
[Issue 19878](https://github.com/ziglang/zig/issues/19878), but let's
see.
