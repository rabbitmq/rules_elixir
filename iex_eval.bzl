load(
    "//private:iex_eval.bzl",
    _iex_eval = "iex_eval",
)

def iex_eval(**kwargs):
    return _iex_eval(
        iex = Label("//tools:iex_wrapper"),
        **kwargs
    )
