# gtnh-enzoserver

GregTech: New Horizons server on Docker.

## Features

- **Server:** [itzg/minecraft-server](https://github.com/itzg/docker-minecraft-server) running GTNH `latest-beta`. It updates itself on restart and pauses when nobody is online.
- **Backups:** [itzg/mc-backup](https://github.com/itzg/docker-mc-backup) saves `data/` to `backups/` every 6h while players are online and keeps 7 days.
- **Daily restart:** at 06:00 Asia/Singapore, with in-game warnings if players are online ([scripts/daily-restart.sh](scripts/daily-restart.sh)).
- **Dashboard:** [Dozzle](https://dozzle.dev) at `http://<host>:8080` shows logs and CPU/RAM, with restart buttons and a shell. It has no login, so keep it on trusted networks.

## Setup

Create `.env` with an RCON password shared by the server, backups and restarter:

```bash
echo "RCON_PASSWORD=$(openssl rand -hex 16)" > .env
```

## Commands

| Task | Command |
| --- | --- |
| Start everything (or apply `compose.yaml` changes) | `docker compose up -d` |
| Stop everything (stays off) | `docker compose stop` |
| Start again after a stop | `docker compose start` |
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

> Typing `stop` in the console restarts the server, because of the restart policy. To keep it off, use `docker compose stop`.

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
