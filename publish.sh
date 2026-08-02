#!/usr/bin/env bash
# Rebuild the [lisa] index from a directory of packages and publish it
# as assets on this repo's rolling "current" release.
#
# Run on Arch (repo-add ships in pacman) with gh authenticated.
# Usage: publish.sh <dir-with-pkg.tar.zst>
#
# Why a rolling release and not gh-pages: pacman needs plain HTTPS GETs
# with byte ranges, which GitHub release assets serve; a git branch
# full of .pkg.tar.zst blobs grows without bound and can never be
# force-pruned safely once mirrors exist.
#
# The index this publishes is what the consumer line points at:
#
#   [lisa]
#   SigLevel = Optional TrustAll
#   Server = https://github.com/Lisa-AgenticOS/lisa-packages/releases/download/current
#
# SigLevel Optional is a STATED GAP, not a decision that signing is
# unnecessary: package signing needs a key custody decision from the
# project owner (where the private key lives, who holds it), which a
# script must not improvise. Tracked in lisa-os#171 step 3.
set -euo pipefail

dir=${1:?usage: publish.sh <dir-with-packages>}
tag=current

ls "$dir"/*.pkg.tar.zst >/dev/null  # fail loudly on an empty input

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp "$dir"/*.pkg.tar.zst "$work/"

# --new: keep only the newest version of each package in the db.
repo-add --new "$work/lisa.db.tar.gz" "$work"/*.pkg.tar.zst
# repo-add already leaves "lisa.db"/"lisa.files" as SYMLINKS to the
# tarballs; release assets cannot be symlinks, so replace them with
# real copies. (A plain cp follows the link and dies on "same file" —
# that failed the first publish run.)
rm "$work/lisa.db" "$work/lisa.files"
cp "$work/lisa.db.tar.gz" "$work/lisa.db"
cp "$work/lisa.files.tar.gz" "$work/lisa.files"

if ! gh release view "$tag" >/dev/null 2>&1; then
    gh release create "$tag" --title "[lisa] package index" \
        --notes "Rolling pacman repo. Do not download by hand — point pacman at it (see README)."
fi
# --clobber: same-name assets are replaced, so the index is atomic per
# file; pacman re-fetches the db before any package, so a client sees
# either the old index or the new one, never a torn mix.
gh release upload "$tag" --clobber \
    "$work/lisa.db" "$work/lisa.db.tar.gz" \
    "$work/lisa.files" "$work/lisa.files.tar.gz" \
    "$work"/*.pkg.tar.zst

echo ">> published $(ls "$work"/*.pkg.tar.zst | wc -l) packages to the '$tag' release"
