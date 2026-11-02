# Workspace image for the "homelab" Coder template.
# Rebuilt automatically by the template when anything in this folder changes
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash-completion build-essential ca-certificates curl git gnupg htop jq less \
      locales openssh-client pipx python3 python3-pip python3-venv sudo tmux unzip vim wget zip \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Node.js LTS (+ corepack for pnpm/yarn)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && rm -rf /var/lib/apt/lists/*

# Go, latest stable
RUN GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1) \
    && curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz" | tar -C /usr/local -xz

# VS Code in the browser, baked in so it is not downloaded at every start
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/usr/local

# ubuntu:24.04 ships a "ubuntu" user with uid 1000, replaced by "coder"
RUN userdel -r ubuntu \
    && useradd --create-home --shell /bin/bash --uid 1000 --groups sudo coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/coder

ENV LANG=en_US.UTF-8 \
    PATH=/home/coder/.local/bin:/home/coder/go/bin:/usr/local/go/bin:$PATH

USER coder
WORKDIR /home/coder
