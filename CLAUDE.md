# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Standalone Bash installers for SQream / Scailium DB, copied onto a customer's RHEL 7/8/9 server and run there as root. There is no build system, no test suite, no CI, no dependencies inside the repo — every script is a single self-contained file that is edited and committed directly.

| Path | Purpose |
|---|---|
| `Scailium_Engine/scailium-install-v1.sh` | Main engine installer (~5.5k lines). On-prem, AWS, OCI, MIG, metadata-only, CBO, Iceberg, upgrade, reconfigure. |
| `Scailium_Engine/scailium-services` | logrotate config for `/var/log/sqream/*.log`; must be copied to `/etc/logrotate.d/` manually. |
| `Pacemaker/pcs_sqream_installer_V1.sh` | HA variant: same install flow plus Pacemaker/corosync cluster setup, node join/remove, worker add/delete. |
| `UI/sq-studio-install.sh` | SQream Studio (Node/PM2) installer + optional nginx HTTPS proxy. |
| `diag-sqream-v1.sh` | Read-only-ish host diagnostic (user, shell, sudoers, groups, limits, core dump path). Runs top-to-bottom, no flags. |

## Working on the scripts

There is nothing to build. Validation is manual:

```bash
bash -n Scailium_Engine/scailium-install-v1.sh   # syntax check — do this after every edit
sudo ./Scailium_Engine/scailium-install-v1.sh -h # regenerate/verify the help text
```

`shellcheck` is not installed and the code would not pass it (unquoted vars, `sudo` inside already-root scripts, no `set -e`); do not "fix" style repo-wide.

The scripts cannot be exercised locally: they require root, `nvidia-smi`, a RHEL package manager, a real `*.tar.gz` SQream package, and they block on interactive `read` prompts throughout. Verification is by reading the flow and by syntax check, not by running.

## Anatomy of an installer script

All four scripts share one shape:

1. Globals at the top (`LOG_FILE`, `today`, colors) and a `logit()` helper appending to `/tmp/...log`.
2. A flat wall of functions, separated by `####...####` banner comments that name the function.
3. A `help()` function that echoes the flag table.
4. A `while [[ $# > 0 ]] / case $key in` loop at the very bottom that dispatches each CLI flag to an **ordered call list of functions** — this is the real "main". Read the case arm to learn what a mode actually does.

Adding a mode means: write the function(s), add a `case` arm with the right call order, add a line to `help()`, and update the directory's README.

### The `_suffix` variant families (most important gotcha)

Nearly every routine is duplicated once per deployment target rather than parameterized. Suffixes:

| Suffix | Target |
|---|---|
| *(none)* | on-prem, monit-supervised |
| `_pcs` | Pacemaker HA |
| `_aws` / `_oci` | cloud installs |
| `_mig` / `_remig` | NVIDIA MIG-partitioned GPUs |
| `_no_meta` | this node does **not** host the metadata server |
| `advance_reconfiguration*` | reconfigure an existing install (vs `advance_configuration*` = fresh) |

So `default_limitQuery`, `default_limitQuery_aws`, `default_limitQuery_oci`, `default_limitQuery_mig`, `default_limitQuery_remig` are five near-identical copies. **A behavior change usually has to be applied to every variant**, and the same functions are duplicated again in `Pacemaker/pcs_sqream_installer_V1.sh`. Grep the base name across both scripts before editing one copy.

### Install pipeline (fresh on-prem `-f`, others are permutations)

`run_with_sudo` → log/summary setup → `check_for_sqream_user` / `check_metadata_service_health` → `check_tar_file` → `check_permissions_and_folders` (backs up `/etc/sqream` to `/etc/sqream_etc_backup_$today`) → `verify_and_extract` → `move_package` → `make_symlink` → `cd sqream-temp` → `install_metadata_service` / `install_metadata_config_json` → `advance_configuration` → `summary`.

`advance_configuration` is the interactive core: prompts for host IP, whether this node hosts metadata, and the storage path, then calls `create_storage`, `install_sqream_serverpicker*`, `create_service_config_template_file`, `install_sqream_services`, `check_monit_service_health*`, `limitQuery*`.

Note the scripts `mkdir sqream-temp; cd sqream-temp` **relative to the caller's cwd**, generate files there, and `rm -rf sqream-temp` at the end. Config generation therefore depends on where the script was invoked from.

### Config file generation (template + `sed` placeholders)

