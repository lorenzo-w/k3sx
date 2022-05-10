# k3sx

Install k3s on given ssh remotes via k3sup and setup additional components for a proper production cluster.

## Installation

### k3s install options:

- `--flannel-backend=none` for Cilium
- `--disable-network-policy` for Cilium
- `--disable traefik` for Contour
- `--oidc-issuer-url=<URL> --oidc-client-id=kubelogin --oidc-username-claim=email --oidc-groups-claim=groups` 
  - see [Dex Docs](https://dexidp.io/docs/kubernetes/#configuring-the-openid-connect-plugin)
  - see [K8S Auth Docs](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#configuring-the-api-server)
  - see [Kubelogin Docs](https://github.com/int128/kubelogin/blob/master/docs/setup.md#4-set-up-the-kubernetes-api-server)

### k3s input

- server node list
- agent node list
- kubeconfig location
- kubeconfig merge flag
- ssh key file override

### (Manual) setup steps

- Install CLI tools
  - [homebrew](https://brew.sh/)
  - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-other-package-management)
  - [kubelogin](https://github.com/int128/kubelogin#setup)
  - [helm](https://helm.sh/docs/intro/install/#from-homebrew-macos)
  - [k3sup](https://github.com/alexellis/k3sup#download-k3sup-tldr)
  - [fluxcd](https://fluxcd.io/docs/installation/#install-the-flux-cli)
  - [vcluster](https://www.vcluster.com/docs/getting-started/setup)
- Setup k3s on all given ssh remotes with params listed above
- [Bootstrap FluxCD](https://fluxcd.io/docs/installation/#bootstrap) 
  - via [`flux bootstrap github`](https://fluxcd.io/docs/installation/#github-and-github-enterprise) for automatically setting up a GitOps repo
  - or [`flux bootstrap git`](https://fluxcd.io/docs/installation/#generic-git-server) for using an existing GitOps repo
  - or [`flux install`](https://fluxcd.io/docs/cmd/flux_install/) for no root GitOps repo
- Setup infrastructure App of Apps (public reference to `/chart`), supplying custom `values.yaml`
  - via commiting [GitRepository](https://fluxcd.io/docs/guides/helmreleases/#git-repository) and [HelmRelease](https://fluxcd.io/docs/guides/helmreleases/#define-a-helm-release) resources to root GitOps repo
  - or CLI commands [`flux create source helm`](https://fluxcd.io/docs/cmd/flux_create_source_helm/) and [`flux create hr`](https://fluxcd.io/docs/cmd/flux_create_helmrelease/)
- [Change the default StorageClass](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/) to Longhorn
- Setup one or more [vclusters](https://www.vcluster.com/docs/getting-started/deployment)
