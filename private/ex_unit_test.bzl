load("@bazel_skylib//lib:shell.bzl", "shell")
load(
    "@rules_erlang//:erlang_app_info.bzl",
    "ErlangAppInfo",
    "flat_deps",
)
load(
    "@rules_erlang//:util.bzl",
    "path_join",
)
load(
    "@rules_erlang//private:util.bzl",
    "erl_libs_contents",
)

def _package_relative_path(ctx, p):
    if ctx.label.package == "":
        return p
    return p.removeprefix(ctx.label.package + "/")

def _impl(ctx):
    copy_srcs_and_data_commands = [
        "mkdir -p $(dirname {dst}) && cp {src} {dst}".format(
            src = s.path,
            dst = path_join("${TEST_UNDECLARED_OUTPUTS_DIR}", _package_relative_path(ctx, s.path)),
        )
        for s in ctx.files.srcs + ctx.files.data
    ]

    erl_libs_dir = ctx.label.name + "_deps"

    erl_libs_files = erl_libs_contents(
        ctx,
        # target_info = None,
        # headers = True,
        deps = flat_deps(ctx.attr.deps),
        ez_deps = ctx.files.ez_deps,
        dir = erl_libs_dir,
        expand_ezs = True,
    )

    package = ctx.label.package

    erl_libs_path = path_join(package, erl_libs_dir)

    if not ctx.attr.is_windows:
        env = "\n".join([
            "export {}={}".format(k, v)
            for k, v in ctx.attr.env.items()
        ])
        output = ctx.actions.declare_file(ctx.label.name)
        script = """\
#!/usr/bin/env bash
set -eo pipefail

{copy_srcs_and_data_commands}

export ERL_LIBS=$TEST_SRCDIR/$TEST_WORKSPACE/{erl_libs_path}

cd ${{TEST_UNDECLARED_OUTPUTS_DIR}}

export HOME=${{PWD}}

{env}

{setup}

set -x
$TEST_SRCDIR/$TEST_WORKSPACE/{elixir} \\
    {elixir_opts} \\
    {srcs} | tee test.log
set +x
tail -n 4 test.log | grep -E --silent "0 failure"
tail -n 4 test.log | grep -E --silent "\\d test"
rm test.log
""".format(
            copy_srcs_and_data_commands = "\n".join(copy_srcs_and_data_commands),
            erl_libs_path = erl_libs_path,
            env = env,
            setup = ctx.attr.setup,
            elixir_opts = " ".join([shell.quote(opt) for opt in ctx.attr.elixir_opts]),
            elixir = ctx.executable._elixir.short_path,
            srcs = " \\\n    ".join([
                path_join("$TEST_SRCDIR", "$TEST_WORKSPACE", s.path)
                for s in ctx.files.srcs
            ]),
        )
    else:
        fail("not implemented")
        output = ctx.actions.declare_file(ctx.label.name + ".bat")
        script = """
"""

    ctx.actions.write(
        output = output,
        content = script,
    )

    runfiles = ctx.attr._elixir[DefaultInfo].default_runfiles
    runfiles = runfiles.merge_all(
        [
            ctx.runfiles([ctx.executable._elixir]),
            ctx.runfiles(ctx.files.srcs + ctx.files.data + erl_libs_files),
        ] + [
            tool[DefaultInfo].default_runfiles
            for tool in ctx.attr.tools
        ],
    )

    return [DefaultInfo(
        runfiles = runfiles,
        executable = output,
    )]

ex_unit_test = rule(
    implementation = _impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".exs"],
        ),
        "is_windows": attr.bool(mandatory = True),
        "data": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [ErlangAppInfo]),
        "ez_deps": attr.label_list(
            allow_files = [".ez"],
        ),
        "tools": attr.label_list(cfg = "target"),
        "env": attr.string_dict(),
        "setup": attr.string(),
        "elixir_opts": attr.string_list(),
        "_elixir": attr.label(
            default = Label("//tools:elixir"),
            allow_single_file = True,
            executable = True,
            cfg = "target",
        ),
    },
    test = True,
)
