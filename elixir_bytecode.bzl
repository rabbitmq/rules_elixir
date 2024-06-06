load("@rules_erlang//:erlang_app_info.bzl", "ErlangAppInfo", "flat_deps")
load("@rules_erlang//:util.bzl", "path_join")
load("@rules_erlang//private:util.bzl", "erl_libs_contents")
load(
    ":elixir_toolchain.bzl",
    "elixir_dirs",
    "erlang_dirs",
    "maybe_install_erlang",
)

def _impl(ctx):
    ebin = ctx.actions.declare_directory(ctx.attr.dest)

    (erlang_home, _, erlang_runfiles) = erlang_dirs(ctx)
    (elixir_home, elixir_runfiles) = elixir_dirs(ctx)

    erl_libs_dir = ctx.label.name + "_deps"

    erl_libs_files = erl_libs_contents(
        ctx,
        target_info = None,
        headers = True,
        dir = erl_libs_dir,
        deps = flat_deps(ctx.attr.deps),
        ez_deps = ctx.files.ez_deps,
    )

    erl_libs_path = ""
    if len(erl_libs_files) > 0:
        erl_libs_path = path_join(
            ctx.bin_dir.path,
            ctx.label.workspace_root,
            ctx.label.package,
            erl_libs_dir,
        )

    env = "\n".join([
        "export {}={}".format(k, v)
        for k, v in ctx.attr.env.items()
    ])

    script = """set -euo pipefail

{maybe_install_erlang}

if [[ "{elixir_home}" == /* ]]; then
    ABS_ELIXIR_HOME="{elixir_home}"
else
    ABS_ELIXIR_HOME=$PWD/{elixir_home}
fi

if [ -n "{erl_libs_path}" ]; then
    export ERL_LIBS={erl_libs_path}
fi

{env}

export PATH="{erlang_home}/bin:$PATH"
set -x
"{elixir_home}"/bin/elixirc \\
    -o {out_dir} \\
    {elixirc_opts} \\
    {srcs}
""".format(
        maybe_install_erlang = maybe_install_erlang(ctx),
        erlang_home = erlang_home,
        elixir_home = elixir_home,
        erl_libs_path = erl_libs_path,
        env = env,
        out_dir = ebin.path,
        elixirc_opts = " ".join(ctx.attr.elixirc_opts),
        srcs = " ".join([f.path for f in ctx.files.srcs]),
    )

    inputs = depset(
        direct = ctx.files.srcs + erl_libs_files,
        transitive = [
            erlang_runfiles.files,
            elixir_runfiles.files
        ],
    )

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [ebin],
        command = script,
        mnemonic = "ELIXIRC",
    )

    return [
        DefaultInfo(
            files = depset([ebin]),
        )
    ]

elixir_bytecode = rule(
    implementation = _impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".ex"],
        ),
        "elixirc_opts": attr.string_list(),
        "env": attr.string_dict(),
        "deps": attr.label_list(
            providers = [ErlangAppInfo],
        ),
        "ez_deps": attr.label_list(
            allow_files = [".ez"],
        ),
        "dest": attr.string(
            mandatory = True,
        ),
        # "ebin": attr.output(),
        # "consolidated": attr.output(),
    },
    toolchains = ["//bazel/elixir:toolchain_type"],
)
