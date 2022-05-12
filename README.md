# k3sx

Install k3s on given ssh remotes via k3sup and setup additional components for a proper production cluster.

## Prerequesites

To proceed, you need one or more exposed remote Linux hosts, which you can access via public IPv4 and can login to as a privileged user via a private key.

## Setup

### 1. Supply all inputs

- Set environment variables for SSH:

```bash
export SSH_USER=root # user name for login on your remotes
export SSH_KEY=$HOME/id_rsa # # ssh key for login on your remotes
```

- Create `./server-ips.txt` and `./agent-ips.txt` and fill them with the IPv4 addresses of your remotes, one IP per line.
- Copy `./chart/values.yaml` to `./` and fill in all required values

### 2. Install CLI tools

#### Quick install via Homebrew

- Install [brew](https://brew.sh/) if you don't have it yet: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Install all other tools via brew: `brew install kubernetes-cli int128/kubelogin/kubelogin helm k3sup fluxcd/tap/flux vcluster`

#### List of tools with alternative install instructions

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-other-package-management)
- [kubelogin](https://github.com/int128/kubelogin#setup)
- [helm](https://helm.sh/docs/intro/install/#from-homebrew-macos)
- [k3sup](https://github.com/alexellis/k3sup#download-k3sup-tldr)
- [fluxcd](https://fluxcd.io/docs/installation/#install-the-flux-cli)
- [vcluster](https://www.vcluster.com/docs/getting-started/setup)

### 3. Setup k3s on all given ssh remotes

```bash
helm template k3sx ./chart --show-only k3s-config.yaml --values ./values.yaml --set k3s_setup_run=true --output-dir ./

for SERVER in $(cat ./server-ips.txt)
do
    scp ./k3s-config.yaml $SSH_USER@$SERVER:~/
    k3sup install --ip $SERVER --user $SSH_USER --ssh-key $SSH_KEY --k3s-extra-args '--config ~/k3s-config.yaml'
    export JOIN_SERVER=$SERVER
done

for AGENT in $(cat ./server-ips.txt)
do
    scp ./k3s-config.yaml $SSH_USER@$AGENT:~/
    k3sup join --ip $AGENT --server-ip $JOIN_SERVER --user $SSH_USER --k3s-extra-args '--config ~/k3s-config.yaml'
done
```

### 4. [Bootstrap FluxCD](https://fluxcd.io/docs/installation/#bootstrap) 

Simply do [`flux install`](https://fluxcd.io/docs/cmd/flux_install/). 

#### Alternative

If you wish to have the entire cluster be controlled my a single GitOps repo, instead do [`flux bootstrap github`](https://fluxcd.io/docs/installation/#github-and-github-enterprise) for automatically setting up a GitOps repo on GitHub or [`flux bootstrap git`](https://fluxcd.io/docs/installation/#generic-git-server) for using an existing GitOps repo with an arbitrary provider.

### 5. Install the infrastructure chart

**NOTE:** If you chose to setup a GitOps repo for the entire cluster in the previous step, create and commit respective YAML definitions of [GitRepository](https://fluxcd.io/docs/guides/helmreleases/#git-repository) and [HelmRelease](https://fluxcd.io/docs/guides/helmreleases/#define-a-helm-release) resources to your repo instead of using the CLI commands shown below.

#### Create a GitRepository source from this repo

```bash
flux create source git k3sx \
  --url=https://github.com/lorenzo-w/k3sx \
  --branch=master
```

#### Create a HelmRelease with values from ./values.yaml

```bash
flux create hr k3sx \
  --source=GitRepository/k3sx \
  --chart=./chart \
  --values=./values.yaml 
```

### 6. [Change the default StorageClass](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/) to Longhorn

```bash
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### 7. Optional: Setup one or more [vclusters](https://www.vcluster.com/docs/getting-started/deployment)

```bash
kubectl create namespace vcluster-1
vcluster create vcluster-1 -n vcluster-1 --expose
```
