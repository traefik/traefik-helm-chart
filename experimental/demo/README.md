# Live demo — chart walkthrough

```bash
kind create cluster --name traefik-demo

kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/experimental-install.yaml

export HUB_TOKEN=<>

helm install traefik ./experimental -n traefik --create-namespace

helm upgrade traefik ./experimental -n traefik \
  -f experimental/demo/01-scale.yaml
kubectl get pods -n traefik -w

helm upgrade traefik ./experimental -n traefik \
  -f experimental/demo/02-gateway.yaml

helm upgrade traefik ./experimental -n traefik \
  -f experimental/demo/03-config.yaml

# Hub is BYO-only: create the license Secret out-of-band, then enable Hub.
kubectl create secret generic traefik-traefik-hub-license -n traefik \
  --from-literal=token="$HUB_TOKEN"

helm upgrade traefik ./experimental -n traefik \
  -f experimental/demo/04-hub.yaml

helm upgrade traefik ./experimental -n traefik \
  -f experimental/demo/05-apim.yaml


helm uninstall traefik -n traefik
kind delete cluster --name traefik-demo
```