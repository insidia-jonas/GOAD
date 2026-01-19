#!/usr/bin/env bash

# This source code come from the opensource project DetectionLab : https://github.com/clong/DetectionLab
# This script is meant to verify that your system is configured to build the lab successfully.

ERROR=$(tput setaf 1; echo -n "  [!]"; tput sgr0)
GOODTOGO=$(tput setaf 2; echo -n "  [✓]"; tput sgr0)
INFO=$(tput setaf 3; echo -n "  [-]"; tput sgr0)

PROVIDERS="virtualbox vmware azure proxmox vmware_esxi ludus aws"
ANSIBLE_HOSTS="docker local"
LABS="GOAD NHA SCCM"
print_usage() {
  echo "Usage: ./check.sh <provider> <ansible_host>"
  echo "provider must be one of the following:"
  for p in $PROVIDERS;  do
    echo " - $p";
  done
  echo "Ansible host must be one of the following:"
  for a in $ANSIBLE_HOSTS;  do
    echo " - $a";
  done
  exit 0
}

if [ $# -lt 2 ]; then
  print_usage
else
  PROVIDER=$1
  ANSIBLE_HOST=$2
fi

check_vagrant_path() {
  if ! which vagrant >/dev/null; then
    (echo >&2 "${ERROR} Vagrant was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing Vagrant : https://www.vagrantup.com/downloads.html")
    exit 1
  else
    (echo >&2 "${GOODTOGO} Vagrant was found in your PATH")

    # Ensure Vagrant >= 2.2.9
    # https://unix.stackexchange.com/a/285928
    VAGRANT_VERSION="$(vagrant --version | cut -d ' ' -f 2)"
    REQUIRED_VERSION="2.2.9"
    # If the version of Vagrant is not greater or equal to the required version
    if ! [ "$(printf '%s\n' "$REQUIRED_VERSION" "$VAGRANT_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        (echo >&2 "${ERROR} WARNING: It is highly recommended to use Vagrant $REQUIRED_VERSION or above before continuing")
    else 
        (echo >&2 "${GOODTOGO} Your version of Vagrant ($VAGRANT_VERSION) is supported")
    fi
  fi
}

check_packer_path() {
  if ! which packer >/dev/null; then
    (echo >&2 "${ERROR} packer was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing packer : https://developer.hashicorp.com/packer/docs/install")
    exit 1
  else
    (echo >&2 "${GOODTOGO} packer was found in your PATH")
  fi
}

check_terraform_path() {
  if ! which terraform >/dev/null; then
    (echo >&2 "${ERROR} terraform was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing terraform : https://developer.hashicorp.com/terraform/downloads")
    exit 1
  else
    (echo >&2 "${GOODTOGO} terraform was found in your PATH")
  fi
}

check_sshpass_path() {
  if ! which sshpass >/dev/null; then
    (echo >&2 "${ERROR} sshpass was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing sshpass")
    exit 1
  else
    (echo >&2 "${GOODTOGO} sshpass was found in your PATH")
  fi
}

# Returns 0 if not installed or 1 if installed
check_virtualbox_installed() {
  if ! which VBoxManage >/dev/null; then
    (echo >&2 "${ERROR} VBoxManage was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing virtualbox")
    exit 1
  else
    (echo >&2 "${GOODTOGO} virtualbox is installed")
  fi
}

check_aws_installed() {
  if ! which aws >/dev/null; then
    (echo >&2 "${ERROR} aws was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing aws (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)")
    exit 1
  else
    (echo >&2 "${GOODTOGO} aws is installed")
  fi
}

check_azure_installed() {
  if ! which az >/dev/null; then
    (echo >&2 "${ERROR} az was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing az (https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)")
    exit 1
  else
    (echo >&2 "${GOODTOGO} azure is installed")
  fi
}

check_rsync_path() {
  if ! which rsync >/dev/null; then
    (echo >&2 "${ERROR} rsync was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    exit 1
  else
    (echo >&2 "${GOODTOGO} rsync was found in your PATH")
  fi
}

# Returns 0 if not installed or 1 if installed
# Check for VMWare Workstation on Linux
check_vmware_workstation_installed() {
  if ! which vmrun >/dev/null; then
    (echo >&2 "${ERROR} vmrun was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing vmware")
    exit 1
  else
    (echo >&2 "${GOODTOGO} vmware is installed")
  fi
}

check_docker_installed() {
  if ! which docker >/dev/null; then
    (echo >&2 "${ERROR} docker was not found in your PATH.")
  else
    (echo >&2 "${GOODTOGO} docker is installed")
  fi
}

check_ansible_installed() {
  if ! which ansible >/dev/null; then
    (echo >&2 "${ERROR} ansible was not found in your PATH.")
  else
    (echo >&2 "${GOODTOGO} ansible is installed")
  fi
}

check_python_env(){
  if ! which python3 >/dev/null; then
    (echo >&2 "${ERROR} python3 was not found in your PATH.")
  else
    (echo >&2 "${GOODTOGO} python3 is installed")
    PYTHON_VERSION=$(python3 --version | cut -d ' ' -f 2)
    REQUIRED_VERSION="3.8"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
      (echo >&2 "${GOODTOGO} python3 ($PYTHON_VERSION) is supported")
      check_ansible_env
    else
      (echo >&2 "${ERROR} python3 ($PYTHON_VERSION) is not supported start checking other available python interpreter")
      check_python_venv
      exit 1
    fi
  fi
}

check_python_venv(){
    PYTHON_INSTALLED=$(ls -1 /usr/bin/python* | grep '.*[3]\(.[0-9]\+\)\?$')
    REQUIRED_VERSION="3.8"
    GOOD_PYTHON=""
    (echo >&2 "${GOODTOGO} Supported python3 interpreter :")
    for python_interpreter in $PYTHON_INSTALLED;  do
      PYTHON_VERSION="$($python_interpreter --version | cut -d ' ' -f 2)"
      # If the version of python is not greater or equal to the required version
      if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
          (echo >&2 "  ${GOODTOGO} $python_interpreter ($PYTHON_VERSION) is supported")
          GOOD_PYTHON=$(echo "$GOOD_PYTHON" "$python_interpreter")
      fi
    done

    INTERPRETER_FOUND=0
    if [ "$GOOD_PYTHON" != "" ]; then
      (echo >&2 "${GOODTOGO} Verify python3 available environment :")
      for python in $GOOD_PYTHON; do
        (echo >&2 "${GOODTOGO} Checking $python :")
        VENV_FOUND=0
        VIRTUALENV_FOUND=0
        PIP_FOUND=0
        if [ "$($python -m venv -h 2>/dev/null | grep -i 'usage:')" ]; then
          (echo >&2 "  ${GOODTOGO} $python venv module is installed")
          VENV_FOUND=1
        else
          (echo >&2 "  ${ERROR} $python venv module not installed")
        fi

        if [ "$($python -m virtualenv -h 2>/dev/null | grep -i 'usage:')" ]; then
          (echo >&2 "  ${GOODTOGO} $python virtualenv module is installed")
          VIRTUALENV_FOUND=1
        else
          (echo >&2 "  ${ERROR} $python virtualenv module not installed")
        fi

        if [ "$($python -m pip -h 2>/dev/null | grep -i 'usage:')" ]; then
          (echo >&2 "  ${GOODTOGO} $python pip module is installed")
          PIP_FOUND=1
        else
          (echo >&2 "  ${ERROR} $python pip module not installed")
        fi

        if [[ $PIP_FOUND -eq 1 ]] && [[ $VENV_FOUND -eq 1 || $VIRTUALENV_FOUND -eq 1 ]]; then
          if [ "$VIRTUALENV_FOUND" -eq 1 ]; then
            (echo >&2 "  ${GOODTOGO} $python environment is available consider creating a venv : \"$python -m virtualenv .venv\", activate it with source .venv/bin/activate and relaunch the prepare script")
          else
            (echo >&2 "  ${GOODTOGO} $python environment is available consider creating a venv : \"$python -m venv .venv\", activate it with source .venv/bin/activate and relaunch the prepare script")
          fi
          INTERPRETER_FOUND=1
        fi
      done
    fi

    if [ "$INTERPRETER_FOUND" -eq 1 ]; then
      (echo >&2 "  ${ERROR} no available interpreter found, please install pip and venv")
    fi
}

check_ansible_env(){
  (echo >&2 "${GOODTOGO} Checking if python3 env is ansible ready :")
  ANSIBLE_CORE_CHECK=$(python3 -m pip --disable-pip-version-check list|grep -c ansible-core)
  if [ "$ANSIBLE_CORE_CHECK" -eq 1 ]; then
    ANSIBLE_VERSION=$(python3 -m pip --disable-pip-version-check list|grep ansible-core|cut -d ' ' -f 2-|sed -e 's/ //g' )
    REQUIRED_VERSION="2.12.6"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$ANSIBLE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
      (echo >&2 "  ${GOODTOGO} ansible-core $ANSIBLE_VERSION  is supported")
    else
      (echo >&2 "  ${ERROR} $ANSIBLE_VERSION  is not supported consider doing :")
      echo "        python3 -m pip install ansible-core==2.12.6"
    fi
  else
    (echo >&2 "  ${ERROR} ansible-core is not installed consider doing :")
    echo "        python3 -m pip install ansible-core==2.12.6"
  fi

  PYWINRM_CHECK=$(python3 -m pip --disable-pip-version-check list |grep -c pywinrm )
  if [ "$PYWINRM_CHECK" -eq 1 ]; then
    (echo >&2 "  ${GOODTOGO} pywinrm is installed")
  else
    (echo >&2 "  ${ERROR} pywinrm  is not install consider doing :")
    echo "        python3 -m pip install pywinrm"
    exit 1
  fi

  if ! which ansible >/dev/null; then
    (echo >&2 "${ERROR} ansible was not found in your PATH abort")
    exit 1
  else
    (echo >&2 "${GOODTOGO} ansible is installed")
  fi

  if ! which ansible-galaxy >/dev/null; then
    (echo >&2 "${ERROR} ansible-galaxy was not found in your PATH abort")
    exit 1
  else
    (echo >&2 "${GOODTOGO} ansible-galaxy is installed")
  fi

  GALAXY_COLLECTION=$(ansible-galaxy collection list)
  ANSIBLE_COLLECTION_EXPECTED="community.windows community.general ansible.windows"
  GALAXY_OK=1
  for collection in $ANSIBLE_COLLECTION_EXPECTED; do
    if [ $(echo $GALAXY_COLLECTION|grep -c $collection) -eq 1 ]; then
      (echo >&2 "  ${GOODTOGO} ansible-galaxy collection $collection installed")
    else
      (echo >&2 "  ${ERROR} ansible-galaxy collection $collection not installed")
      GALAXY_OK=0
    fi
  done
  if [ $GALAXY_OK -eq 0 ]; then
    (echo >&2 "${ERROR} ansible-galaxy requirements missing consider doing : ansible-galaxy install -r ansible/requirements.yml")
    exit 1
  else
    (echo >&2 "${GOODTOGO} ansible-galaxy requirements ok")
  fi
}

# Returns 0 if not installed or 1 if installed
check_vmware_desktop_vagrant_plugin_installed() {
  LEGACY_PLUGIN_CHECK="$(vagrant plugin list | grep -c 'vagrant-vmware-fusion')"
  if [ "$LEGACY_PLUGIN_CHECK" -gt 0 ]; then
    (echo >&2 "${ERROR} The VMware Fusion Vagrant plugin is deprecated and is no longer supported.")
    (echo >&2 "${INFO} Please upgrade to the VMware Desktop plugin: https://www.vagrantup.com/docs/vmware/installation.html")
    (echo >&2 "${INFO} Please also uninstall the vagrant-vmware-fusion plugin and install the vmware-vagrant-desktop plugin")
    (echo >&2 "${INFO} HINT: \`vagrant plugin uninstall vagrant-vmware-fusion && vagrant plugin install vagrant-vmware-desktop\`")
    (echo >&2 "${INFO} NOTE: The VMware plugin does not work with trial versions of VMware Fusion")
    exit 1
  fi

  VMWARE_DESKTOP_PLUGIN_PRESENT="$(vagrant plugin list | grep -c 'vagrant-vmware-desktop')"
  if [ "$VMWARE_DESKTOP_PLUGIN_PRESENT" -eq 0 ]; then
    (echo >&2 "VMWare Fusion or Workstation is installed, but the vagrant-vmware-desktop plugin is not.")
    (echo >&2 "Visit https://www.hashicorp.com/blog/introducing-the-vagrant-vmware-desktop-plugin for more information on how to purchase and install it")
    (echo >&2 "VMWare Fusion or Workstation will not be listed as a provider until the vagrant-vmware-desktop plugin has been installed.")
    exit 1
  else
    (echo >&2 "${GOODTOGO} vagrant-vmware-desktop plugin installed")
  fi
}

check_vagrant_vmware_utility_installed() {
  # Ensure the helper utility is installed: https://www.vagrantup.com/docs/providers/vmware/vagrant-vmware-utility
  if ! pgrep -f vagrant-vmware-utility > /dev/null; then
    (echo >&2 "${ERROR} vagrant-vmware-utility is not installed (https://developer.hashicorp.com/vagrant/docs/providers/vmware/vagrant-vmware-utility)")
    exit 1
  else
    (echo >&2 "${GOODTOGO} vagrant-vmware-utility installed")
  fi
}

# Check to see if any Vagrant instances exist already
check_vagrant_instances_exist() {
  cd "$VAGRANT_DIR"|| exit 1
  # Vagrant status has the potential to return a non-zero error code, so we work around it with "|| true"
  VAGRANT_STATUS_OUTPUT=$(vagrant status)
  VAGRANT_BUILT=$(echo "$VAGRANT_STATUS_OUTPUT" | grep -c 'not created') || true
  if [ "$VAGRANT_BUILT" -ne 4 ]; then
    (echo >&2 "${INFO} You appear to have already created at least one Vagrant instance:")
    # shellcheck disable=SC2164
    cd "$VAGRANT_DIR" && echo "$VAGRANT_STATUS_OUTPUT" | grep -v 'not created' | grep -E 'logger|dc|wef|win10' 
    (echo >&2 "${INFO} If you want to start with a fresh install, you should run \`vagrant destroy -f\` to remove existing instances.")
  else 
    (echo >&2 "${GOODTOGO} No Vagrant instances have been created yet")
  fi
}

check_vagrant_reload_plugin() {
  # Ensure the vagrant-reload plugin is installed
  VAGRANT_RELOAD_PLUGIN_INSTALLED=$(vagrant plugin list | grep -c 'vagrant-reload')
  if [ "$VAGRANT_RELOAD_PLUGIN_INSTALLED" != "1" ]; then
    (echo >&2 "${ERROR} The vagrant-reload plugin is required and was not found. This script will attempt to install it now.")
    if ! $(which vagrant) plugin install "vagrant-reload"; then
      (echo >&2 "Unable to install the vagrant-reload plugin. Please try to do so manually and re-run this script.")
      exit 1
    else 
      (echo >&2 "${GOODTOGO} The vagrant-reload plugin was successfully installed!")
    fi
  else
    (echo >&2 "${GOODTOGO} The vagrant-reload plugin is currently installed")
  fi
}

check_vagrant_esxi_plugin() {
  # Ensure the vagrant-vmware-esxi plugin is installed
  VAGRANT_ESXI_PLUGIN_INSTALLED=$(vagrant plugin list | grep -c 'vagrant-vmware-esxi')
  if [ "$VAGRANT_ESXI_PLUGIN_INSTALLED" != "1" ]; then
    (echo >&2 "${ERROR} The vagrant-vmware-esxi plugin is required and was not found. This script will attempt to install it now.")
    if ! $(which vagrant) plugin install "vagrant-vmware-esxi"; then
      (echo >&2 "Unable to install the vagrant-vmware-esxi plugin. Please try to do so manually and re-run this script.")
      exit 1
    else 
      (echo >&2 "${GOODTOGO} The vagrant-vmware-esxi plugin was successfully installed!")
    fi
  else
    (echo >&2 "${GOODTOGO} The vagrant-vmware-esxi plugin is currently installed")
  fi
}

check_vagrant_env_plugin() {
  # Ensure the vagrant-env plugin is installed
  VAGRANT_ENV_PLUGIN_INSTALLED=$(vagrant plugin list | grep -c 'vagrant-env')
  if [ "$VAGRANT_ENV_PLUGIN_INSTALLED" != "1" ]; then
    (echo >&2 "${ERROR} The vagrant-env plugin is required and was not found. This script will attempt to install it now.")
    if ! $(which vagrant) plugin install "vagrant-env"; then
      (echo >&2 "Unable to install the vagrant-env plugin. Please try to do so manually and re-run this script.")
      exit 1
    else 
      (echo >&2 "${GOODTOGO} The vagrant-env plugin was successfully installed!")
    fi
  else
    (echo >&2 "${GOODTOGO} The vagrant-env plugin is currently installed")
  fi
}

check_ovftool_installed() {
  if ! which ovftool >/dev/null; then
    (echo >&2 "${ERROR} ovftool was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing appropriate ovftool version for your environment : https://developer.broadcom.com/tools/open-virtualization-format-ovf-tool/latest")
    exit 1
  else
    OVFTOOL_VERSION=$(ovftool -v | cut -d ' ' -f 3)
    (echo >&2 "${GOODTOGO} ovftool (${OVFTOOL_VERSION}) is installed, make sure that version matches your ESXi environment")
  fi
}

# Check available disk space. Recommend 120GB free, warn if less.
check_disk_free_space() {
  FREE_DISK_SPACE=$(df -m "$HOME" | tr -s ' ' | grep '/' | cut -d ' ' -f 4)
  if [ "$FREE_DISK_SPACE" -lt 120000 ]; then
    (echo >&2 "${INFO} Warning: You appear to have less than 120GB of HDD space free on your primary partition. If you are using a separate parition, you may ignore this warning.\n")
  else
    (echo >&2 "${GOODTOGO} You have more than 120GB of free space on your primary partition")
  fi
}

check_ram_space() {
  RAM_SPACE=$(free|tr -s ' '|grep Mem|cut -d ' ' -f 2)
  if [ "$RAM_SPACE" -lt 24000000 ]; then
    (echo >&2 "${INFO} Warning: You appear to have less than 24GB of RAM on your disk, you should consider running only a part of the lab.\n")
  else
    (echo >&2 "${GOODTOGO} You have more than 24GB of ram")
  fi
}

# ============================================================================
# LUDUS PROVIDER CHECKS
# ============================================================================

check_ludus_installed() {
  if ! which ludus >/dev/null; then
    (echo >&2 "${ERROR} ludus CLI was not found in your PATH.")
    (echo >&2 "${ERROR} Please install ludus: https://docs.ludus.cloud/")
    exit 1
  else
    (echo >&2 "${GOODTOGO} ludus CLI is installed")
  fi
}

check_ludus_range() {
  if which ludus >/dev/null; then
    LUDUS_RANGE=$(ludus range list 2>/dev/null | grep -E "^[0-9]+" | head -1)
    if [ -n "$LUDUS_RANGE" ]; then
      RANGE_ID=$(echo "$LUDUS_RANGE" | awk '{print $1}')
      (echo >&2 "${GOODTOGO} Ludus range found: ID=$RANGE_ID")
      (echo >&2 "${INFO} Your IP range is likely: 10.${RANGE_ID}.10.x")
    else
      (echo >&2 "${INFO} No Ludus range found. Create one with: ludus range create")
    fi
  fi
}

check_ludus_templates() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  GOAD_DIR="$(dirname "$SCRIPT_DIR")"
  LAB_NAME="${LAB:-GOAD}"

  (echo >&2 "[+] Checking Ludus VM templates for $LAB_NAME")

  # Required templates for GOAD (extracted from config.yml)
  REQUIRED_TEMPLATES="win2022-server-x64-template win2012r2-server-x64-template win11-22h2-x64-enterprise-template win10-22h2-x64-enterprise-template debian-12-x64-server-template kali-x64-desktop-template"

  # Get available templates from Ludus
  if ! which ludus >/dev/null 2>&1; then
    (echo >&2 "  ${ERROR} ludus CLI not found, skipping template check")
    return 1
  fi

  AVAILABLE_TEMPLATES=$(ludus templates list 2>/dev/null | tail -n +3 | awk '{print $1}')

  if [ -z "$AVAILABLE_TEMPLATES" ]; then
    (echo >&2 "  ${ERROR} Could not retrieve Ludus templates. Are you logged in? Try: ludus auth login")
    return 1
  fi

  MISSING_TEMPLATES=""
  TEMPLATES_OK=1

  for template in $REQUIRED_TEMPLATES; do
    if echo "$AVAILABLE_TEMPLATES" | grep -q "^${template}$"; then
      (echo >&2 "  ${GOODTOGO} Template available: $template")
    else
      (echo >&2 "  ${ERROR} Template missing: $template")
      MISSING_TEMPLATES="$MISSING_TEMPLATES $template"
      TEMPLATES_OK=0
    fi
  done

  if [ $TEMPLATES_OK -eq 0 ]; then
    (echo >&2 "")
    (echo >&2 "${INFO} Missing templates detected. Would you like to add them? (y/n)")
    read -r REPLY
    if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
      add_ludus_templates "$MISSING_TEMPLATES"
    else
      (echo >&2 "${INFO} You can manually add templates with:")
      for template in $MISSING_TEMPLATES; do
        (echo >&2 "  ludus templates add -n $template")
      done
      (echo >&2 "")
      (echo >&2 "${INFO} Or build templates with: ludus templates build")
    fi
  else
    (echo >&2 "${GOODTOGO} All required Ludus templates are available")
  fi
}

add_ludus_templates() {
  TEMPLATES_TO_ADD="$1"

  (echo >&2 "[+] Adding missing Ludus templates...")

  for template in $TEMPLATES_TO_ADD; do
    (echo >&2 "  ${INFO} Adding template: $template")

    # Map template names to Ludus template add commands
    case $template in
      "win2022-server-x64-template")
        ludus templates add -n "$template" 2>&1 | while read line; do echo "    $line"; done
        ;;
      "win2012r2-server-x64-template")
        ludus templates add -n "$template" 2>&1 | while read line; do echo "    $line"; done
        ;;
      "win11-22h2-x64-enterprise-template")
        ludus templates add -n "$template" 2>&1 | while read line; do echo "    $line"; done
        ;;
      "win10-22h2-x64-enterprise-template")
        ludus templates add -n "$template" 2>&1 | while read line; do echo "    $line"; done
        ;;
      "debian-12-x64-server-template")
        ludus templates add -n "$template" 2>&1 | while read line; do echo "    $line"; done
        ;;
      "kali-x64-desktop-template")
        ludus templates add -n "$template" 2>&1 | while read line; do echo "    $line"; done
        ;;
      *)
        (echo >&2 "    ${ERROR} Unknown template: $template")
        ;;
    esac
  done

  (echo >&2 "")
  (echo >&2 "${INFO} Templates added. You may need to build them with:")
  (echo >&2 "  ludus templates build")
  (echo >&2 "")
  (echo >&2 "${INFO} Check template status with:")
  (echo >&2 "  ludus templates list")
  (echo >&2 "  ludus templates status")
}

