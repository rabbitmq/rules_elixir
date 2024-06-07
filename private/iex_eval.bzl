def _impl(ctx):
    args = ctx.actions.args()
    args.add("--eval")
    args.add(ctx.attr.expression)

    ctx.actions.run(
        inputs = ctx.files.srcs,
        outputs = ctx.outputs.outs,
        executable = ctx.executable._iex,
        mnemonic = "IEX",
        env = {
            "SRCS": ctx.configuration.host_path_separator.join([
                src.path
                for src in ctx.files.srcs
            ]),
            "OUTS": ctx.configuration.host_path_separator.join([
                out.path
                for out in ctx.outputs.outs
            ]),
        },
        arguments = [args],
    )

iex_eval = rule(
    implementation = _impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "outs": attr.output_list(),
        "expression": attr.string(
            mandatory = True,
        ),
        "_iex": attr.label(
            default = Label("//tools:iex"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)
