# Hermes Agent on an Ubuntu server within a Podman container

Setup notes for running [Hermes Agent](https://hermes-agent.nousresearch.com/) in a Podman container on a fresh Ubuntu.

--

## TODO: 
- Create a script for the actions in this README file, simply provide the README file as documentation, not a walkthrough.
- Ensure it fits the Containerfile and host_bootstrap.sh and other supporting files in naming conventions.

---

## What you'll have at the end

- A server running Ubuntu 24.04 LTS with a non-root `manager` user.
- Podman installed.
- A custom Hermes container image (`hermes:v1`) built locally.
- Hermes's state living on the host at `~/hermes/`, persistent across
  container restarts.

## What you'll need beforehand

- A server with:
  - Ubuntu 24.04 LTS
  - 2 vCPU, 4 GB RAM minimum (Hermes's own minimum)
  - 25+ GB disk
- SSH access to the server.

## The setup

### 1. Create a non-root user

SSH in as `root`:

```bash
ssh root@YOUR_SERVER_IP
```

Create a regular user. This prompts for a password — keep it; sudo will
ask for it, which is the boundary we want.

```bash
adduser manager
usermod -aG sudo manager
```

Copy your SSH key over so you can log in directly as `manager`:

```bash
mkdir -p /home/manager/.ssh
cp ~/.ssh/authorized_keys /home/manager/.ssh/
chown -R manager:manager /home/manager/.ssh
chmod 700 /home/manager/.ssh
chmod 600 /home/manager/.ssh/authorized_keys
```

**Verify before continuing.** Open a second terminal locally:

```bash
ssh manager@YOUR_SERVER_IP
```

Should log in without a password. Then test sudo:

```bash
sudo whoami     # should ask for password, then print 'root'
```

If both work, close the root session. Stay on as `manager` from here on.

### 2. Install Podman

```bash
sudo apt-get update
sudo apt-get install -y podman
```

Verify:

```bash
podman --version
podman run --rm hello-world      # smoke test
podman rm -f hello-world
```

### 3. Run the host-bootstrap script
This is a one-time host-side setup. It enables systemd lingering for
your user (so Podman containers survive SSH disconnects) and grants
passwordless sudo for `journalctl` (used by diagnostic scripts).  
Both can be done manually, but the script makes it idempotent and
documented.  
Execute the provided `host-bootstrap.sh` script.  
It will prompt for your sudo password once or twice, print a summary,
and exit. Safe to re-run.  

**Why this matters**: without lingering enabled, rootless Podman
containers get killed when your SSH session ends (systemd cleans up
`user@1000.service`). The container will appear to run for hours then
mysteriously disappear or stop responding.

### 5. Create the host directory for Hermes state

```bash
mkdir -p ~/hermes
```

This directory will hold all of Hermes's persistent state (config, memory,
skills, sessions). It survives container rebuilds.

### 6. Build the Hermes container image

```bash
podman build --tag hermes:v1 .
```

Takes 5–15 minutes depending on network speed. Watch the output for any
red error messages; if it finishes with `Successfully tagged
localhost/hermes:v1`, you're good.

### 7. Seed the host directory from the image

The first time around, the bind-mount (next step) would hide Hermes's
installed code. We need to copy the image's `~/.hermes/` contents into
the host's `~/hermes/` first. This is a one-shot:

```bash
podman run --rm \
  --userns=keep-id \
  -v ~/hermes:/seed:Z \
  hermes:v1 \
  bash -c "cp -a /home/hermes/.hermes/. /seed/"
```

Verify the seed worked:

```bash
ls ~/hermes
```

You should see directories like `hermes-agent`, `skills`, `cron`, etc.,
and files like `config.yaml`, `SOUL.md`, `.env`.

### 7. Run the setup container

This is where you configure Hermes interactively (provider, model, channels).

```bash
podman run \
  --rm \
  -it \
  --userns=keep-id \
  --name hermes-setup \
  -v ~/hermes:/home/hermes/.hermes:Z \
  -p 127.0.0.1:8765:8765 \
  hermes:v1
```

You'll get a shell prompt inside the container: `hermes@<hash>:~$`.

Run setup:

```bash
hermes setup
```

The wizard walks you through setting up hermes.

### 8. Restarting container - run the script

Run `podman ps` to check if the container is still up. If it is, remove it with the following command:
```bash
podman rm -f hello-world
```

Helper scripts:
- `run_podman_hermes_gateway.sh` runs the Hermes Agent's gateway in a restarting container.
- `run_podman_hermes_dashboard.sh` runs the Hermes Agent's dashboard in a restarting container on port 9119 in the server. *

Notes*:
Open up an SSH tunnel to the VPS on your local machine with `ssh -L 9119:127.0.0.1:9119 manager@SERVER_IP` to access the WebUI at http://127.0.0.1:9119/ in your local browser.

Enter the container with:
```bash
podman exec -it CONTAINER_NAME_OR_ID /bin/bash
```

---

## Common issues and what to do

### "UID 1000 is not unique" during image build

Ubuntu 24.04's base image now ships with a default `ubuntu` user at
uid 1000. The Containerfile handles this with `userdel -r ubuntu`
before creating the `hermes` user. If you start from a different base
image and hit this, that's the fix.

### "Unable to locate package python3.11" during image build

Ubuntu 24.04 ships Python 3.12 by default. Hermes requires "3.11+",
so use the `python3` package (which pulls 3.12 on Noble), not the
explicit `python3.11`. The Containerfile in this repo does this.

### "No such file or directory" when running `hermes setup`

You started the container with the bind-mount before seeding the host
directory. The bind-mount masked the image's installed code. Solution:
do step 6 (seed the host directory) before step 7.

### "Permission denied" when accessing `/home/hermes/.hermes/` inside the container

You forgot `--userns=keep-id` on the `podman run` command. Without it,
rootful Podman maps host uid 1000 to container *root*, while the
container's `hermes` user is a different uid — the container can't
read its own bind-mounted files. Every `podman run` against this
bind-mount needs `--userns=keep-id`.

### Container name "hermes-setup" is already in use

The previous container exited unexpectedly (e.g. SSH pipe broke) and
`--rm` didn't fire. Remove the stale container:

```bash
podman rm -f hermes-setup
```

Then re-run the same `podman run` command. Or add `--replace` to
the `podman run` command itself, which removes any existing container
with the same name before starting.

### Build fails with a network error

Almost always transient. Re-run the same `podman build` command;
earlier successful steps are cached, so it picks up from where
it failed.