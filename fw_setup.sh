#!/bin/bash
# fw_setup:
#	  __                     _
#	 / _|_      __  ___  ___| |_ _   _ _ __
#	| |_\ \ /\ / / / __|/ _ \ __| | | | '_ \
#	|  _|\ V  V /  \__ \  __/ |_| |_| | |_) |
#	|_|   \_/\_/___|___/\___|\__|\__,_| .__/
#	          |_____|                 |_|
#
# 	    fw_setup is a command-line firewall setup written in  bash 5.2+.
#           fw_setup will handle iptables, nftables, ufw and firewalld
#           fw_setup uses ss to scan for listening ports on tcp or udp protocols
#           and automatically add them to the firewall rules
#           fw_setup also has a safety lockout feature where preserves ssh ports
#           default ssh is port 22, you can modify the port number below
#
# The MIT License (MIT)
#
# Copyright (c) 2024-2025 DJ Ware - Cybergizmo
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# version=0.8

echo "🚨 WARNING: THIS IS A BETA FIREWALL SCRIPT 🚨"
echo "DO NOT RUN THIS ON A PRODUCTION SERVER!"
echo "MAKE SURE YOU HAVE A MONITOR & KEYBOARD ATTACHED IN CASE OF LOCKOUT!"
echo ""
read -p "Type 'YES' to continue or anything else to EXIT: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
    echo "Exiting script. No changes were made."
    exit 1
fi

echo "Proceeding with firewall setup..."
sleep 3  # Give them a moment before running critical commands
# =======================
# ✅ PRE-CHECK FOR REQUIRED TOOLS
# =======================

# Check if at least one firewall tool is installed
if command -v firewall-cmd &>/dev/null; then
    FIREWALL="firewalld"
elif command -v ufw &>/dev/null; then
    FIREWALL="ufw"
elif command -v iptables &>/dev/null; then
    FIREWALL="iptables"
elif command -v nft &>/dev/null; then
    FIREWALL="nftables"
else
    echo "Error: No firewall tool found. Install iptables, nftables, ufw, or firewalld."
    exit 1
fi

# Check if 'ss' is installed; if not, exit
if ! command -v ss &>/dev/null; then
    echo "Error: 'ss' command is missing. Please install 'iproute2' package."
    exit 1
fi

echo "Detected firewall: $FIREWALL"
echo "Pre-check passed. Proceeding with firewall setup..."

# =======================
# ✅ USER-DEFINED SSH PORT (SET THIS BEFORE RUNNING)
# =======================
SSH_PORT=22  # Change this as needed

# =======================
# 🔥 STEP 1: FLUSH ALL FIREWALL RULES
# =======================
echo "Flushing all firewall rules..."
if [[ "$FIREWALL" == "iptables" ]]; then
    iptables -P INPUT ACCEPT  # Keep open while adding rules
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -t nat -F
    iptables -t mangle -F
    iptables -F
    iptables -X
elif [[ "$FIREWALL" == "nftables" ]]; then
    nft flush ruleset
elif [[ "$FIREWALL" == "firewalld" ]]; then
    firewall-cmd --reload
elif [[ "$FIREWALL" == "ufw" ]]; then
    ufw --force reset
    ufw default allow incoming  # Allow until rules are set
    ufw default allow outgoing
fi

# =======================
# 🔥 STEP 2: BASE RULES (LOOPBACK, ESTABLISHED, ICMP, NTP)
# =======================
echo "Applying base security rules..."

if [[ "$FIREWALL" == "iptables" ]]; then
    iptables -A INPUT -i lo -j ACCEPT  # Allow loopback traffic
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT  # Allow established connections
    iptables -A INPUT -p icmp -j ACCEPT  # Allow ping
    iptables -A OUTPUT -p udp --dport 123 -j ACCEPT  # Allow NTP sync
    iptables -A INPUT -p udp --sport 123 -j ACCEPT
