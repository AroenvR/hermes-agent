podman run \
  --detach \
  --restart=always \
  --userns=keep-id \
  --name hermes-dashboard \
  -v ~/hermes:/home/hermes/.hermes:Z \
  --network=host \
  hermes:v1 \
  hermes dashboard --no-open --host 127.0.0.1 --port 9119