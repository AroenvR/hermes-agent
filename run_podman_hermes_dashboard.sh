podman run \
  --detach \
  --restart=always \
  --userns=keep-id \
  --name hermes-dashboard \
  -v ~/hermes:/home/hermes/.hermes:Z \
  hermes:v1 \
  hermes dashboard --no-open --host 0.0.0.0 --port 9119