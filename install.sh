#!/usr/bin/env bash

# Copyright 2018 Palo Alto Networks.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Install tools via yum
function getTools() {
    echo -n "Installing git ..."
    sudo apt-get -y install git
    echo " Done"
    echo -n "Installing unzip ..."
    sudo apt-get -y install unzip
    echo " Done"
    echo -n "Installing python-pip ..."
    sudo apt-get -y install python-pip
    echo " Done"
    echo -n "Installing ansible ..."
    sudo apt-get -y install ansible
    echo " Done"

    echo -n "Installing azure-cli ..."
    AZ_REPO=$(lsb_release -cs)
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
    curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    sudo apt-get -y install apt-transport-https
    sudo apt-get -y update && sudo apt-get -y install azure-cli
    echo " Done"

}

# Download and extract Terraform utility in the deployment directory.
function getTerraform() {
  # Places terraform in /usr/local/bin dir.
  local T_VERSION='0.11.8/terraform_0.11.8_linux_amd64'
  local T_URL="https://releases.hashicorp.com/terraform/${T_VERSION}.zip"
  local T_DIR=/usr/local/bin
  local T_ZIP="${T_DIR}/terraform.zip"
  local T_EXE="${T_DIR}/terraform"

  if [ -e ${T_EXE} ]; then
    echo "${T_EXE} already exists. Exiting."
    return 0
  fi
  echo -n "Installing Terraform ..."
  pushd ${T_DIR} > /dev/null
  sudo curl -s -o "${T_ZIP}" "${T_URL}"
  sudo unzip -q "${T_ZIP}"
  sudo rm "${T_ZIP}"
  popd > /dev/null

  if [ -e ${T_EXE} ]; then
    echo " Done"
  else
    echo " Could not retrieve ${T_EXE}."
  fi
}

# Install Python libraries.
function getPyLibs() {
  echo -n "Installing Python libraries ..."
  sudo pip install --upgrade pip setuptools
  sudo pip install pandevice xmltodict
  echo " Done"
}

# Main program
getTools
getTerraform
getPyLibs