# ============================================================================
# TEMPLATE AND INVENTORY VALIDATION
# ============================================================================

check_goad_templates() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  GOAD_DIR="$(dirname "$SCRIPT_DIR")"

  (echo >&2 "[+] Checking GOAD templates and configuration files")

  TEMPLATE_OK=1

  # Check main directories exist
  for dir in "ad" "ansible" "ansible/roles" "extensions"; do
    if [ -d "$GOAD_DIR/$dir" ]; then
      (echo >&2 "  ${GOODTOGO} Directory exists: $dir")
    else
      (echo >&2 "  ${ERROR} Directory missing: $dir")
      TEMPLATE_OK=0
    fi
  done

  # Check lab configurations
  for lab in $LABS; do
    LAB_DIR="$GOAD_DIR/ad/$lab"
    if [ -d "$LAB_DIR" ]; then
      (echo >&2 "  ${GOODTOGO} Lab directory exists: ad/$lab")

      # Check config.json
      if [ -f "$LAB_DIR/data/config.json" ]; then
        # Validate JSON syntax
        if python3 -c "import json; json.load(open('$LAB_DIR/data/config.json'))" 2>/dev/null; then
          (echo >&2 "    ${GOODTOGO} config.json is valid JSON")
        else
          (echo >&2 "    ${ERROR} config.json has invalid JSON syntax!")
          TEMPLATE_OK=0
        fi
      else
        (echo >&2 "    ${ERROR} config.json missing in ad/$lab/data/")
        TEMPLATE_OK=0
      fi

      # Check main inventory
      if [ -f "$LAB_DIR/data/inventory" ]; then
        (echo >&2 "    ${GOODTOGO} Main inventory exists: ad/$lab/data/inventory")
      else
        (echo >&2 "    ${ERROR} Main inventory missing: ad/$lab/data/inventory")
        TEMPLATE_OK=0
      fi

      # Check provider inventory for selected provider
      if [ -n "$PROVIDER" ] && [ -d "$LAB_DIR/providers/$PROVIDER" ]; then
        if [ -f "$LAB_DIR/providers/$PROVIDER/inventory" ]; then
          (echo >&2 "    ${GOODTOGO} Provider inventory exists: ad/$lab/providers/$PROVIDER/inventory")
        else
          (echo >&2 "    ${ERROR} Provider inventory missing: ad/$lab/providers/$PROVIDER/inventory")
          TEMPLATE_OK=0
        fi
      fi
    else
      (echo >&2 "  ${INFO} Lab directory not found: ad/$lab (optional)")
    fi
  done

  if [ $TEMPLATE_OK -eq 0 ]; then
    (echo >&2 "${ERROR} Template validation failed!")
    exit 1
  else
    (echo >&2 "${GOODTOGO} All templates validated successfully")
  fi
}

