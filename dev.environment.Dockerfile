# Use the official Arch Linux base image
FROM archlinux/base

# Set maintainer label (optional)
LABEL maintainer="your_email@example.com"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. System Update and Core Dependencies
# --------------------------------------
# - Update package database and upgrade system
# - Install sudo, openssh (for SSH server), git, curl, wget
# - Install 'base-devel' for build tools (gcc, make, etc.) often needed for Node native modules or Go projects
# - Install 'which' (VS Code server sometimes needs it)
# - Install 'man-db' and 'man-pages' for documentation (optional but good)
# - Clean up pacman cache
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    sudo \
    openssh \
    git \
    curl \
    wget \
    base-devel \
    which \
    man-db \
    man-pages \
    # Optional: a common editor inside the container
    neovim \
    # Or: vim nano \
    && yes | pacman -Scc

# 2. Configure SSH Server
# -----------------------
# - Generate SSH host keys
# - Allow root login via password (for simplicity in dev, change 'yoursecurepassword')
#   IMPORTANT: For production or shared environments, use key-based auth and a non-root user.
# - Ensure PasswordAuthentication is enabled
RUN ssh-keygen -A && \
    echo "root:yoursecurepassword" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    # For VS Code server to not complain about missing PTY
    sed -i 's/#UsePAM yes/UsePAM yes/' /etc/ssh/sshd_config

# 3. Create a non-root user (Recommended)
# ---------------------------------------
# - User 'devuser' with home directory, bash shell, and added to 'wheel' group (for sudo)
# - Set password for 'devuser' (change 'anothersecurepassword')
# - Allow passwordless sudo for the 'wheel' group (convenient for dev)
RUN useradd -m -s /bin/bash -G wheel devuser && \
    echo "devuser:anothersecurepassword" | chpasswd && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 4. Switch to non-root user for user-specific installations
# ---------------------------------------------------------
USER devuser
WORKDIR /home/devuser

# 5. Install NVM (Node Version Manager), Node.js, and pnpm/yarn (optional)
# --------------------------------------------------------------------
ENV NVM_DIR="/home/devuser/.nvm"
# You can specify a version like "18.17.0" or "lts/hydrogen" or just "node" for latest
ENV NODE_VERSION="--lts"

# Install NVM and specified Node.js version
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install "$NODE_VERSION" && \
    nvm alias default "$NODE_VERSION" && \
    nvm use default && \
    # Optionally install pnpm or yarn globally if you prefer
    # npm install -g pnpm yarn && \
    # Clean npm cache
    npm cache clean --force

# Add NVM to .bashrc so it's sourced automatically in new shells
RUN echo '' >> /home/devuser/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> /home/devuser/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> /home/devuser/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> /home/devuser/.bashrc

# 6. Install Go
# -------------
# Switch back to root to install Go system-wide
USER root
RUN pacman -S --noconfirm go && \
    yes | pacman -Scc

# Switch back to devuser
USER devuser
WORKDIR /home/devuser

# Set up Go environment variables in .bashrc
# Arch installs Go to /usr/bin/go, so GOROOT is usually not needed.
# GOPATH is where your Go projects and their dependencies will live (by default).
# GOBIN is where `go install` will place binaries.
RUN echo '' >> /home/devuser/.bashrc && \
    echo 'export GOPATH="$HOME/go"' >> /home/devuser/.bashrc && \
    echo 'export GOBIN="$GOPATH/bin"' >> /home/devuser/.bashrc && \
    echo 'export PATH="$PATH:$GOBIN"' >> /home/devuser/.bashrc && \
    mkdir -p /home/devuser/go/bin

# 7. Set Locale (to avoid warnings with some tools)
# -------------------------------------------------
USER root
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
ENV LANG=en_US.UTF-8
USER devuser

# 8. Define Workspace and EXPOSE Port
# ----------------------------------
# This will be the directory where your host project code is mounted
WORKDIR /workspace

# Expose SSH port
EXPOSE 22

# 9. Default command to start SSH server
# -------------------------------------
# Using -D to run sshd in the foreground and not daemonize
CMD ["/usr/sbin/sshd", "-D"]