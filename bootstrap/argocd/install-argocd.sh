#!/usr/bin/env bash
set -euo pipefail

echo "Installing Argo CD..."

if command -v helm >/dev/null 2>&1; then
  echo "Using Helm to install Argo CD..."
  helm repo add argo https://argoproj.github.io/argo-helm || true
  helm repo update
  
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
  
  helm upgrade --install argocd argo/argo-cd     --namespace argocd     --version 7.7.12     --set configs.params."server\.insecure"=true     --wait     --timeout 10m
  
  echo "✅ Argo CD installed via Helm"
else
  echo "Helm not found, using upstream manifest..."
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  
  echo "Waiting for Argo CD to be ready..."
  kubectl -n argocd wait --for=condition=available --timeout=600s deployment/argocd-server
  kubectl -n argocd wait --for=condition=available --timeout=600s deployment/argocd-repo-server
  
  echo "✅ Argo CD installed via manifest"
fi

echo ""
echo "Retrieving initial admin password..."
if kubectl -n argocd get secret argocd-initial-admin-secret >/dev/null 2>&1; then
  ARGO_PASS="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || echo '<password-retrieval-failed>')"
  echo ""
  echo "=========================================="
  echo "ArgoCD Credentials:"
  echo "  Username: admin"
  echo "  Password: ${ARGO_PASS}"
  echo "=========================================="
  echo ""
  echo "⚠️  IMPORTANT: Change the admin password immediately!"
  echo ""
  echo "To access ArgoCD UI:"
  echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
  echo "  Then visit: https://localhost:8080"
  echo ""
else
  echo "No initial admin secret found (may be managed by Helm values or SSO)."
fi

echo ""
echo "For production, configure SSO (OIDC/GitHub/Okta) and disable the default admin user."
