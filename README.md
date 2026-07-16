# Zabbix Agent Hostname Update for Windows Servers

Ansible project to update the `Hostname=` parameter in
`C:\Program Files\Zabbix Agent\zabbix_agentd.conf` on Windows servers and
(re)start the **Zabbix Agent** service afterwards.

## Target servers

| Server (inventory name)        | Hostname written to zabbix_agentd.conf |
|--------------------------------|----------------------------------------|
| `UXUS1SIT1UTL019`              | `UXUS1SIT1UTL019`                      |
| `UXUS1SIT1UTL018`              | `UXUS1SIT1UTL018`                      |
| `ggnsitutl06v.unitedlex.global`| `ggnsitutl06v.unitedlex.global`        |

Each server's `Hostname=` is set to its own inventory name
(`zabbix_hostname` defaults to `inventory_hostname`).

## Project layout

```
ansible.cfg                                   # Ansible defaults (inventory path, etc.)
requirements.yml                              # Required Ansible collections
setup_ansible_server.sh                       # One-time control-node setup
inventory/
  hosts.ini                                   # The 3 Windows servers
  group_vars/
    zabbix_windows.yml                        # WinRM connection + Zabbix vars
    zabbix_windows_vault.yml.example          # Credential vault template
playbooks/
  update_zabbix_hostname.yml                  # The playbook to run
roles/
  zabbix_agent_hostname/                      # Backup conf, set Hostname, start service
```

## 1. One-time setup on the Ansible server

```bash
git clone <this-repo> && cd window_zabbix_alert
./setup_ansible_server.sh
```

This installs `pywinrm` (Python WinRM client) and the `ansible.windows` /
`community.windows` collections.

### Create the credentials vault

```bash
ansible-vault create inventory/group_vars/zabbix_windows_vault.yml
```

Content (see the `.example` file):

```yaml
vault_ansible_user: 'UNITEDLEX\svc_ansible'
vault_ansible_password: 'YourPasswordHere'
```

The account must be a local Administrator on the Windows servers.

## 2. One-time setup on the Windows servers (if WinRM is not enabled)

Ansible manages Windows over WinRM. If it is not already configured, run this
in an elevated PowerShell on each server:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/ansible/ansible-documentation/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
Invoke-WebRequest -Uri $url -OutFile ConfigureRemotingForAnsible.ps1
.\ConfigureRemotingForAnsible.ps1
```

Ensure port **5986** (WinRM HTTPS) is open from the Ansible server. If only
**5985** (HTTP) is available, edit `inventory/group_vars/zabbix_windows.yml`
and switch `ansible_port`/`ansible_winrm_scheme` accordingly.

## 3. Test connectivity

```bash
ansible zabbix_windows -m ansible.windows.win_ping --ask-vault-pass
```

All three servers should return `pong`.

## 4. Run the playbook

Dry run first (shows what would change, changes nothing):

```bash
ansible-playbook playbooks/update_zabbix_hostname.yml --ask-vault-pass --check --diff
```

Apply:

```bash
ansible-playbook playbooks/update_zabbix_hostname.yml --ask-vault-pass
```

Limit to a single server:

```bash
ansible-playbook playbooks/update_zabbix_hostname.yml --ask-vault-pass --limit UXUS1SIT1UTL019
```

## What the playbook does on each server

1. Verifies `C:\Program Files\Zabbix Agent\zabbix_agentd.conf` exists
   (fails clearly if the agent is not installed).
2. Takes a timestamped backup of the config file (`*.bak`) — disable with
   `-e zabbix_backup_conf=false`.
3. Sets `Hostname=<server name>` — replaces an existing `Hostname=` line or
   adds one if missing.
4. Restarts the **Zabbix Agent** service if the config changed, and ensures
   the service is set to auto-start and is running either way.

## Overriding the hostname value

If a server ever needs a Zabbix hostname different from its inventory name,
set `zabbix_hostname` as a host variable in `inventory/hosts.ini`, e.g.:

```ini
UXUS1SIT1UTL019 zabbix_hostname=SOME-OTHER-NAME
```
