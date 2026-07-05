# PROJECT KNOWLEDGE BASE

**Generated:** 2026-07-05T02:43:02Z  
**Commit:** 6ec48fa  
**Branch:** master  

## OVERVIEW
Flake that packages upstream SurrealDB linux-amd64 release tarballs as Nix derivations, plus a NixOS module (`services.surrealdb-bin`) that runs the binary as a systemd service. Version is user-selectable at build time via per-version manifest files. Stack: Nix flake + nixpkgs `stdenvNoCC` + `autoPatchelfHook`.

## STRUCTURE
```
surrealdb-nixos/
├── flake.nix            # flake outputs: per-system packages + nixosModules + a test VM
├── module.nix           # NixOS module: services.surrealdb-bin options + systemd service
├── lib/mkDerivation.nix # stdenvNoCC.mkDerivation factory: fetchzip + autoPatchelf the surreal binary
├── manifests/default.nix # attrset of ALL version keys → manifest imports (dual-key + shortcuts)
├── manifests/binary/     # one 4-line file per upstream release: { version, hash }
├── test-service.nix      # minimal config consumed by nixosConfigurations.vm
├── .envrc                # NIXPKGS_ALLOW_UNFREE=1 (direnv)
├── nixos.qcow2           # committed VM image (~7.6 MB, gitignored shape may vary)
└── result -> /nix/store/...-surrealdb-bin-3.0.5   # latest build symlink
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add a new SurrealDB version | `manifests/binary/<ver>.nix` + `manifests/default.nix` | see `./manifests/binary/AGENTS.md` |
| Change how the binary is fetched/patched | `lib/mkDerivation.nix` | only place that touches `fetchzip`/`autoPatchelfHook` |
| Add/change service options (bind, auth, TLS, timeouts, capabilities) | `module.nix` `options.services.surrealdb-bin` | mirror `surreal start` CLI flags |
| Change default `latest`/`latest_unstable`/major shortcuts | bottom of `manifests/default.nix` |
| Wire a new flake output / change systems | `flake.nix` | uses `flake-utils.eachDefaultSystem` |
| Test the module in a VM | `test-service.nix` + `nixosConfigurations.vm` in `flake.nix` |

## CODE MAP
Symbol/centrality via `nixd` document outline. Module boundary counts derived from `flake.nix` outputs.

| Symbol | Kind | Location | Role |
|--------|------|----------|------|
| `services.surrealdb-bin` (options) | NixOS option set | `module.nix:10` | `enable`, `package`, `bind`, `dataDir`, `tikvAddr`, `log`, `auth.{username,passwordFile,unauthenticated}`, `strict`, `queryTimeout`, `transactionTimeout`, `tls.{certFile,keyFile}`, `capabilities.{allow*,deny*}`, `importFile` |
| `config` (assertions + systemd) | `mkIf cfg.enable` block | `module.nix:144` | assertion: exactly one of `dataDir`/`tikvAddr`; `systemd.services.surrealdb` `script` assembles CLI args via `optionals` |
| `systemd.services.surrealdb.script` | shell script string | `module.nix:173` | builds `surreal start --log <lvl> <storage> [--password --strict --*-timeout --web-* --import-file --allow-* --deny-*]` |
| `mkComponent` | derivation factory | `lib/mkDerivation.nix` | `stdenvNoCC.mkDerivation` over `fetchzip` of `surrealdb/releases/download/v<ver>/surreal-v<ver>.linux-amd64.tgz` + `autoPatchelfHook` against `glibc`,`gcc-unwrapped` |
| `manifests` attrset | `import ./manifests` | `flake.nix` + `manifests/default.nix` | every key → `{version, hash}`; `mapAttrs` builds per-version packages |
| `nixosModules.default` / `nixosModules.surrealdb` | flake output | `flake.nix` | both alias `import ./module.nix` |
| `nixosModule` | legacy alias | `flake.nix` | backwards-compat single-module export |
| `nixosConfigurations.vm` | `nixosSystem` | `flake.nix` | `x86_64-linux`, imports `self.nixosModules.surrealdb` + `./test-service.nix` |

Centrality: module-cfg boundary is the load-bearing boundary (options → script → systemd). `manifests/default.nix` is the version registry that both `flake.nix` (build) and consumers (CLI keys) depend on. Reference-counting across the flake is structurally small (3 substantive files).

## CONVENTIONS (deviations from standard)
- **No `latest`/`latest_unstable` derivation logic** — they are literal extra keys in `manifests/default.nix` pointing at a chosen manifest file. Bump by editing the import target.
- **Dual-key aliasing**: every concrete version is published under both `x.y.z` and `x_y_z` (dots↔underscores). Underscore form is what `nix build .#x_y_z` accepts; dot form is what configs read. Both must be added together for every new version. Pre-release suffixes also alias dots↔underscores: `3.0.0-alpha.1` ↔ `3_0_0-alpha_1`.
- **Major/minor shortcut keys** (`"2"`, `"2.6"`, `"2_6"`, `"3"`, `"2.3"`, `"2_3"`) point at the latest patch file of their line. When you add a new patch you must repoint the shortcut to the new file.
- **Binary fetch URL is hardcoded** in `lib/mkDerivation.nix` to `linux-amd64` only; no per-arch manifest field. Adding a new arch means editing the factory, not the manifests.
- **`platforms = platforms.gnu`** in `mkDerivation.nix` meta — narrower than `platforms.linux`.
- **`fetchzip` is fed `version` AND `hash`** even though `version` is duplicated from the inner manifest attr; both come from the same `manifest` arg, kept in sync by hand.
- **Storage selection is assertion-enforced**, not option-defaulted: exactly one of `dataDir` (→ `rocksdb://`) or `tikvAddr` (→ `tikv://`) must be set. Both null OR both set fails the build.
- **`WorkingDirectory`/`StateDirectory`** differ when `dataDir` is non-null: `StateDirectory = "surrealdb"` (systemd-managed `/var/lib/surrealdb`) vs `WorkingDirectory = cfg.dataDir`. Read `module.nix:168-170` before touching state layout.

