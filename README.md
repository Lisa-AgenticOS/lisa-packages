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

**The index is live** (first published 2026-08-03, carrying
`lisa-desktop`, `lisa-desktop-ime` and `lisa-apps` 0.1.0-1; verified
by a clean container that knew nothing but the `Server=` line below).
`publish.sh` + the `publish` workflow (manual dispatch) pull
`.pkg.tar.zst` assets from tagged releases of
`lisa-desktop`/`lisa-apps`/`lisa-os`, run `repo-add`, and publish the
index to this repo's rolling `current` release:

```ini
[lisa]
SigLevel = Optional TrustAll
Server = https://github.com/Lisa-AgenticOS/lisa-packages/releases/download/current
```

`SigLevel = Optional` is a stated gap, not a decision that signing is
unnecessary: signing needs a key-custody decision from the project
owner, tracked in lisa-os#171. The image build also still consumes the
locally built `file:///…` repo — switching it to this index is #171
step 4, deliberately separate so the old path keeps working until the
new one has shipped a release.

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
