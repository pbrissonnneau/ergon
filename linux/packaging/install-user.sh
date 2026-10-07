#!/usr/bin/env sh
# Installs a built Overdue bundle for the current user only (no root needed).
#   flutter build linux --release && linux/packaging/install-user.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
bundle="$here/../../build/linux/x64/release/bundle"
dest="${XDG_DATA_HOME:-$HOME/.local/share}"
mkdir -p "$dest/overdue" "$HOME/.local/bin" "$dest/applications"
cp -r "$bundle"/. "$dest/overdue/"
ln -sf "$dest/overdue/overdue" "$HOME/.local/bin/overdue"
sed "s|^Exec=overdue|Exec=$dest/overdue/overdue|" "$here/app.overdue.overdue.desktop" > "$dest/applications/app.overdue.overdue.desktop"
echo "Installed to $dest/overdue (launcher: $dest/applications/app.overdue.overdue.desktop)"
