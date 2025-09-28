#!/bin/sh
cd /app > /dev/null
# cf隧道
cloudflaredargo(){
if [ -n "$TUNNEL_TOKEN" ]; then
    if [ ! -e ./bot ]; then
        case $(uname -m) in
        aarch64) cpu=arm64;;
        x86_64) cpu=amd64;;
        *) return 1;;
        esac
        if ! command -v wget &> /dev/null; then
            if command -v apk &> /dev/null
            then
                apk add -y wget
                if [ $? -ne 0 ]; then
                    echo "error：wget install failed!"
                    exit 1
                fi
            else
                echo "error: apk not found!"
                exit 1
            fi
        fi

        if [ -n "$PROXY_URL" ]; then
            proxychains -f /etc/proxychains.conf wget -O ./bot --tries=3 https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu
        else
            wget -O ./bot --tries=3 https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu
        fi

        chmod +x ./bot
        ./bot tunnel --edge-ip-version auto --no-autoupdate --protocol auto run --token $TUNNEL_TOKEN > ./botlog 2>&1 &
    fi
fi
}


if [ -n "$PROXY_URL" ]; then
export HOSTNAME="0.0.0.0";
protocol=$(echo $PROXY_URL | cut -d: -f1);
host=$(echo $PROXY_URL | cut -d/ -f3 | cut -d: -f1);
port=$(echo $PROXY_URL | cut -d: -f3);
conf=/etc/proxychains.conf;
echo "strict_chain" > $conf;
echo "proxy_dns" >> $conf;
echo "remote_dns_subnet 224" >> $conf;
echo "tcp_read_time_out 15000" >> $conf;
echo "tcp_connect_time_out 8000" >> $conf;
echo "localnet 127.0.0.0/255.0.0.0" >> $conf;
echo "localnet ::1/128" >> $conf;
echo "[ProxyList]" >> $conf;
echo "$protocol $host $port" >> $conf;
cat /etc/proxychains.conf;
fi

cloudflaredargo

if [ -n "$PROXY_URL" ]; then
proxychains -f /etc/proxychains.conf node server.mjs;
else
node server.mjs;
fi
