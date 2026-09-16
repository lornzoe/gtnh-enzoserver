# gtnh-enzoserver

GregTech: New Horizons server on Docker.

## Features

- **Server:** [itzg/minecraft-server](https://github.com/itzg/docker-minecraft-server) running GTNH `latest-beta`. It updates itself on restart and pauses when nobody is online.
- **Backups:** [itzg/mc-backup](https://github.com/itzg/docker-mc-backup) saves `data/` to `backups/` every 6h while players are online and keeps 7 days.
- **Daily restart:** at 06:00 Asia/Singapore, with in-game warnings if players are online ([scripts/daily-restart.sh](scripts/daily-restart.sh)).
- **Dashboard:** [Dozzle](https://dozzle.dev) at `http://<host>:8080` shows logs and CPU/RAM, with restart buttons and a shell. It has no login, so keep it on trusted networks.
- **Starts on boot:** `systemd/gtnh-server.service` brings the stack up after a reboot and, more importantly, stops it gracefully beforehand so the world saves ([why](#why-the-boot-service-exists)).

## Setup

### 1. Docker Engine

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"   # log out and back in for this to take effect
```

The package enables `docker.service` at boot, so the daemon starts itself.

### 2. RCON password

Create `.env` with an RCON password shared by the server, backups and restarter:

```bash
echo "RCON_PASSWORD=$(openssl rand -hex 16)" > .env
```

### 3. The boot service

Enabling by absolute path symlinks this repo's copy into `/etc/systemd/system`, so
edits here take effect after a `systemctl daemon-reload`:

```bash
sudo systemctl enable --now /home/nzoe/gtnh-enzoserver/systemd/gtnh-server.service
```

The unit runs as `nzoe`, so the `docker` group membership from step 1 has to be live
first. The first start downloads the GTNH pack and takes a while — follow it with
`docker compose logs -f mc`.

## Commands

| Task | Command |
| --- | --- |
| Start everything (or apply `compose.yaml` changes) | `sudo systemctl start gtnh-server` |
| Stop everything (stays off) | `sudo systemctl stop gtnh-server` |
| Is the stack up? | `sudo systemctl status gtnh-server` |
| Stop only the server | `docker compose stop mc` |
| Restart the server | `docker compose restart mc` |
| Status | `docker compose ps` |
| Follow server logs | `docker compose logs -f mc` |
| Server console | `docker compose exec mc rcon-cli` |
| Run one server command | `docker compose exec mc rcon-cli list` |
| Message players | `docker compose exec mc rcon-cli say "Restarting soon"` |
| Back up now | `docker compose exec backups backup now` |
| List backups | `ls -lh backups/` |
| Update Docker images | `docker compose pull && docker compose up -d` |
| Test the daily restart (a few minutes ahead) | `RESTART_TIME=HH:MM docker compose up -d restarter` |
| Reset restart time to 06:00 | `docker compose up -d restarter` |

> Typing `stop` in the console restarts the server, because of the restart policy. To keep it off, use `sudo systemctl stop gtnh-server`.

> Prefer `systemctl stop` over `docker compose stop` or `down` — the unit gives `mc` up to 5 minutes to finish its RCON save.

### Restore a backup

```bash
docker compose stop mc
mv data/World data/World.old
tar --zstd -xf backups/world-YYYYMMDD-HHMMSS.tar.zst -C data ./World
docker compose start mc
```

### Update GTNH

`latest-beta` installs new betas automatically, but never stable releases. When a stable release comes out:

1. In `compose.yaml`, set `GTNH_PACK_VERSION: latest`, or pin an exact version like `2.9.0`.
2. Back up and apply:
   ```bash
   docker compose exec backups backup now
   docker compose up -d
   ```

Old configs are saved to `data/gtnh-upgrade-*`. To stop automatic updates, set `SKIP_GTNH_UPDATE_CHECK: true`.

## Why the boot service exists

`restart: unless-stopped` already brings the containers back when the daemon starts,
so boot is covered without any unit. Shutdown is not: on `reboot`, `dockerd` gives
each container only its `--shutdown-timeout` (**15s** by default), while `mc` is
configured for a 110s RCON save under a 2m `stop_grace_period`. Without the unit, a
reboot SIGKILLs GTNH mid-save.

`Requires=`/`After=docker.service` makes systemd stop the unit — running
`docker compose stop` under a 300s `TimeoutStopSec` — before it tears `docker.service`
down. `TimeoutStartSec=0` is there because `up -d` pulls images synchronously and the
first GTNH pack install blows past systemd's 90s default.