check_inventory_rendered() {
  # Check if a workspace inventory has unrendered templates
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  GOAD_DIR="$(dirname "$SCRIPT_DIR")"

  (echo >&2 "[+] Checking workspace inventories for unrendered templates")

  WORKSPACE_DIR="$GOAD_DIR/workspace"
  if [ -d "$WORKSPACE_DIR" ]; then
    INVENTORY_FILES=$(find "$WORKSPACE_DIR" -name "inventory" -type f 2>/dev/null)
    if [ -n "$INVENTORY_FILES" ]; then
      for inv_file in $INVENTORY_FILES; do
        if grep -q '{{ip_range}}' "$inv_file" 2>/dev/null; then
          (echo >&2 "  ${ERROR} Unrendered template found in: $inv_file")
          (echo >&2 "  ${ERROR} The {{ip_range}} placeholder was not replaced!")
          (echo >&2 "  ${INFO} Fix: Re-run GOAD instance creation or manually replace {{ip_range}} with your IP range")
          exit 1
        else
          (echo >&2 "  ${GOODTOGO} Inventory rendered correctly: $inv_file")
        fi
      done
    else
      (echo >&2 "  ${INFO} No workspace inventories found (run GOAD install first)")
    fi
  else
    (echo >&2 "  ${INFO} Workspace directory does not exist yet")
  fi
}

