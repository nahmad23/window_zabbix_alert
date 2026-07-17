#!/usr/bin/env bash
# One-time setup on the Ansible (control) server so it can manage
# Windows hosts over WinRM.
set -euo pipefail

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
fi

install_with_pip() {
    if ! command -v pip3 >/dev/null 2>&1; then
        echo "pip3 not found. Install python3-pip first (e.g. apt install python3-pip / yum install python3-pip)."
        return 1
    fi
    if pip3 install --user "pywinrm>=0.4.1" requests-ntlm 2>/dev/null; then
        return 0
    fi
    # Debian/Ubuntu with PEP 668 protection (externally-managed-environment)
    echo ">>> pip refused to install into the system Python (PEP 668); retrying with --break-system-packages..."
    pip3 install --user --break-system-packages "pywinrm>=0.4.1" requests-ntlm
}

echo ">>> Installing Python WinRM dependencies..."
if command -v apt-get >/dev/null 2>&1; then
    # Debian/Ubuntu: prefer distro packages - they install into the same
    # Python that the apt-installed Ansible uses, and PEP 668 blocks pip.
    $SUDO apt-get install -y python3-winrm python3-requests-ntlm || install_with_pip
else
    install_with_pip
fi

echo ">>> Installing required Ansible collections..."
ansible-galaxy collection install -r requirements.yml

echo ">>> Done."
echo "Next steps:"
echo "  1. Create the credentials vault:"
echo "       ansible-vault create inventory/group_vars/zabbix_windows_vault.yml"
echo "     (see inventory/group_vars/zabbix_windows_vault.yml.example for the format)"
echo "  2. Test connectivity:"
echo "       ansible zabbix_windows -m ansible.windows.win_ping --ask-vault-pass"
echo "  3. Run the playbook:"
echo "       ansible-playbook playbooks/update_zabbix_hostname.yml --ask-vault-pass"
