#!/bin/bash
export HOME=/root
export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

mkdir -p /root/.openclaw

curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard --version ${openclaw_version}

cat <<EOF > /root/.openclaw/.env
AWS_PROFILE=default
AWS_REGION=${aws_region}
AWS_DEFAULT_REGION=${aws_region}
EOF

cat <<EOF > /root/.openclaw/openclaw.json
{
  "gateway": {
    "mode": "local",
    "port": ${openclaw_port},
    "bind": "loopback",
    "controlUi": {
      "enabled": true,
      "allowInsecureAuth": true
    },
    "auth": {
      "mode": "token",
      "token": "${openclaw_token}"
    }
  },
  "plugins": {
    "entries": {
      "amazon-bedrock": {
        "enabled": true
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${openclaw_model}"
      }
    }
  }
}
EOF

#=====================================================================================
# Install and Start OpenClaw Gateway Service - Workaround
loginctl enable-linger root 2>/dev/null || true
systemctl start user@0.service
for i in $(seq 1 15); do
  [ -S /run/user/0/bus ] && break
  echo "Waiting for user session... $i/15"
  sleep 2
done
[ -S /run/user/0/bus ] || exit 1
export XDG_RUNTIME_DIR=/run/user/0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/0/bus

openclaw gateway install
systemctl --user start openclaw-gateway.service || openclaw gateway start
echo "OpenClaw should be Ready to use!"
#=====================================================================================