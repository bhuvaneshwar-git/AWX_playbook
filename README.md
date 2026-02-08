# AWX playbook

This repository contains automation playbooks executed and managed using **AWX (Ansible Tower)** for Linux system administration tasks.

## Playbooks Included

- `ping_playbook.yaml`  
  Tests connectivity between AWX and target hosts.

- `system_information_playbook.yml`  
  Collects basic system information from managed nodes.

- `updated_sysinformation_playbook.yml`  
  Gathers detailed system facts via AWX job templates.

- `accesscontrol_playbook.yaml`  
  Automates user access and permission configuration.

- `linux_hardening_playbook.yml`  
  Applies baseline Linux security hardening controls.

- `update_chrome.yml`  
  Automates Google Chrome update via AWX jobs.

- `set_wallpaper.yml`  
  Automates desktop wallpaper configuration.
  
## Tools & Technologies

- AWX (Ansible Tower)
- YAML
- Linux System Administration
- SSH

## Execution

Playbooks are executed through **AWX Job Templates** using configured inventories and credentials.

## Purpose

- Minimize manual intervention in infrastructure and application management activities
- Improve operational efficiency and service delivery timelines.