`create_config_template_file` / `create_service_config_template_file` / `install_sqream_services` write three templates into the temp dir: `default_config.json`, `default_service.conf`, `default.service`. Then `generate_config_files*` loops `worker_count` times per GPU, copies the templates to `sqream${N}_config.json` / `sqream${N}-service.conf` / `sqream${N}.service` and `sed`-substitutes:

- `@regular_port@` → `4999 + N`, `@sslport@` → `5099 + N`
- `@sqream_00@` → instance id, `@sqream@` → log filename, `@sqreamX-service.conf@` → env file
- bare token `limitQueryMemoryGB` (unquoted, invalid JSON on purpose) → the computed value, patched later by `limitQuery*`
- `"gpu": 0` and `"cudaMemQuota": 90` → per-GPU values

Each iteration also appends a `check process sqreamN` stanza to the monit config, delimited by `#SQREAMN-START` / `#SQREAMN-END` markers (used later to remove workers). `copy_files` then moves configs to `/etc/sqream/` and `*.service` units to `/usr/lib/systemd/system/`, chowns to `sqream`, and reloads systemd.

Because the templates are only valid JSON *after* substitution, `jq` can only be used on already-installed files (as `cbo_installer` does).

### Sizing math

`total_ram` / `total_ram_meta` reserve headroom by RAM tier (8/16/32/64/128 GB, plus 50 GB more for metadata hosts), then `limitQueryMemoryGB = AVAILABLE_RAM_GB / number_of_workers` and `spoolMemoryGB = limit - 50` when ≥128 GB else 50 % of limit. Worker count is discovered as `ls -dq /etc/sqream/*sqream*-service.conf | wc -l`; GPU count from `nvidia-smi`. `install_legacy` writes the shared `/etc/sqream/sqream_config_legacy.json` with the spool value.

## On-disk contract (do not rename these)

The repo and product were renamed SQream → Scailium (commit `c3cf469`), but every path, user, service, and log name on the target host is still `sqream`. Only user-facing echo text and script filenames carry "Scailium".

- Package: extracted to `/tmp/sqreampkg`, moved to `/usr/local/${SQVER}`, symlinked as `/usr/local/sqream`. `SQVER` is derived as `${basename%.*.*.*}` — the package filename must be `<name>.<x>.<y>.tar.gz`-shaped or the path is wrong.
- Config: `/etc/sqream/` (owned by `sqream:sqream`). Logs: `/var/log/sqream/`. Units: `/usr/lib/systemd/system/`.
- Supervision: monit — `/etc/monit.d/monitrc` in the monit paths, `/etc/sqream/monitrc` in the older/pcs paths. Both appear in the file; match the surrounding function.
- Ports: worker `4999+N` / SSL `5099+N`, metadata server `3105`, CBO client `6666`, backend `6665`, md-service `6668`.
- Install logs: `/tmp/sqream-installV1.log` (`-L`), `/tmp/sqreamdb-summary.log` (`-S`), `/tmp/pcs_sqream_installer_V1.log`, `/tmp/sq-studio_install.log`, `/tmp/sqream-sqdiag.log`.

## MIG mode

`-mig` generates `/usr/local/sbin/sqream-mig-setup.sh` from a quoted heredoc whose `mig_pr_id` / `mig_in_per_gpu` markers are `sed`-replaced with the profile ID and instances-per-GPU the operator entered, plus a oneshot `sqream-mig-setup.service` ordered `Before=monit.service`. That generated script re-creates the MIG layout at every boot and rewrites `sqreamN-service.conf` with the NUMA node read from `nvidia-smi topo -m`, so MIG worker configs are owned by it, not by the installer. `-remig` deletes both and regenerates them.

Heredoc quoting matters here: `<< 'EOM'` blocks are emitted verbatim (placeholders patched afterwards), unquoted `<<EOF` blocks interpolate installer variables. Preserve whichever form a block already uses.

## Known quirks to preserve

- `Scailium_Engine/scailium-install-v1.sh:4310` has a stray bare `{` before `create_storage`, closed only by the `}` on the last line of the file. Everything from there down (including the dispatch loop) lives inside that brace group. It is harmless at runtime, but any edit near the end of the file must keep the braces balanced — check with `bash -n`.
- Functions are redefined more than once in the same file (e.g. `permission_sqream`, `check_logfile`, `log`/`fail`, `write_sqream_conf`). The last definition before the call wins; verify which one is in effect before changing one.
- The logging idiom is a `logit "Started X"` / `logit "Success: X"` bookend pair in every function, with `echo` banners of `#` for the operator. New functions should follow it.
- Commit messages in this repo are almost all `Update <filename>`; git history is not a useful source of intent.
