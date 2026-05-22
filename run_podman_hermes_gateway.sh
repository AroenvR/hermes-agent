podman run \
  --detach \
  --restart=always \
  --userns=keep-id \
  --name hermes-gateway \
  -v ~/hermes:/home/hermes/.hermes:Z \
  hermes:v1 \
  hermes gateway