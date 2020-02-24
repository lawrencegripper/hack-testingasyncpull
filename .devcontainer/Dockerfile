FROM golang:1.13-buster

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# This Dockerfile adds a non-root 'vscode' user with sudo access. However, for Linux,
# this user's GID/UID must match your local user UID/GID to avoid permission issues
# with bind mounts. Update USER_UID / USER_GID if yours is not 1000. See
# https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV GO111MODULE=on

# Configure apt, install packages and tools
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog rsync bash-completion jq \
    # bazel stuff
    && apt-get -y install openjdk-11-jdk pkg-config zip g++ zlib1g-dev unzip patch \
    #
    # Verify git, process tools, lsb-release (common in install instructions for CLIs) installed
    && apt-get -y install git iproute2 procps lsb-release \
    #
    # Install Azure CLI
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV GIT_PROMPT_START='\033[1;36mkube-devcon>\033[0m\033[0;33m\w\a\033[0m'

# Save command line history 
RUN echo "export HISTFILE=/root/commandhistory/.bash_history" >> "/root/.bashrc" \
    && echo "export PROMPT_COMMAND='history -a'" >> "/root/.bashrc" \
    && mkdir -p /root/commandhistory \
    && touch /root/commandhistory/.bash_history
    
# Git command prompt
RUN git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1 \
    && echo "if [ -f \"$HOME/.bash-git-prompt/gitprompt.sh\" ]; then GIT_PROMPT_ONLY_IN_REPO=1 && source $HOME/.bash-git-prompt/gitprompt.sh; fi" >> "/root/.bashrc"


ENV DEVCONTAINER="TRUE"

# Install docker used by go releaser
RUN bash -c "cd /tmp && curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-19.03.5.tgz && tar --strip-components=1 -xvzf docker-19.03.5.tgz -C /usr/local/bin"

# Install Go tools
RUN \
    # --> Delve for debugging
    go get github.com/go-delve/delve/cmd/dlv@v1.3.2 \
    # --> Go language server
    && go get golang.org/x/tools/gopls@v0.3.2 \
    # --> Go symbols and outline for go to symbol support and test support 
    && go get github.com/acroca/go-symbols@v0.1.1 && go get github.com/ramya-rao-a/go-outline@7182a932836a71948db4a81991a494751eccfe77 \
    && rm -rf /go/src/ && rm -rf /go/pkg

# Install K8s stuff we need
RUN \
    # Build and install kubetest from test infra
    git clone https://github.com/kubernetes/test-infra.git && cd test-infra && GO111MODULE=on go install ./kubetest \
    # Install kind
    && curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-linux-amd64" \
	&& chmod +x ./kind \ 
	&& mv ./kind /usr/local/bin/kind \
    # Install bazel 
    && wget -O bazelinstaller.sh https://github.com/bazelbuild/bazel/releases/download/2.1.0/bazel-2.1.0-installer-linux-x86_64.sh  \
    && chmod +x bazelinstaller.sh \
    && ./bazelinstaller.sh \
    # Install required bazel version (may change)
    && curl -LO https://releases.bazel.build/0.23.2/release/bazel-0.23.2-linux-x86_64 && chmod +x bazel-0.23.2-linux-x86_64 && cp bazel-0.23.2-linux-x86_64 /usr/local/lib/bazel/bin \
    # Install kubectl
    && curl -sSL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.16.2/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl


# Configure bash
RUN echo "alias kindbuild='kind build node-image --type bazel -v 5 --image kindest/node:lawrence && kind create cluster --name lg --image kindest/node:lawrence'" >> ~/.bashrc
RUN echo "source /etc/bash_completion" >> "/root/.bashrc" 
RUN echo "alias k=kubectl" >> "/root/.bashrc"
RUN echo "source <(kubectl completion bash)" >> "/root/.bashrc"
RUN echo "source <(kubectl completion bash | sed 's/kubectl/k/g')" >> "/root/.bashrc"
