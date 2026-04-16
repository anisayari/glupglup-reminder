#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

"$ROOT_DIR/Scripts/install_app.sh"

echo
read -k 1 "?Installation terminee. Appuie sur une touche pour fermer..."
