#!/bin/zsh
set -e
cargo build --release
cp target/release/tui tui
codesign --force --deep --sign - tui
cargo clean -q
echo "✓ tui built and signed"
