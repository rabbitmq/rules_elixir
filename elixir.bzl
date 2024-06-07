load(
    "//repositories:elixir_config.bzl",
    "INSTALLATION_TYPE_INTERNAL",
    _elixir_config = "elixir_config",
)

DEFAULT_ELIXIR_VERSION = "1.15.0"
DEFAULT_ELIXIR_SHA256 = "0f4df7574a5f300b5c66f54906222cd46dac0df7233ded165bc8e80fd9ffeb7a"

# Generates the @elixir_config repository, which contains erlang
# toolchains and platform defintions
def elixir_config(internal_elixir_configs = []):
    types = {c.name: INSTALLATION_TYPE_INTERNAL for c in internal_elixir_configs}
    versions = {c.name: c.version for c in internal_elixir_configs}
    urls = {c.name: c.url for c in internal_elixir_configs}
    strip_prefixs = {c.name: c.strip_prefix for c in internal_elixir_configs if c.strip_prefix}
    sha256s = {c.name: c.sha256 for c in internal_elixir_configs if c.sha256}

    _elixir_config(
        name = "elixir_config",
        types = types,
        versions = versions,
        urls = urls,
        strip_prefixs = strip_prefixs,
        sha256s = sha256s,
    )

def internal_elixir_from_http_archive(
        name = None,
        version = None,
        url = None,
        strip_prefix = None,
        sha256 = None):
    return struct(
        name = name,
        version = version,
        url = url,
        strip_prefix = strip_prefix,
        sha256 = sha256,
    )

def internal_elixir_from_github_release(
        name = "internal",
        version = DEFAULT_ELIXIR_VERSION,
        sha256 = DEFAULT_ELIXIR_SHA256):
    url = "https://github.com/elixir-lang/elixir/archive/refs/tags/v{}.tar.gz".format(
        version,
    )

    return internal_elixir_from_http_archive(
        name = name,
        version = version,
        url = url,
        strip_prefix = "elixir-{}".format(version),
        sha256 = sha256,
    )