check_ansible_playbooks() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  GOAD_DIR="$(dirname "$SCRIPT_DIR")"

  (echo >&2 "[+] Checking Ansible playbooks")

  PLAYBOOKS="build.yml ad-servers.yml ad-data.yml vulnerabilities.yml"
  PLAYBOOK_OK=1

  for playbook in $PLAYBOOKS; do
    if [ -f "$GOAD_DIR/ansible/$playbook" ]; then
      # Basic YAML syntax check
      if python3 -c "import yaml; yaml.safe_load(open('$GOAD_DIR/ansible/$playbook'))" 2>/dev/null; then
        (echo >&2 "  ${GOODTOGO} Playbook valid: $playbook")
      else
        (echo >&2 "  ${ERROR} Playbook has YAML syntax error: $playbook")
        PLAYBOOK_OK=0
      fi
    else
      (echo >&2 "  ${ERROR} Playbook missing: $playbook")
      PLAYBOOK_OK=0
    fi
  done

  if [ $PLAYBOOK_OK -eq 0 ]; then
    (echo >&2 "${ERROR} Playbook validation failed!")
    exit 1
  else
    (echo >&2 "${GOODTOGO} All playbooks validated successfully")
  fi
}

check_ansible_roles() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  GOAD_DIR="$(dirname "$SCRIPT_DIR")"

  (echo >&2 "[+] Checking critical Ansible roles")

  # Critical roles that must exist
  CRITICAL_ROLES="common domain_controller member_server ad settings/hostname settings/admin_password settings/keyboard"
  ROLES_OK=1

  for role in $CRITICAL_ROLES; do
    ROLE_PATH="$GOAD_DIR/ansible/roles/$role"
    if [ -d "$ROLE_PATH" ]; then
      if [ -f "$ROLE_PATH/tasks/main.yml" ]; then
        (echo >&2 "  ${GOODTOGO} Role exists: $role")
      else
        (echo >&2 "  ${ERROR} Role missing tasks/main.yml: $role")
        ROLES_OK=0
      fi
    else
      (echo >&2 "  ${ERROR} Role directory missing: $role")
      ROLES_OK=0
    fi
  done

  # Check disable_eval_shutdown role (our new role)
  if [ -d "$GOAD_DIR/ansible/roles/settings/disable_eval_shutdown" ]; then
    (echo >&2 "  ${GOODTOGO} Role exists: settings/disable_eval_shutdown")
  else
    (echo >&2 "  ${INFO} Optional role missing: settings/disable_eval_shutdown (prevents evaluation shutdown)")
  fi

  if [ $ROLES_OK -eq 0 ]; then
    (echo >&2 "${ERROR} Role validation failed!")
    exit 1
  else
    (echo >&2 "${GOODTOGO} All critical roles validated successfully")
  fi
}

