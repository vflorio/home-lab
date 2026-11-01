FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install development tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    htop \
    sudo \
    vim \
    wget \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js and NPM
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Python and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz && \
    rm go1.21.5.linux-amd64.tar.gz

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add Go and Rust to PATH
ENV PATH="/usr/local/go/bin:/root/.cargo/bin:${PATH}"

# Install Coder agent
RUN curl -fsSL https://coder.com/install.sh | sh

# Create docker group and coder user
RUN groupadd -f docker && \
    useradd --groups sudo,docker --uid 1000 --shell /bin/bash --create-home coder && \
    mkdir -p /etc/sudoers.d && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd

# Set up workspace directory
RUN mkdir -p /home/coder/workspace && \
    chown -R coder:coder /home/coder

USER coder

# Configure Git for the coder user
RUN git config --global init.defaultBranch main && \
    git config --global pull.rebase false && \
    git config --global safe.directory '*'

# Configure NPM registry
RUN npm config set registry https://npm.dev.intranet.vflorio.com/

# Set working directory
WORKDIR /home/coder/workspace