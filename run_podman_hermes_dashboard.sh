podman run \
  --detach \
  --restart=always \
  --userns=keep-id \
  --name hermes-dashboard \
  -v ~/hermes:/home/hermes/.hermes:Z \
  --network=host \
  hermes:v1 \
  hermes dashboard --no-open --host 127.0.0.1 --port 9119

# Note: Open an SSH tunnel with `ssh -L 9119:127.0.0.1:9119 USER@SERVER_IP` 
#       to access the dashboard on your local machine (http://127.0.0.1:9119/kanban)