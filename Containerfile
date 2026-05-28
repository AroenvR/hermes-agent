# Start from Ubuntu (current LTS) - Hermes' preferred distro.
FROM ubuntu:24.04

# Don't prompt during apt installs.
ENV DEBIAN_FRONTEND=noninteractive

# Install base tools first (curl is needed to fetch NodeSource's setup script).
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg \
  && rm -rf /var/lib/apt/lists/*

# Add NodeSource's Node.js 24 apt repo (current LTS), then install Node 24.
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

# Install Hermes's other dependencies.
# Noble ships Python 3.12 by default — Hermes requires "3.11+" so 3.12 is fine.
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
    git \
    ripgrep ffmpeg \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

# Ubuntu ships with a default 'ubuntu' user at uid 1000.
# Delete it and create our own 'hermes' user at the same uid.
RUN userdel -r ubuntu \
  && useradd --create-home --shell /bin/bash --uid 1000 hermes

# Switch to that user for everything after this point.
USER hermes
WORKDIR /home/hermes

# Run Hermes's official installer.
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# Make sure the 'hermes' command is findable on PATH.
ENV PATH="/home/hermes/.local/bin:${PATH}"

# Default action: open a shell for interactive use.
CMD ["/bin/bash"]