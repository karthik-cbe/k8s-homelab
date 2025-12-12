.PHONY: help install-argocd deploy-root status sync-all backup health-check

help:
	@echo "Available commands:"
	@echo "  make install-argocd  - Install ArgoCD in the cluster"
	@echo "  make deploy-root     - Deploy the root application"
	@echo "  make status          - Show status of all applications"
	@echo "  make sync-all        - Force sync all applications"
	@echo "  make backup          - Backup cluster resources"
	@echo "  make health-check    - Check cluster health"

install-argocd:
	@bash bootstrap/argocd/install-argocd.sh

deploy-root:
	@kubectl apply -f bootstrap/argocd/root-app.yaml
	@echo "✅ Root application deployed. ArgoCD will sync automatically."
	@echo "Monitor progress: kubectl get applications -n argocd"

status:
	@echo "=== ArgoCD Applications ==="
	@kubectl get applications -n argocd
	@echo ""
	@echo "=== Pods in all namespaces ==="
	@kubectl get pods -A | grep -v "Running.*0/" || true

sync-all:
	@echo "Forcing sync on all applications..."
	@kubectl get applications -n argocd -o name | xargs -r -I {} kubectl patch {} -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
	@echo "✅ Sync triggered for all applications"

backup:
	@mkdir -p backups
	@echo "Creating backup of all cluster resources..."
	@kubectl get all --all-namespaces -o yaml > backups/cluster-backup-$(shell date +%Y%m%d-%H%M%S).yaml
	@kubectl get configmaps,secrets --all-namespaces -o yaml > backups/configs-secrets-backup-$(shell date +%Y%m%d-%H%M%S).yaml
	@echo "✅ Backup created in backups/ directory"

health-check:
	@echo "=== Cluster Health Check ==="
	@echo ""
	@echo "Nodes:"
	@kubectl get nodes
	@echo ""
	@echo "System Pods:"
	@kubectl get pods -n kube-system
	@echo ""
	@echo "ArgoCD Status:"
	@kubectl get pods -n argocd
	@echo ""
	@echo "Storage:"
	@kubectl get pvc -A
	@echo ""
	@echo "Ingress Controller:"
	@kubectl get pods -n ingress-nginx
