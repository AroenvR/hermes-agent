# Container services

This directory holds the systemd-managed container definitions for long-running Hermes services as well as their setup scripts.

Each subdirectory is self-contained: a `.container` file that declares the service, and a setup script that installs and starts it. Together they create containers that linger and survive reboots cleanly.

## How the pieces fit together

A typical lifecycle for either service looks like this:

You edit the `.container` file (or just check it out fresh on a new server), run the setup script, and that's it. The script copies the `.container` file into `~/.config/containers/systemd/` — which is the directory systemd's user manager scans for Quadlet definitions — then runs `systemctl --user daemon-reload` so systemd notices the new spec, stops any previously-running copy of the service, and starts it fresh.

After that, the service is just a normal systemd user unit. You can `systemctl --user status hermes-gateway.service` to see how it's doing, `systemctl --user restart hermes-gateway.service` to bounce it, or `journalctl --user -u hermes-gateway.service` to read its logs. The underlying Podman container is automatically created, started, stopped, and restarted as systemd directs.

The `.container` file is *the* source of truth. The setup script always overwrites the installed copy — there is no merge logic.

## What each service does

The **gateway** is the always-running Hermes process that bridges between your chosen messaging platform and the LLM provider. It also runs Hermes's internal tooling system for any agent-side scheduled work (maintenance, periodic tasks, etc).

The **dashboard** is a small web UI Hermes ships with — useful for inspecting config, looking at sessions, managing skills, and the Kanban view at `/kanban`. It binds to loopback inside the container's network namespace (`127.0.0.1:9119`) and joins the host's network namespace so that loopback port is reachable on the server's own `127.0.0.1`. From your local machine you reach it via an SSH tunnel:

```
ssh -L 9119:127.0.0.1:9119 USER@SERVER_IP
```

Then you can access it at `http://127.0.0.1:9119/kanban` in your browser.

## Where state lives

Both services bind-mount the host directory `~/hermes/` into the container at `/home/hermes/.hermes/`. That's where everything Hermes accumulates over time lives — `MEMORY.md`, `USER.md`, `SOUL.md`, the sessions database, the skills directory, your agent's wikilinks vault, the auto-commit git history, all of it.

## What's in each `.container` file

A `.container` file is roughly INI-shaped, with sections borrowed from systemd unit files plus a `[Container]` section for Quadlet-specific options.  
The interesting parts:

- **`Image=localhost/hermes:v1`** — which container image to run. The image
  is built locally via the `Containerfile` in the parent repo.
- **`ContainerName=...`** — the visible Podman name. Matches the service
  name minus the `.service` suffix.
- **`UserNS=keep-id`** — maps the container's `hermes` user to the host's
  user so file ownership on the bind-mount works. Without this,
  the container can't read its own files because host-uid 1000 and
  container-uid 1000 are different namespaces.
- **`Volume=%h/hermes:/home/hermes/.hermes:Z`** — the bind-mount. `%h` is
  systemd's home-directory placeholder; `:Z` is an SELinux relabel hint
  (harmless on Ubuntu, useful if anything we run is ever moved to a
  SELinux-enforcing distro).
- **`Exec=...`** — what command to run inside the container. For the gateway
  it's `hermes gateway`; for the dashboard it's
  `hermes dashboard --no-open --host 127.0.0.1 --port 9119`.
- **`Restart=always`** in `[Service]` — under Quadlet this is a real systemd
  directive, not a Podman flag. It applies the same way every other systemd
  service treats `Restart=always`.
- **`WantedBy=default.target`** in `[Install]` — this is what makes the
  service start at boot. `default.target` is the user-systemd equivalent of
  "fully booted." Without this line, the service would exist but not
  auto-start.

The dashboard `.container` additionally has `Network=host`, which is necessary because rootless Podman's normal port-publishing flow doesn't gracefully forward host-loopback to container-loopback when the bound address is `127.0.0.1` rather than `0.0.0.0`. Sharing the host's network namespace means there's only one `127.0.0.1` involved, and the SSH tunnel reaches the dashboard cleanly. The gateway doesn't need this — it makes no inbound connections at all.

## What the setup scripts do

Each script does the same six things:

1. **Pre-flight check**: verify the image `localhost/hermes:v1` actually
   exists. If not, fail loudly with a hint about how to build it. This
   prevents the more cryptic "container failed to start" error that
   systemd would otherwise emit.
2. **Ensure the Quadlet directory exists** (`~/.config/containers/systemd/`).
   Created if needed; harmless if already there.
3. **Copy the `.container` file** into the Quadlet directory, always
   overwriting any existing copy. The file in the repo is the truth.
4. **Stop the existing service** if it's running. Done via `systemctl
   --user stop ... || true` so it's a no-op when the service doesn't exist
   yet. This avoids a known Quadlet wrinkle where in-place `restart` can
   sometimes leave a stale container holding the name.
5. **`systemctl --user daemon-reload`** so systemd parses the (possibly
   updated) `.container` file and refreshes its picture of the unit.
6. **Start the service** and show its status. If everything's healthy you'll
   see `active (running)` with a recent timestamp.

The dashboard script also prints the SSH-tunnel command at the end as a
reminder.

## How to run them on a fresh server

Assuming the host has been bootstrapped (see `host-bootstrap.sh` at the
project root — that's the script that enables linger, sets up sudoers,
etc.) and you've built the image:

```
podman build --tag localhost/hermes:v1 -f /path/to/Containerfile .
```

Then run the gateway setup script first:

```
cd containers/gateway
bash setup_hermes_gateway_container.sh
```

That's it, you can now run any other container scripts in this directory.  
The services will be running and will auto-start on every subsequent boot.

## How to update a service

There are two kinds of update.

**Updating the service definition** (changing flags, mount points, the command being run, etc.) means editing the `.container` file in this repo and re-running the setup script. The script's overwrite-and-restart flow applies the new spec cleanly.

**Updating the image** (new Hermes release, new base, new tool installed)
means rebuilding the image first:

```
podman build --tag localhost/hermes:v1 -f /path/to/Containerfile .
```

Then either re-run the setup script (which will stop and start the
service, picking up the new image), or just:

```
systemctl --user restart hermes-gateway.service
systemctl --user restart hermes-dashboard.service
```

Either path works. The setup script is more thorough but slower; the bare restart is one line and instant. If the image name in `.container` has changed too, use the setup script — bare restart won't pick that up without a daemon-reload.

## Why Quadlet specifically

Quadlet was chosen over the alternatives because:

- It's declarative — the `.container` file is the spec, no imperative
  glue code in between.
- It integrates with systemd natively, which means it benefits from
  systemd's mature handling of boot ordering, dependency management,
  log capture, and lifecycle events.
- It's the official forward path for Podman service management; the older
  `podman generate systemd` approach is deprecated as of Podman 5.x.
- The container definitions live in version control alongside the rest of
  the project, which keeps deployment reproducible.

The main alternative considered was `podman generate systemd`, which would have produced equivalent systemd units from existing running containers but with a stateful, imperative flow ("first create the container the way you want it, then generate a unit from it"). Quadlet inverts this — the `.container` file is the source of truth, the container is just an artifact systemd creates from it. Cleaner for the long-term.

## What this directory does NOT cover

A few things deliberately live elsewhere:

- **Building the image** — see the `Containerfile` at the project root.
- **Host preparation** (linger, sudoers, packages) — see
  `host-bootstrap.sh` at the project root.

The pattern is: container definitions go here, the image recipe goes at the root, host plumbing goes at the root, agent-side concerns go inside the skills tree. Different concerns, different homes, but all reproducible from a fresh server given this repo plus a Hermes-ready Containerfile.