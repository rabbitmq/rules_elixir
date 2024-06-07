load("@rules_erlang//:erlang_app_info.bzl", "ErlangAppInfo", "flat_deps")
load("@rules_erlang//:util.bzl", "path_join")
load("@rules_erlang//private:util.bzl", "erl_libs_contents")

def _impl(ctx):
    ebin = ctx.actions.declare_directory(ctx.attr.dest)

    erl_libs_dir = ctx.label.name + "_deps"

    erl_libs_files = erl_libs_contents(
        ctx,
        target_info = None,
        headers = True,
        dir = erl_libs_dir,
        deps = flat_deps(ctx.attr.deps),
        ez_deps = ctx.files.ez_deps,
        expand_ezs = True,
    )

    env = {}
    if len(erl_libs_files) > 0:
        env["ERL_LIBS"] = path_join(
            ctx.bin_dir.path,
            ctx.label.workspace_root,
            ctx.label.package,
            erl_libs_dir,
        )

    env.update(ctx.attr.env)

    args = ctx.actions.args()
    args.add("-o")
    args.add(ebin.path)
    args.add_all(ctx.attr.elixirc_opts)
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        inputs = ctx.files.srcs + erl_libs_files,
        outputs = [ebin],
        executable = ctx.executable._compiler,
        mnemonic = "ELIXIRC",
        env = env,
        arguments = [args],
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
        "_compiler": attr.label(
            default = Label("//tools:elixirc"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)
