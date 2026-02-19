FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Update package manager
RUN apt-get update && apt-get upgrade -y

# Install Git
RUN apt-get install -y git

# Install Python 3.11
RUN apt-get install -y python3.11 python3.11-venv python3-pip && \
    ln -sf /usr/bin/python3.11 /usr/bin/python && \
    ln -sf /usr/bin/python3.11 /usr/local/bin/python

# Install Docker CLI
RUN apt-get install -y docker.io

# Install Node.js and npm (required for gemini-cli)
RUN apt-get install -y nodejs npm

# Install Terraform
RUN apt-get install -y wget unzip && \
    wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip && \
    unzip terraform_1.7.0_linux_amd64.zip -d /usr/local/bin && \
    rm terraform_1.7.0_linux_amd64.zip && \
    terraform version

# Install AWS CLI
RUN apt-get install -y awscli

# Install gemini-cli globally
RUN npm install -g gemini-cli

# Clean up apt cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
