# scailium-installers

Bash installers and diagnostics for **Scailium Engine** (SQream DB), its HA / Pacemaker variant, and SQream Studio. Each script is standalone — copy the one you need onto the target server and run it there.

| Script | Use it for |
|---|---|
| [`Scailium_Engine/scailium-install-v1.sh`](Scailium_Engine/) | Installing, upgrading and reconfiguring the engine — on-prem, AWS, OCI, MIG, metadata-only, CBO, Iceberg |
| [`Pacemaker/pcs_sqream_installer_V1.sh`](Pacemaker/) | The same engine in a Pacemaker HA cluster — master/slave nodes, node join/remove, worker add/delete |
| [`UI/sq-studio-install.sh`](UI/) | SQream Studio (Node.js + PM2), optionally behind an nginx HTTPS proxy |
| [`diag-sqream-v1.sh`](diag-sqream-v1.sh) | Checking a host before or after an install (user, shell, sudoers, groups, limits, core dumps) |

## Requirements

- RHEL / CentOS **7, 8 or 9** (the scripts detect `VERSION_ID` and exit on anything else)
- `root` — run everything with `sudo`, except the Studio installer, which refuses to run as root
- An OS user named **`sqream`** — create it first, the installer exits if it is missing
- NVIDIA driver + `nvidia-smi` on GPU worker nodes
- The engine package as a `<name>.<x>.<y>.tar.gz` archive
- On RHEL 8/9 the `-prepare` step enables `codeready-builder` and `highavailability` repos via `subscription-manager`, so the host must be registered

Install the OS prerequisites (EPEL, monit, jq, kernel headers, build tools, chrony/ntp) with:

```bash
sudo ./scailium-install-v1.sh -prepare      # or: sudo ./pcs_sqream_installer_V1.sh -prepare
```

The engine must be **stopped** before installing or reconfiguring — the scripts abort if `metadataserver.service` is active.

## Quick start

```bash
chmod +x scailium-install-v1.sh

sudo ./scailium-install-v1.sh -prepare                        # OS prerequisites
sudo ./scailium-install-v1.sh -f sqream-db-v2024.1.tar.gz     # fresh install
sudo ./scailium-install-v1.sh -S                              # review the summary
```

The installers are **interactive** — they prompt for the host IP, whether the node hosts the metadata server, the storage path, workers per GPU, and `cudaMemQuota`. Run them in a real terminal (`tmux`/`screen` for long sessions), not from a pipeline.

After installing, copy the logrotate rule for the engine logs:

```bash
sudo cp Scailium_Engine/scailium-services /etc/logrotate.d/
```

## Scailium Engine flags

`sudo ./scailium-install-v1.sh <flag> [package.tar.gz]`

| Flag | Description |
|---|---|
| `-f <pkg>` | Fresh install, monit-supervised |
| `-u <pkg>` | Upgrade the version and the storage; keeps existing configs |
| `-a` | Reconfigure an existing on-prem install |
| `-aws <pkg>` / `-reaws` | Install / reconfigure on AWS |
| `-oci <pkg>` / `-reoci` | Install / reconfigure on OCI |
| `-mig <pkg>` / `-remig` | Install / reconfigure with NVIDIA MIG support |
| `-metadata <pkg>` / `-remetadata` | Metadata server only, no workers |
| `-cbo` | Install the CBO components (`cbo-backend`, `cbo-client`, `md-service`) |
| `-iceberg` | Enable Iceberg support (requires CBO) |
| `-E` / `-EA` | Expert reconfiguration — edit worker JSON configs directly |
| `-ldap` | Configure an LDAP connection |
| `-prepare` | Install OS prerequisites |
| `-L` / `-S` | View the install log / the configuration summary |
| `-h` | Help |

`-p` and `-A` also exist for Pacemaker installs, but use `Pacemaker/pcs_sqream_installer_V1.sh` for HA instead.

## Pacemaker (HA) flags

`sudo ./pcs_sqream_installer_V1.sh <flag> [package.tar.gz]`

| Flag | Description |
|---|---|
| `-prepare` | Prepare the OS for the engine and Pacemaker |
| `-master <pkg>` / `-slave <pkg>` | Install the first node / an additional node of the cluster |
| `-remaster` / `-reslave` | Reconfigure an existing master / slave node |
| `-metadata <pkg>` | Metadata server node for the cluster |
| `-sqreamdb <pkg>` | Engine only, on an existing cluster node |
| `-join_gpu` / `-join_metadata` | Join a new GPU / metadata node to the cluster |
| `-add-workers` / `-delete-workers` | Add or remove workers (run on the master) |
| `-remove_node` / `-remove` | Remove a node / a cluster resource |
| `-status` | Watch `pcs status` |
| `-cbo` | Install the CBO components |
| `-S` | View the configuration summary |

Pacemaker creates a `sqreamdb` cluster with a `lb_group` resource group holding `PublicVIP` (IPaddr2), `MS` (metadata server) and `LB` (serverpicker). You are prompted for the `hacluster` credentials during setup.

> The script's built-in `-h` text is out of date: it advertises `-join`, while the flag the script actually accepts is `-join_gpu`. It also omits `-sqreamdb`, `-add-workers`, `-delete-workers`, `-remove_node`, `-status` and `-cbo`.

## SQream Studio flags

Run **without** `sudo` (the script calls `sudo` itself where needed):

| Flag | Description |
|---|---|
| `-pm2` | Install Node.js, npm and PM2 |
| `-f <pkg>` | Install Studio |
| `-u <pkg>` | Upgrade Studio |
| `-nginx` | Put an nginx HTTPS reverse proxy in front of Studio |

## Diagnostics

```bash
sudo ./diag-sqream-v1.sh
```

No flags — it walks the host checks in order (`sqream` user, shell, sudoers, groups, CUDA driver, security limits, core dumps), offers to configure the security limits and the core-dump path, and prints a summary of the errors it found at the end.

## What gets installed where

| Path | Contents |
|---|---|
| `/usr/local/<package-version>` | Extracted package, symlinked as `/usr/local/sqream` |
| `/etc/sqream/` | Worker configs (`sqreamN_config.json`), service env files, legacy config, license |
| `/usr/lib/systemd/system/` | `sqreamN.service`, `metadataserver.service`, `serverpicker.service` |
| `/etc/monit.d/monitrc` | monit process supervision for every worker and service |
| `/var/log/sqream/` | Runtime logs |

Existing `/etc/sqream` is backed up to `/etc/sqream_etc_backup_<timestamp>` before a fresh install.

Ports: worker *N* listens on `4999+N` (SSL `5099+N`), metadata server on `3105`, CBO client `6666`, CBO backend `6665`, md-service `6668`.

## Logs

| File | Written by |
|---|---|
| `/tmp/sqream-installV1.log` | Engine installer (`-L`) |
| `/tmp/sqreamdb-summary.log` | Configuration summary (`-S`) |
| `/tmp/pcs_sqream_installer_V1.log` | Pacemaker installer |
| `/tmp/sq-studio_install.log` | Studio installer |
| `/tmp/sqream-sqdiag.log` | Diagnostics |

Attach the relevant log when reporting an installation problem.
