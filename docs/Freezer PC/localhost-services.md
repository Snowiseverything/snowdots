# Localhost Services — Freezer

## Services Dashboard (auto-detected)

**`http://localhost/`** — dynamic HTML dashboard showing running/idle services.

Started automatically by hyprland.conf. Binds port 80 via CAP_NET_BIND_SERVICE setcap on python3.

Source: `~/.local/bin/services-dashboard.py`

## Known Services

| Port | Service                | Access                  | Type                              |
| ---- | ---------------------- | ----------------------- | --------------------------------- |
| 80   | **Services Dashboard** | `http://localhost/`     | Always up if dashboard is running |
| 3333 | **MAD68 HE Dashboard** | `http://localhost:3333` | Keyboard RGB animation            |
| 4096 | **OpenCode Serve**     | `http://freezer:4096`   | AI remote access                  |
| 6742 | **OpenRGB**            | SDK port                | Lighting (SDK, not browser)       |
| 7000 | **Odysseus**           | `http://localhost:7000` | Dashboard/metadata                |
| 8080 | **SearXNG**            | `http://localhost:8080` | Private metasearch                |
| 8091 | **ntfy**               | `http://localhost:8091` | Push notifications                |
| 8100 | **ChromaDB**           | SDK port                | Vector DB (no browser UI)         |
| 8956 | **Brave CSS Server**   | `http://localhost:8956` | Matugen CSS for Brave             |

## Non-web services

| Port        | Service       | Purpose         |
| ----------- | ------------- | --------------- |
| 22          | SSH           | Remote access   |
| 631         | CUPS          | Printing        |
| 5037        | ADB           | Android debug   |
| 6463        | Discord RPC   | Rich presence   |
| 10086       | Wine (RE9)    | Game server     |
| 27036       | Steam         | Networking      |
| 11987-11988 | CoolerControl | Fan control IPC |

## Docker

```bash
docker ps
docker compose -f /opt/fast-note-sync/docker-compose.yml ps
```
