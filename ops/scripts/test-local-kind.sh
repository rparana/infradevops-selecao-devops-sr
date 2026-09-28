#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="comments-cluster"
NAMESPACE="comments"
IMAGE_NAME="comments-api:latest"

echo "=========================================================="
echo "🚀 Bootstrapping Local KinD Cluster for Comments API"
echo "=========================================================="

# Check prerequisites
for cmd in kind kubectl helm docker; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "❌ Erro: Ferramenta '$cmd' não encontrada no PATH. Por favor, instale-a."
    exit 1
  fi
done

# 1. Create KinD cluster with Ingress port mappings if not already existing
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "ℹ️ Cluster KinD '${CLUSTER_NAME}' já existe. Pulando criação."
else
  echo "📦 Criando cluster KinD '${CLUSTER_NAME}' com suporte a Ingress (portas 80/443)..."
  cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}"

# 2. Install Ingress-NGINX Controller
echo "🌐 Instalando Ingress-NGINX Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "⏳ Aguardando Ingress-NGINX Controller ficar Ready (até 90s)..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# 3. Build container and load into KinD
echo "🐳 Construindo imagem '${IMAGE_NAME}'..."
docker build -t "${IMAGE_NAME}" ./app

echo "📥 Carregando imagem no cluster KinD..."
kind load docker-image "${IMAGE_NAME}" --name "${CLUSTER_NAME}"

# 4. Deploy Helm Chart
echo "⛵ Realizando deploy do Helm chart 'comments-api'..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install comments-api ./helm/comments-api \
  --namespace "${NAMESPACE}" \
  --set image.repository="comments-api" \
  --set image.tag="latest" \
  --set image.pullPolicy="Never" \
  --set ingress.enabled=true \
  --set postgresql.enabled=true

echo "⏳ Aguardando rollout dos pods da Comments API..."
kubectl rollout status deployment/comments-api -n "${NAMESPACE}" --timeout=120s

echo ""
echo "=========================================================="
echo "✅ Deploy concluído com sucesso no cluster KinD!"
echo "=========================================================="
echo "Endpoints disponíveis:"
echo "👉 Health:  http://localhost/health"
echo "👉 Metrics: http://localhost/metrics"
echo "👉 Swagger: http://localhost/docs"
echo ""
echo "Para limpar o cluster local:"
echo "kind delete cluster --name ${CLUSTER_NAME}"
