###########################################################################
# Homelab workspace: Docker container on the dev server with
# - a Gitea repo cloned on first start (auth through Coder's Gitea external auth)
# - VS Code in the browser (code-server) + VS Code desktop / SSH via the Coder agent
# - persistent home volume, everything else is rebuilt from build/Dockerfile
###########################################################################

terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 2.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# Asks the user to link their Gitea account before creating a workspace,
# the agent then uses that token for git over https (GIT_ASKPASS)
data "coder_external_auth" "gitea" {
  id = "gitea"
}

data "coder_parameter" "repo" {
  name         = "repo"
  display_name = "Repository Gitea"
  description  = "`owner/repo` oppure URL https completo. Vuoto per un workspace senza repo"
  type         = "string"
  default      = ""
  mutable      = false
  order        = 1
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memoria (GB)"
  type         = "number"
  default      = "4"
  mutable      = true
  order        = 2
  validation {
    min = 2
    max = 8
  }
}

data "coder_parameter" "dotfiles" {
  name         = "dotfiles"
  display_name = "Dotfiles"
  description  = "Repo dotfiles da applicare all'avvio (opzionale)"
  type         = "string"
  default      = ""
  mutable      = true
  order        = 3
}

locals {
  gitea_url = "https://git.dev.intranet.vflorio.com"
  repo      = trimsuffix(trimspace(data.coder_parameter.repo.value), ".git")
  repo_url  = local.repo == "" ? "" : (startswith(local.repo, "https://") ? "${local.repo}.git" : "${local.gitea_url}/${local.repo}.git")
  repo_dir  = local.repo == "" ? "/home/coder" : "/home/coder/${basename(local.repo)}"

  container_name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  git_name       = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
  build_hash     = substr(sha1(join("", [for f in fileset("${path.module}/build", "**") : filesha1("${path.module}/build/${f}")])), 0, 12)
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"
  dir  = local.repo_dir

  env = {
    GIT_AUTHOR_NAME     = local.git_name
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = local.git_name
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
  }

  metadata {
    display_name = "CPU"
    key          = "0_cpu"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM"
    key          = "1_ram"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home"
    key          = "2_home"
    script       = "coder stat disk --path $HOME"
    interval     = 60
    timeout      = 1
  }
}

resource "coder_script" "setup" {
  agent_id           = coder_agent.main.id
  display_name       = "Setup"
  icon               = "/icon/git.svg"
  run_on_start       = true
  start_blocks_login = true
  script             = <<-EOT
    set -e

    # First start on an empty home volume
    if [ ! -f ~/.init_done ]; then
      cp -rT /etc/skel ~
      git config --global init.defaultBranch main
      git config --global pull.rebase false
      touch ~/.init_done
    fi

    if [ -n "${local.repo_url}" ] && [ ! -d "${local.repo_dir}/.git" ]; then
      git clone "${local.repo_url}" "${local.repo_dir}"
    fi

    if [ -n "${data.coder_parameter.dotfiles.value}" ]; then
      coder dotfiles --yes "${data.coder_parameter.dotfiles.value}"
    fi
  EOT
}

resource "coder_script" "code_server" {
  agent_id     = coder_agent.main.id
  display_name = "code-server"
  icon         = "/icon/code.svg"
  run_on_start = true
  script       = <<-EOT
    code-server --auth none --bind-addr 127.0.0.1:13337 --disable-telemetry >/tmp/code-server.log 2>&1 &
  EOT
}

# Path based (no subdomain): the *.coder wildcard has no TLS certificate
resource "coder_app" "code_server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code Web"
  url          = "http://localhost:13337/?folder=${local.repo_dir}"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"
  order        = 1

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "docker_image" "workspace" {
  name         = "coder-homelab:${local.build_hash}"
  keep_locally = true # shared by every workspace, not removed when one stops
  build {
    context = "${path.module}/build"
  }
}

resource "docker_volume" "home" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes
  lifecycle {
    ignore_changes = all
  }
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_container" "workspace" {
  count    = data.coder_workspace.me.start_count
  image    = docker_image.workspace.image_id
  name     = local.container_name
  hostname = data.coder_workspace.me.name
  memory   = data.coder_parameter.memory.value * 1024

  entrypoint = ["sh", "-c", coder_agent.main.init_script]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]

  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home.name
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
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
