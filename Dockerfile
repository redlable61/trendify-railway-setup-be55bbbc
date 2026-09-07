FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV XRAY_VMESS_AEAD_FORCED=false
ENV XUI_ENABLE_FAIL2BAN=false

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    openssh-server \
    sudo \
    curl \
    wget \
    ca-certificates \
    tar \
    procps \
    iproute2 \
    net-tools \
    nano \
    vim \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Prepare directories
RUN mkdir -p /run/sshd /root/.ssh /data/x-ui

# Install 3X-UI v3.7.0
RUN cd /tmp && \
    wget -q https://github.com/MHSanaei/3x-ui/releases/download/v3.7.0/x-ui-linux-amd64.tar.gz && \
    tar -xzf x-ui-linux-amd64.tar.gz && \
    mv x-ui /usr/local/x-ui && \
    chmod +x /usr/local/x-ui/x-ui && \
    chmod +x /usr/local/x-ui/bin/xray-linux-amd64 && \
    rm -f /tmp/x-ui-linux-amd64.tar.gz

# Remove Ubuntu default Nginx configuration
RUN rm -f /etc/nginx/sites-enabled/default \
    /etc/nginx/conf.d/default.conf

# Create a clean Nginx configuration
RUN cat > /etc/nginx/nginx.conf <<'EOF'
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    keepalive_timeout 65;

    include /etc/nginx/conf.d/*.conf;
}
EOF

# Copy our Nginx configuration
COPY railway.conf /etc/nginx/conf.d/railway.conf

# Copy Railway startup script
COPY start-railway.sh /usr/local/bin/start-railway.sh

RUN chmod +x /usr/local/bin/start-railway.sh

# Railway public port
EXPOSE 8080

# SSH
EXPOSE 22

ENTRYPOINT ["/usr/local/bin/start-railway.sh"]
