#!/bin/bash
# Sigma to Wazuh Rules Converter Script
# Downloads Sigma rules and converts them to Wazuh format
# Uses the sigWah converter for Windows Sysmon rules

set -e

WAZUH_RULES_DIR="/var/ossec/etc/rules"
SIGMA_REPO="https://github.com/SigmaHQ/sigma.git"
SIGWAH_REPO="https://github.com/SanWieb/sigWah.git"
WORK_DIR="/opt/wazuh/sigma"

echo "[*] Setting up Sigma to Wazuh conversion..."

# Install required packages
if command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y python3 python3-pip git
elif command -v yum &> /dev/null; then
    yum install -y python3 python3-pip git
fi

# Create work directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Clone sigWah converter if not exists
if [ ! -d "sigWah" ]; then
    echo "[*] Cloning sigWah converter..."
    git clone "$SIGWAH_REPO" sigWah
fi

# Clone Sigma rules if not exists
if [ ! -d "sigma" ]; then
    echo "[*] Cloning Sigma rules repository..."
    git clone --depth 1 "$SIGMA_REPO" sigma
fi

# Install Python dependencies
pip3 install PyYAML

# Run the sigWah converter for Windows Sysmon rules
cd sigWah
echo "[*] Converting Sigma rules to Wazuh format..."

python3 sigWah.py \
    --rulesdir ../sigma/rules/windows/sysmon \
    --outfile sigma_sysmon_rules.xml \
    --ruleid 110000 \
    --level 10 \
    2>/dev/null || true

# Also convert process creation rules
python3 sigWah.py \
    --rulesdir ../sigma/rules/windows/process_creation \
    --outfile sigma_process_rules.xml \
    --ruleid 111000 \
    --level 10 \
    2>/dev/null || true

# Copy generated rules to Wazuh
if [ -f "sigma_sysmon_rules.xml" ]; then
    echo "[*] Installing Sigma Sysmon rules..."
    cp sigma_sysmon_rules.xml "$WAZUH_RULES_DIR/"
    chown wazuh:wazuh "$WAZUH_RULES_DIR/sigma_sysmon_rules.xml"
    chmod 660 "$WAZUH_RULES_DIR/sigma_sysmon_rules.xml"
fi

if [ -f "sigma_process_rules.xml" ]; then
    echo "[*] Installing Sigma process creation rules..."
    cp sigma_process_rules.xml "$WAZUH_RULES_DIR/"
    chown wazuh:wazuh "$WAZUH_RULES_DIR/sigma_process_rules.xml"
    chmod 660 "$WAZUH_RULES_DIR/sigma_process_rules.xml"
fi

# Restart Wazuh to apply new rules
echo "[*] Restarting Wazuh Manager..."
systemctl restart wazuh-manager

echo "[+] Sigma rules conversion completed!"
echo "[+] Rules installed to: $WAZUH_RULES_DIR"
