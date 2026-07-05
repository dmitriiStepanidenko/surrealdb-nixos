# manifests/binary

One file per upstream SurrealDB release. Each file is a 4-line attrset, no functions:

```nix
{
  version = "<x.y.z>";
  hash = "sha256-...";
}
```

## INVARIANT
- Filename MUST equal the `version` field (with pre-release suffixes verbatim). `2.3.10.nix` → `version = "2.3.10"`; `3.0.0-alpha.1.nix` → `version = "3.0.0-alpha.1"`.
- `version` is consumed by `lib/mkDerivation.nix` to build the GitHub release URL — never abbreviate or rewrite it.
- `hash` is the `fetchzip` SRI hash; obtain with `nix-prefetch-url --unpack --type sha256 <tarball> | nix hash to-sri --type sha256`.
- Linux-amd64 tar only — every file here backs the same hardcoded arch in `lib/mkDerivation.nix`.

## ADD A NEW VERSION (recipe)
1. Add a new file here named `<version>.nix` filled with the 4-line invariant above.
2. Register the file in `../default.nix` as a dual-key pair:
   ```nix
   "<version>" = import ./binary/<version>.nix;
   "<underscore-version>" = import ./binary/<version>.nix;
   ```
   - Pre-release suffixes alias dots↔underscores: `3.0.0-alpha.1` ↔ `3_0_0-alpha_1`.
3. If this is a new patch of an existing line, repoint the major/minor shortcut (`"2"`, `"2.6"`, `"2_6"`, `"3"`, ...) to your new file.
4. If it should be the new default, repoint `latest` (and `latest_unstable` for betas/alphas) at the bottom of `../default.nix`.
5. Run `nix build .#<underscore-version>`; on hash mismatch update the `hash` field.
   - On current `nix` (>=2.34) `nix-prefetch-url --unpack --type sha256` does NOT reproduce `fetchzip`'s nar hash. Use the fake-hash → got extraction instead: set `hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";` in the manifest, run `nix build .#<underscore-version>`, fetchzip will fail and print `got: sha256-...` — paste that SRI hash back into the manifest and rebuild to confirm.
6. If you repointed `latest` or `latest_unstable` in step 4, also update `README.md` so its `Current latest version:` / `Current latest_unstable version:` lines match the new targets. README is the user-visible version-authoritative surface; `manifests/default.nix` is the build-authoritative surface — both must stay in sync.

## ANTI-PATTERNS
- Do NOT commit a `.nix` file here without also registering BOTH keys in `../default.nix` — the build won't pick it up.
- Do NOT name files without matching their `version` field — the dispatcher maps by hand, not by glob.
- Do NOT put `hash = lib.fakeHash` or leave it empty; `fetchzip` will fail at build time with a mismatch error.
