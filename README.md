# lisa-packages — the `[lisa]` package index

The pacman repository for [Lisa OS](https://github.com/Lisa-AgenticOS/lisa-os):
the single place where packages built by `lisa-os`, `lisa-desktop` and
`lisa-apps` are indexed, signed and published, and the layer that sits
on top of a pinned Arch snapshot mirror (PLAN §3's packaging
economics; ADR-0039).

## What it does

We do not write a package manager — we populate one. Each source repo
carries its own PKGBUILD next to the code it builds; this repo holds
the **index**: `repo-add` output (`lisa.db`), the signing key policy,
and the publishing workflow.

```
lisa-desktop ─┐
lisa-apps    ─┼─→ each repo builds its package on tag
lisa-os      ─┘
                    │
                    ▼
          lisa-packages: repo-add → [lisa], sign, publish
                    │
       ┌────────────┴─────────────┐
       ▼                          ▼
 Track L: pacman -S on       Track I: mkosi pulls [lisa]
 stock Arch/Omarchy          at image build
```

Consumers add:

```ini
[lisa]
Server = <not yet published — see Status>
```

## Status, honestly

**Nothing is hosted yet.** Today the `[lisa]` repo is built locally by
`os/repo-tools/build-packages.sh` in `lisa-os` and consumed as
`Server = file:///…` during image builds. This repo exists so that
stops being one developer's `out/` directory; the publishing pipeline
is the next deliverable, and this README will carry the real `Server=`
line only when it exists (no invented URLs — CLAUDE.md rule 8).

## How to extend it

A new package = a PKGBUILD in the repo that owns the source, plus a
publish step here. Binding rules from `lisa-os`: the install/update/
recovery paths may not depend on infrastructure we do not control
beyond what release artifacts already use (ADR-0034); the Arch base
underneath `[lisa]` is a pinned snapshot we move deliberately.

## Limits

- No hosted index, no signing key, no CI — this is the seed commit.
- The mirror-of-last-resort question (GitHub unreachable) is open and
  tracked in ADR-0039, not solved here.
