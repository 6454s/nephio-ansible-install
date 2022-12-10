#!/bin/bash
export USER=user
export BASE=$(pwd)
export LC_ALL=C.UTF-8
echo "-----------------"
echo "Cloning repo"
#git clone https://github.com/henderiw-nephio/nephio-ansible-install
git clone -b feature-dev-env https://github.com/6454s/nephio-ansible-install.git
cd nephio-ansible-install
echo "-----------------"
echo "Configuring inventory"
mkdir -p inventory
tee inventory/nephio.yaml <<EOF
all:
  vars:
    cloud_user: user
    gitea_username: nephio
    gitea_password: nephio
    proxy:
      http_proxy: 
      https_proxy:
      no_proxy:
    host_os: "linux"  # use "darwin" for MacOS X, "windows" for Windows
    host_arch: "amd64"  # other possible values: "386","arm64","arm","ppc64le","s390x"
    tmp_directory: "/tmp"
    bin_directory: "/usr/local/bin"
    kubectl_version: "1.25.0"
    kubectl_checksum_binary: "sha512:fac91d79079672954b9ae9f80b9845fbf373e1c4d3663a84cc1538f89bf70cb85faee1bcd01b6263449f4a2995e7117e1c85ed8e5f137732650e8635b4ecee09"
    kind_version: "0.17.0"
    cni_version: "0.8.6"
    kpt_version: "1.0.0-beta.23"
    multus_cni_version: "3.9.2"
    nephio:
      install_dir: nephio-install
      packages_url: https://github.com/nephio-project/nephio-packages.git
    clusters:
      mgmt: {mgmt_subnet: 172.88.0.0/16, pod_subnet: 10.196.0.0/16, svc_subnet: 10.96.0.0/16}
      edge1: {mgmt_subnet: 172.89.0.0/16, pod_subnet: 10.197.0.0/16, svc_subnet: 10.97.0.0/16}
      edge2: {mgmt_subnet: 172.90.0.0/16, pod_subnet: 10.198.0.0/16, svc_subnet: 10.98.0.0/16}
      region1: {mgmt_subnet: 172.91.0.0/16, pod_subnet: 10.199.0.0/16, svc_subnet: 10.99.0.0/16}
  children:
    vm:
      hosts:
        localhost:
         vars:
           ansible_connection: local
           ansible_python_interpreter: "{{ansible_playbook_python}}"
EOF
echo "-----------------"
echo "Setting up python"
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install ansible
pip install pygithub
ansible-galaxy collection install community.general
echo "-----------------"
echo "Installing prereq..."
ansible-playbook --connection=local playbooks/install-prereq.yaml > prereq.out 2>&1
echo "-----------------"
echo "Deploying gitea..."
ansible-playbook --connection=local playbooks/create-gitea.yaml > gitea.out 2>&1
echo "-----------------"
echo "Creating repos..."
ansible-playbook --connection=local playbooks/create-gitea-repos.yaml > repos.out 2>&1
echo "-----------------"
echo "Deploying clusters..."
ansible-playbook --connection=local playbooks/deploy-clusters.yaml > clusters.out 2>&1
echo "-----------------"
echo "Configuring nephio..."
ansible-playbook --connection=local playbooks/configure-nephio.yaml > nephio.out 2>&1
echo "-----------------"
echo "Done"
cd $BASE
