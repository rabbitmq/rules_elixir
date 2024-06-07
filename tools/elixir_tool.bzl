load(
    "//private:elixir_toolchain.bzl",
    "elixir_dirs",
    "erlang_dirs",
    "maybe_install_erlang",
)

def _impl(ctx):
    (erlang_home, _, erlang_runfiles) = erlang_dirs(ctx)
    (elixir_home, elixir_runfiles) = elixir_dirs(ctx)

    script = """\
#!/usr/bin/env bash

set -euo pipefail

{maybe_install_erlang}

exec \\
    env PATH="{erlang_home}/bin:$PATH" \\
    "{elixir_home}"/bin/{tool} $@
""".format(
        maybe_install_erlang = maybe_install_erlang(ctx),
        erlang_home = erlang_home,
        elixir_home = elixir_home,
        tool = ctx.attr.tool,
    )

    ctx.actions.write(
        output = ctx.outputs.out,
        content = script,
        is_executable = True,
    )

    runfiles = erlang_runfiles.merge(elixir_runfiles)

    return [
        DefaultInfo(
            runfiles = runfiles,
            executable = ctx.outputs.out,
        ),
    ]

elixir_tool = rule(
    implementation = _impl,
    attrs = {
        "tool": attr.string(
            mandatory = True,
        ),
        "out": attr.output(
            mandatory = True,
        ),
    },
    toolchains = ["//:toolchain_type"],
    executable = True,
)