elif [[ "$FIREWALL" == "ufw" ]]; then
    ufw allow out 123/udp  # NTP
    ufw allow in 123/udp
    ufw allow proto icmp  # Allow ping
elif [[ "$FIREWALL" == "firewalld" ]]; then
    firewall-cmd --permanent --add-service=ntp
    firewall-cmd --permanent --add-service=icmp
fi

# =======================
# 🔥 STEP 3: ENSURE SSH ACCESS (PREVENT LOCKOUT)
# =======================
echo "Ensuring SSH access on port $SSH_PORT..."
if [[ "$FIREWALL" == "iptables" ]]; then
    iptables -A INPUT -p tcp --dport $SSH_PORT -j ACCEPT
elif [[ "$FIREWALL" == "ufw" ]]; then
    ufw allow $SSH_PORT/tcp
elif [[ "$FIREWALL" == "firewalld" ]]; then
    firewall-cmd --permanent --add-port=${SSH_PORT}/tcp
fi

# =======================
# 🔥 STEP 4: DETECT OPEN PORTS & APPLY RULES (TCP & UDP)
# =======================
echo "Scanning open ports..."
IFS=$'\n' read -d '' -r -a PORTS < <(ss -tulnp | awk '{if ($1 ~ /tcp|udp/) {split($5, a, ":"); if (a[length(a)] ~ /^[0-9]+$/) print $1, a[length(a)]}}')

echo "Detected open ports (excluding SSH):"
printf "%s\n" "${PORTS[@]}"

for line in "${PORTS[@]}"; do
    PROTOCOL=$(echo "$line" | awk '{print $1}')
    PORT=$(echo "$line" | awk '{print $2}')

    if [[ -z "$PORT" || -z "$PROTOCOL" || "$PORT" == "$SSH_PORT" ]]; then
        continue
    fi

    echo "Applying firewall rule: Allow $PROTOCOL port $PORT"

    if [[ "$FIREWALL" == "iptables" ]]; then
        iptables -A INPUT -p ${PROTOCOL} --dport ${PORT} -j ACCEPT
        echo "✔ iptables: Allowed $PROTOCOL port $PORT"
    elif [[ "$FIREWALL" == "ufw" ]]; then
        ufw allow ${PORT}/${PROTOCOL}
        echo "✔ ufw: Allowed $PROTOCOL port $PORT"
    elif [[ "$FIREWALL" == "firewalld" ]]; then
        firewall-cmd --permanent --add-port=${PORT}/${PROTOCOL}
        echo "✔ firewalld: Allowed $PROTOCOL port $PORT"
    fi
done

# =======================
# 🔥 STEP 5: SET FINAL DROP RULE & CHANGE INPUT POLICY
# =======================
echo "Setting logging and final DROP rule..."

if [[ "$FIREWALL" == "iptables" ]]; then
    # Log dropped packets (rate-limited to avoid flooding logs)
    iptables -A INPUT -m limit --limit 15/min -j LOG --log-prefix "FW DROP: " --log-level 7

    # Ensure DROP rule is last
    iptables -A INPUT -j DROP
    iptables -P INPUT DROP  # Now change policy to DROP after rules are set

    echo "✔ iptables: Final DROP rule and logging added."
elif [[ "$FIREWALL" == "nftables" ]]; then
    nft add rule inet myfirewall input log prefix "FW DROP: " limit rate 15/minute
    nft add rule inet myfirewall input drop
    echo "✔ nftables: Final DROP rule and logging added."
elif [[ "$FIREWALL" == "firewalld" ]]; then
    firewall-cmd --permanent --set-target=DROP
elif [[ "$FIREWALL" == "ufw" ]]; then
    ufw logging on
    ufw default deny incoming
fi

# =======================
# 🔥 STEP 6: FINALIZE & RELOAD FIREWALL
# =======================
if [[ "$FIREWALL" == "firewalld" ]]; then
    firewall-cmd --reload
elif [[ "$FIREWALL" == "ufw" ]]; then
    ufw reload
fi

echo "Firewall setup completed."