check_config_json_hosts() {
  # Validate that config.json has all required host entries
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  GOAD_DIR="$(dirname "$SCRIPT_DIR")"
  LAB_NAME="${LAB:-GOAD}"

  CONFIG_FILE="$GOAD_DIR/ad/$LAB_NAME/data/config.json"

  if [ -f "$CONFIG_FILE" ]; then
    (echo >&2 "[+] Validating config.json host entries for $LAB_NAME")

    # Check required fields using Python
    python3 << EOF
import json
import sys

try:
    with open('$CONFIG_FILE') as f:
        config = json.load(f)

    lab = config.get('lab', {})
    hosts = lab.get('hosts', {})
    domains = lab.get('domains', {})

    errors = []

    # Check hosts have required fields
    required_host_fields = ['hostname', 'domain', 'local_admin_password']
    for host_key, host_data in hosts.items():
        for field in required_host_fields:
            if field not in host_data:
                errors.append(f"Host '{host_key}' missing required field: {field}")

    # Check domains exist
    if not domains:
        errors.append("No domains defined in config.json")

    # Check domain references are valid
    for host_key, host_data in hosts.items():
        host_domain = host_data.get('domain', '')
        if host_domain and host_domain not in domains:
            errors.append(f"Host '{host_key}' references undefined domain: {host_domain}")

    if errors:
        for err in errors:
            print(f"  [!] {err}", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"  [✓] config.json has {len(hosts)} hosts and {len(domains)} domains", file=sys.stderr)
        sys.exit(0)

except json.JSONDecodeError as e:
    print(f"  [!] Invalid JSON: {e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"  [!] Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF

    if [ $? -ne 0 ]; then
      (echo >&2 "${ERROR} config.json validation failed!")
      exit 1
    else
      (echo >&2 "${GOODTOGO} config.json validated successfully")
    fi
  fi
}

main() {
  # Get location of prepare.sh
  # https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
  VAGRANT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  case $PROVIDER in
    "virtualbox")
      (echo >&2 "[+] Enumerating virtualbox")
      check_virtualbox_installed
      check_vagrant_path
      check_vagrant_reload_plugin
      check_disk_free_space
      check_ram_space
      case $ANSIBLE_HOST in
        "docker")
          check_docker_installed
          ;;
        "local")
          check_python_env
          ;;
        *)
          ;;
      esac
      ;;
    "vmware")
      (echo >&2 "[+] Enumerating vmware")
      check_vmware_workstation_installed
      check_vagrant_path
      check_vagrant_reload_plugin
      check_vagrant_vmware_utility_installed
      check_vmware_desktop_vagrant_plugin_installed
      check_disk_free_space
      check_ram_space
      case $ANSIBLE_HOST in
        "docker")
          check_docker_installed
          ;;
        "local")
          check_python_env
          ;;
        *)
          ;;
      esac
      ;;
    "vmware_esxi")
      (echo >&2 "[+] Enumerating vmware_esxi")
      check_vagrant_path
      check_vagrant_reload_plugin
      check_vagrant_esxi_plugin
      check_vagrant_env_plugin
      check_ovftool_installed
      case $ANSIBLE_HOST in
        "docker")
          check_docker_installed
          ;;
        "local")
          check_python_env
          ;;
        *)
          ;;
      esac
      ;;
    "proxmox")
      (echo >&2 "[+] Enumerating proxmox")
      check_packer_path
      check_terraform_path
      case $ANSIBLE_HOST in
        "docker")
          check_docker_installed
          ;;
        "local")
          check_python_env
          ;;
        *)
          ;;
      esac
      ;;
    "azure")
      (echo >&2 "[+] Enumerating azure")
      check_azure_installed
      check_terraform_path
      check_rsync_path
      ;;
    "aws")
      (echo >&2 "[+] Enumerating aws")
      check_aws_installed
      check_terraform_path
      check_rsync_path
      case $ANSIBLE_HOST in
        "docker")
          check_docker_installed
          ;;
        "local")
          check_python_env
          ;;
        *)
          ;;
      esac
      ;;
    "ludus")
      (echo >&2 "[+] Enumerating ludus")
      check_ludus_installed
      check_ludus_range
      check_ludus_templates
      case $ANSIBLE_HOST in
        "docker")
          check_docker_installed
          ;;
        "local")
          check_python_env
          ;;
        *)
          ;;
      esac
      ;;
    *)
      print_usage
      ;;
  esac

  # Always run template and configuration checks
  (echo >&2 "")
  (echo >&2 "[+] Running GOAD configuration validation")
  check_goad_templates
  check_ansible_playbooks
  check_ansible_roles
  check_config_json_hosts
  check_inventory_rendered
}

main
exit 0
