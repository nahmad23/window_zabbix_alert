#!/usr/bin/env bash
# One-time setup on the Ansible (control) server so it can manage
# Windows hosts over WinRM.
set -euo pipefail

echo ">>> Installing Python WinRM dependencies..."
if command -v pip3 >/dev/null 2>&1; then
    pip3 install --user "pywinrm>=0.4.1" requests-ntlm
else
    echo "pip3 not found. Install python3-pip first (e.g. yum install python3-pip / apt install python3-pip)."
    exit 1
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
