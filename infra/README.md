# Infrastructure

## Usage

```sh
kubectl apply -f infra/ -R
```

Deploying these manifests will _not_ create any pod, but ArgoCD applications will be created. Please login ArgoCD webui or use cli to run application (notice that fill in parameters before sync application).

## Resources

These resources are cluster infrastructure that could be used for self-hosted applications.

| Namespace | Group                          | Kind                | Name                                   |
| --------- | ------------------------------ | ------------------- | -------------------------------------- |
| -         | `storage.k8s.io/v1`            | `StorageClass`      | `local-path`                           |
| -         | `storage.k8s.io/v1`            | `StorageClass`      | `csi-s3`                               |
| -         | -                              | storage provisioner | `cluster.local/local-path-provisioner` |
| -         | -                              | storage provisioner | `ru.yandex.s3.csi`                     |
| -         | `networking.k8s.io/v1`         | `IngressClass`      | `traefik`                              |
| -         | -                              | ingress controller  | `traefik.io/ingress-controller`        |
| -         | `gateway.networking.k8s.io/v1` | `GatewayClass`      | `traefik`                              |
| `traefik` | `gateway.networking.k8s.io/v1` | `Gateway`           | `traefik-gateway`                      |
| -         | `cert-manager.io/v1`           | `ClusterIssuer`     |                                        |
| `infra`   | `cert-manager.io/v1`           | `Issuer`            | `letsencrypt-issuer`                   |
| `argocd`  | `argoproj.io/v1alpha1`         | `AppProject`        | `default`                              |
| `argocd`  | `argoproj.io/v1alpha1`         | `AppProject`        | `infra`                                |
| `argocd`  | `argoproj.io/v1alpha1`         | `AppProject`        | `self-hosted`                          |
