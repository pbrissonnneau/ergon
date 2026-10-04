#!/usr/bin/env sh
# Installs a built Ergon bundle for the current user only (no root needed).
#   flutter build linux --release && linux/packaging/install-user.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
bundle="$here/../../build/linux/x64/release/bundle"
dest="${XDG_DATA_HOME:-$HOME/.local/share}"
mkdir -p "$dest/ergon" "$HOME/.local/bin" "$dest/applications"
cp -r "$bundle"/. "$dest/ergon/"
ln -sf "$dest/ergon/ergon" "$HOME/.local/bin/ergon"
sed "s|^Exec=ergon|Exec=$dest/ergon/ergon|" "$here/app.ergon.ergon.desktop" > "$dest/applications/app.ergon.ergon.desktop"
echo "Installed to $dest/ergon (launcher: $dest/applications/app.ergon.ergon.desktop)"
