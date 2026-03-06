FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Update package manager
RUN apt-get update && apt-get upgrade -y

# Install Git
RUN apt-get install -y git

# Install Python 3
RUN apt-get install -y python3 python3-venv python3-pip && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/python3 /usr/local/bin/python

# Install Docker CLI
RUN apt-get install -y docker.io

# Install Node.js 20 LTS and npm (required for gemini-cli; Node.js v20+ needed for the regex 'v' flag used by string-width)
# The NodeSource setup script is the officially documented install method: https://github.com/nodesource/distributions
RUN apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN apt-get install -y wget unzip && \
    wget https://releases.hashicorp.com/terraform/1.14.6/terraform_1.14.6_linux_amd64.zip && \
    unzip terraform_1.14.6_linux_amd64.zip -d /usr/local/bin && \
    rm terraform_1.14.6_linux_amd64.zip && \
    terraform version

# Install gemini-cli globally
RUN npm install -g @google/gemini-cli

# Clean up apt cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
