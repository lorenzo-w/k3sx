# k3sx

Install k3s on given ssh remotes via k3sup and setup additional components for a proper production cluster.

## Installation

### k3s install options:

- `--flannel-backend=none` for Cilium
- `--disable-network-policy` for Cilium
- `--disable traefik` for Contour
- `--oidc-issuer-url=<URL> --oidc-client-id=<ID> --oidc-username-claim=email --oidc-groups-claim=groups` 
  - to enable auth via Dex
  - see [K8S Auth Docs](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#configuring-the-api-server)

### k3s input

- server node list
- agent node list
- kubeconfig location
- kubeconfig merge flag
- ssh key file override

### (Manual) setup steps

- Install CLI tools
  - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
  - [kubelogin](https://github.com/Azure/kubelogin#getting-started)
  - [helm](https://helm.sh/docs/intro/install/)
  - [k3sup](https://github.com/alexellis/k3sup#download-k3sup-tldr)
  - [argocd](https://argo-cd.readthedocs.io/en/stable/cli_installation/#installation)
  - [vcluster](https://www.vcluster.com/docs/getting-started/setup)
- Setup k3s on all given ssh remotes with params listed above
- Install `/chart` via helm, supplying custom `values.yaml`
- Add app referencing `/chart` with according `values.yaml` via `argocd app`
- [Change the default StorageClass](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/) to Longhorn
- Setup one or more [vclusters](https://www.vcluster.com/docs/getting-started/deployment)

### Sources

1. ArgoCD

   - [Chart](https://artifacthub.io/packages/helm/argo/argo-cd)
     - `--insecure` flag
   - [Getting Started Guide](https://argo-cd.readthedocs.io/en/stable/getting_started/)
   - [Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#declarative-setup)
   - Setup Ingress
     - Translate this example of a [Traefik IngressRoute CRD](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#ingressroute-crd) to a [Contour HTTPProxy CRD](https://projectcontour.io/docs/v1.20.1/config/request-routing/)
     - [Setup TLS with Cert-Manager and HTTPProxy](https://projectcontour.io/guides/cert-manager/#making-cert-manager-work-with-httpproxy)
     - [Setup SSO](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#existing-oidc-provider)

2. Cilium

   - [Helm install](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-helm/)
   - [Enable WireGuard](https://docs.cilium.io/en/stable/gettingstarted/encryption-wireguard/)

3. Longhorn

   - [Chart](https://github.com/longhorn/charts/tree/master/charts/longhorn)
   - [Set up S3 Backup Store](https://longhorn.io/docs/1.2.4/snapshots-and-backups/backup-and-restore/set-backup-target/#set-up-aws-s3-backupstore)
   - [Set up Recurring Job for snapshot and backup](https://longhorn.io/docs/1.2.4/snapshots-and-backups/scheduling-backups-and-snapshots/#set-up-recurring-jobs-using-a-longhorn-recurringjob)

4. Contour

   - [Helm install](https://projectcontour.io/getting-started/#option-2-helm)

5. Cert-Manager

   - [Chart](https://artifacthub.io/packages/helm/cert-manager/cert-manager)
     - `installCRDs=true`
   - [Create a central CA issuer](https://cert-manager.io/docs/configuration/ca/)
   - [How it works with Ingress](https://cert-manager.io/docs/usage/ingress/)

6. External-DNS

   - [Chart](https://artifacthub.io/packages/helm/bitnami/external-dns)
     - Set `digitalocean.secretName` to the name of the secret containing DO token
     - `sources=[ingress, contour-httpproxy]`
     - `provider=digitalocean`
   - [Example manifests for use with DigitalOcean](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/digitalocean.md#manifest-for-clusters-with-rbac-enabled)
   - [Example manifests for use with Contour](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/contour.md#example-manifests-for-external-dns)
   - PostUpgrade Hook to reload entire cluster?

7. Kubernetes Dashboard

   - [Chart](https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard)
   - [K3s install instructions](https://rancher.com/docs/k3s/latest/en/installation/kube-dashboard/)
