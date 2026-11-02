# Workspace images for the "homelab" Coder template: one target per stack, all sharing "base".
# The template builds only the target picked in the "stack" parameter, and rebuilds it
# automatically when anything in this folder changes.
#
# Toolchains live outside /home/coder (it is the persistent volume and would hide them),
# and are owned by coder so extra versions/components can be installed from the workspace.

###########################################################################
# base: shared tools, Node.js (needed by many editors/CLIs), code-server
###########################################################################
FROM ubuntu:24.04 AS base

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash-completion build-essential ca-certificates curl git gnupg htop jq less \
      locales openssh-client pkg-config sudo tmux unzip vim wget xz-utils zip \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Node.js LTS (+ corepack for pnpm/yarn)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && rm -rf /var/lib/apt/lists/*

# VS Code in the browser, baked in so it is not downloaded at every start
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/usr/local

# ubuntu:24.04 ships a "ubuntu" user with uid 1000, replaced by "coder"
RUN userdel -r ubuntu \
    && useradd --create-home --shell /bin/bash --uid 1000 --groups sudo coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/coder

ENV LANG=en_US.UTF-8 \
    PATH=/home/coder/.local/bin:$PATH

USER coder
WORKDIR /home/coder

###########################################################################
# node: Node.js (from base) + Bun
###########################################################################
FROM base AS node

USER root
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash
USER coder

###########################################################################
# python: system Python 3.12 + uv (manages other Python versions and tools)
###########################################################################
FROM base AS python

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-dev python3-pip python3-venv pipx \
    && rm -rf /var/lib/apt/lists/* \
    && curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh
USER coder

###########################################################################
# rust: rustup stable with clippy, rustfmt, rust-analyzer
###########################################################################
FROM base AS rust

ENV RUSTUP_HOME=/opt/rustup \
    CARGO_HOME=/opt/cargo \
    PATH=/opt/cargo/bin:$PATH

USER root
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile default --component rust-analyzer \
    && chown -R coder:coder /opt/rustup /opt/cargo
USER coder

###########################################################################
# scala: JDK 21 + coursier, scala, scala-cli, sbt (jars are fetched into ~/.cache on first use)
###########################################################################
FROM base AS scala

# some launchers (sbt) run straight from the coursier cache, so it must stay in the image
ENV COURSIER_CACHE=/opt/coursier/cache \
    COURSIER_ARCHIVE_CACHE=/opt/coursier/arc

USER root
RUN apt-get update && apt-get install -y --no-install-recommends openjdk-21-jdk-headless \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://github.com/coursier/coursier/releases/latest/download/cs-x86_64-pc-linux.gz | gzip -d > /usr/local/bin/cs \
    && chmod +x /usr/local/bin/cs \
    && cs install --install-dir /usr/local/bin scala scala-cli sbt \
    && chown -R coder:coder /opt/coursier
USER coder

###########################################################################
# elixir: precompiled Erlang/OTP + Elixir from the official elixir-lang.org installer
###########################################################################
FROM base AS elixir

ENV MIX_HOME=/opt/elixir/mix \
    HEX_HOME=/opt/elixir/hex \
    PATH=/opt/elixir/otp/bin:/opt/elixir/elixir/bin:/opt/elixir/mix/escripts:$PATH

USER root
RUN apt-get update && apt-get install -y --no-install-recommends inotify-tools libncurses6 libssl3 \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://elixir-lang.org/install.sh -o /tmp/install.sh \
    && HOME=/tmp/elixir-home sh /tmp/install.sh elixir@latest otp@latest \
    && mkdir -p /opt/elixir \
    && mv /tmp/elixir-home/.elixir-install/installs/otp/* /opt/elixir/otp \
    && mv /tmp/elixir-home/.elixir-install/installs/elixir/* /opt/elixir/elixir \
    && rm -rf /tmp/install.sh /tmp/elixir-home \
    && chown -R coder:coder /opt/elixir
USER coder
RUN mix local.hex --force && mix local.rebar --force