## ANTI-PATTERNS (THIS PROJECT)
- **Do not** add a manifest file without also registering BOTH keys (`x.y.z` and `x_y_z`) in `manifests/default.nix`. A bare file does nothing.
- **Do not** point a shortcut key (`"2"`, `"3"`, `"2.6"`, etc.) at a manifest that is not the latest patch of its line — that breaks the documented semantics.
- **Do not** set both `dataDir` and `tikivAddr` (or neither) — the `assertions` block in `module.nix:146-149` will fail evaluation.
- **Do not** rely on `pkgs.surrealdb` for anything other than the `package` option default; the actual packaged binary used by the service is whatever the consumer puts in `package` (the README example uses `inputs.surrealdb.packages.${system}.latest`). The flake does NOT set `package` for you.
- **Do not** edit `nixos.qcow2` by hand or expect it to be deterministic — it is a committed binary blob, `.gitignore` lists `*.qcow2` but the file is already tracked.
- **Do not** add a non-RocksDB/TiKV storage backend to the module without also extending the `dataDir`/`tikivAddr` assertion — currently only those two backends are wired (see README todo).

## UNIQUE STYLES
- Manifests are deliberately `{ version; hash; }` attrsets, not functions — `flake.nix` calls `mkDerivationSet {inherit (manifest) version hash;}` per entry.
- `mkDerivation.nix` exports a factory that takes `{version, hash}` and returns a `mkDerivation`; `self = mkComponent` self-reference is left in place (cosmetic).
- Service `script` is one big `concatStringsSep " "` of `optionals`-gated flag lists built from `cfg` — no helper module, no `lib.cli` style. New flags get appended in order.

## COMMANDS
```bash
# Build a specific version (underscore form required on CLI):
nix build .#3_0_5         # = ./result for the 3.0.5 binary
nix build .#latest        # alias defined in manifests/default.nix
nix build .#2_2           # shortcut to latest 2.2.x manifest

# Enter a dev shell / allow unfree (direnv reads .envrc):
NIXPKGS_ALLOW_UNFREE=1 nix develop

# Build the test VM defined in flake.nix:
nixos-rebuild build-vm --flake .#vm   # produces a runnable VM using test-service.nix

# Update flake inputs:
nix flake update   # bumps nixpkgs + flake-utils

# Evaluate and check the module alone:
nix eval .#nixosModules.surrealdb
```
> NOTE: requires Nix with flakes enabled; `flake-utils.eachDefaultSystem` means every system gets the same linux-amd64 tar (only meaningful on x86_64-linux).

## NOTES
- `result` is a tracked symlink into `/nix/store/...-surrealdb-bin-3.0.5` and will go stale as soon as anything rebuilds; treat as "last build pointer", not source of truth.
- README's `Current latest version:` / `Current latest_unstable version:` lines are the user-visible version-authoritative surface; `manifests/default.nix` is the build-authoritative surface. When `latest`/`latest_unstable` is repointed in `manifests/default.nix`, README MUST be updated to match in the same change — see `manifests/binary/AGENTS.md` step 6.
- `nixos.qcow2` is committed (~7.6 MB); `.gitignore` ignores `*.qcow2` going forward, not the existing one.
- Backlog (README todo): only RocksDB backend supported via `dataDir`, and no GitHub Action for auto version bumps.
- `flake.lock` pins `nixpkgs/nixos-unstable` @ `ba487db` and `numtide/flake-utils` @ `11707dc`.
