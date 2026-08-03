# Python Project Environment Design

uv will use a visible `venv` directory in each project through the inherited
`UV_PROJECT_ENVIRONMENT=venv` environment variable. ty will use that same
directory through the user-level `$XDG_CONFIG_HOME/ty/ty.toml` configuration.

This replaces `workon`, its centralized environment-name hashing, and its
generated project-local Pyright, ty, and Pyrefly configuration files. Existing
project-local files are not modified automatically.
