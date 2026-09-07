#!/bin/bash
set -e

echo "======================================"
echo " Starting 3X-UI + Nginx on Railway"
echo "======================================"

mkdir -p /data/x-ui
chmod 700 /data/x-ui

# Railway HTTP service port
PUBLIC_PORT="8080"

# Internal 3X-UI panel
PANEL_PORT="8081"

echo "Public Port: ${PUBLIC_PORT}"
echo "Panel Port: ${PANEL_PORT}"
echo "Database: /data/x-ui"

cd /usr/local/x-ui

echo "Configuring panel..."

./x-ui setting -port "$PANEL_PORT" || true
./x-ui setting -listenIP "127.0.0.1" || true

echo "Starting 3X-UI..."

./x-ui &
XUI_PID=$!

echo "Waiting for 3X-UI..."

for i in $(seq 1 30); do
    if ss -lnt 2>/dev/null | grep -q ":${PANEL_PORT} "; then
        echo "3X-UI is listening on ${PANEL_PORT}"
        break
    fi
    sleep 1
done

echo "Configuring Nginx..."

sed -i "s/listen 8080;/listen ${PUBLIC_PORT};/" \
    /etc/nginx/conf.d/railway.conf

nginx -t

echo "Starting Nginx..."

nginx

echo "Starting SSH..."

/usr/sbin/sshd -D -e &
SSH_PID=$!

trap 'kill $XUI_PID $SSH_PID 2>/dev/null || true; nginx -s quit 2>/dev/null || true' TERM INT

echo "======================================"
echo " 3X-UI : ${PANEL_PORT}"
echo " Nginx : ${PUBLIC_PORT}"
echo " Xray  : 10001 /vless"
echo " Xray  : 21660 / Reality"
echo "======================================"

wait $XUI_PID
