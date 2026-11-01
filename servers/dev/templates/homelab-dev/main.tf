terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}

locals {
  username = data.coder_workspace.me.name
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}

provider "docker" {}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
  default      = "2"
  type         = "number"
  mutable      = true
  validation {
    min = 1
    max = 4
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory (GB)"
  description  = "The amount of memory in GB"
  default      = "4"
  type         = "number"
  mutable      = true
  validation {
    min = 2
    max = 8
  }
}

data "coder_parameter" "git_repo" {
  name         = "git_repo"
  display_name = "Git Repository"
  description  = "Repository to clone (leave empty for fresh workspace)"
  default      = ""
  type         = "string"
  mutable      = true
}

resource "coder_agent" "main" {
  arch                   = data.coder_provisioner.me.arch
  os                     = data.coder_provisioner.me.os
  #login_before_ready     = false
  #startup_script_timeout = 180
  startup_script = <<-EOT
    set -e
    
    # Clone repository if specified
    if [ -n "${data.coder_parameter.git_repo.value}" ]; then
      if [ ! -d "/home/coder/workspace/.git" ]; then
        git clone ${data.coder_parameter.git_repo.value} /home/coder/workspace/$(basename ${data.coder_parameter.git_repo.value} .git)
        cd /home/coder/workspace/$(basename ${data.coder_parameter.git_repo.value} .git)
      else
        cd /home/coder/workspace
        git pull
      fi
    fi
    
    # Configure NPM to use Verdaccio
    npm config set registry https://npm.dev.intranet.vflorio.com/
    
    # Configure Docker to use local registry
    echo '{"insecure-registries":["registry.dev.intranet.vflorio.com"]}' | sudo tee /etc/docker/daemon.json
    sudo systemctl restart docker || true
    
    # Install development tools
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server
    /tmp/code-server/bin/code-server --install-extension ms-vscode.vscode-typescript-next
    /tmp/code-server/bin/code-server --install-extension esbenp.prettier-vscode
    /tmp/code-server/bin/code-server --install-extension bradlc.vscode-tailwindcss
  EOT

  # These environment variables allow you to make Git commits right away after creating a
  # workspace. Note that they take precedence over configuration defined in ~/.gitconfig!
  env = {
    GIT_AUTHOR_NAME     = "${data.coder_workspace.me.name}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace.me.name}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.name}@example.com"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.name}@example.com"
  }

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $HOME"
    interval     = 60
    timeout      = 1
  }
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code"
  url          = "http://localhost:13337/?folder=/home/coder/workspace"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_image" "main" {
  name = "coder-${data.coder_workspace.me.id}"
  build {
    context = "./build"
    dockerfile = "Dockerfile"
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "build/*") : filesha1(f)]))
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.main.name
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.name}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/coder/"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  volumes {
    container_path = "/workspaces"
    host_path      = "/mnt/ssd-0/homelab-data/workspaces"
    read_only      = false
  }
  
  # Set resources
  memory = data.coder_parameter.memory.value * 1024
  
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[0].id

  item {
    key   = "memory"
    value = "${data.coder_parameter.memory.value}GB"
  }
  item {
    key   = "cpu"
    value = "${data.coder_parameter.cpu.value} cores"
  }
  item {
    key   = "git_repo"
    value = data.coder_parameter.git_repo.value
  }
}