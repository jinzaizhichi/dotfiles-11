#!/usr/bin/env bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT

mkdir -p \
    "$test_dir/config/ty" \
    "$test_dir/home" \
    "$test_dir/project/venv/lib/python3.12/site-packages/example_dependency"
ln -s "$repo/configs/xdg/ty/ty.toml" "$test_dir/config/ty/ty.toml"

printf 'home = /usr/bin\nversion = 3.12.3\n' \
    >"$test_dir/project/venv/pyvenv.cfg"
printf 'value: int = 1\n' \
    >"$test_dir/project/venv/lib/python3.12/site-packages/example_dependency/__init__.pyi"
printf 'from example_dependency import value\nresult: int = value\n' \
    >"$test_dir/project/example.py"

project_environment="$({
    HOME="$test_dir/home" sh -c '. "$1"; printf "%s" "$UV_PROJECT_ENVIRONMENT"' \
        sh "$repo/configs/home/profile"
})"
test "$project_environment" = venv
ty_bin="$(mise which ty)"

(
    cd "$test_dir/project"
    XDG_CONFIG_HOME="$test_dir/config" "$ty_bin" check
)
