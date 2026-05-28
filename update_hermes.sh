TAG=v0.15.0-24.04

podman build --no-cache --pull=always --tag hermes:$TAG .

podman run --rm -it hermes:$TAG bash -lc '
  whoami
  node --version
  python3 --version
  command -v hermes
  hermes --version || hermes version || true
'