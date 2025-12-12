# k8s-homelab - Production-Grade GitOps Homelab

A declarative, GitOps-driven Kubernetes homelab using ArgoCD and the App-of-Apps pattern.

## 🏗️ Architecture

```
ArgoCD (GitOps Controller)
    ↓
Root Application (App-of-Apps)
    ↓
├── Infrastructure Layer
│   ├── ingress-nginx    → External traffic routing
│   ├── cert-manager     → Automated SSL certificates
│   ├── sealed-secrets   → Encrypted secrets in Git
│   ├── velero          → Cluster backups (optional)
│   └── monitoring
│       ├── prometheus  → Metrics collection
│       ├── grafana     → Visualization
│       └── loki        → Log aggregation
└── Applications Layer
    └── sample-app      → Demo nginx application
```

## 📋 Prerequisites

- Kubernetes cluster vv1.28.0+
- kubectl configured and connected
- Git
- (Recommended) Helm v3+
- Default storage class configured
- At least 2 CPU cores and 4GB RAM available

## 🚀 Quick Start

### 1. Bootstrap Repository

```bash
# Run the bootstrap script
bash bootstrap-gitops.sh

# Follow prompts for GitHub username, email, domain
```

### 2. Create GitHub Repository

```bash
# Create a new repository on GitHub named 'k8s-homelab'
# Then push:

cd /home/karthik/k8s-homelab
git add .
git commit -m "Initial commit: GitOps infrastructure"
git remote add origin git@github.com:karthik-cbe/k8s-homelab.git
git branch -M main
git push -u origin main
```

### 3. Install ArgoCD

```bash
make install-argocd
# or: bash bootstrap/argocd/install-argocd.sh
```

### 4. Deploy Root Application

```bash
make deploy-root
# or: kubectl apply -f bootstrap/argocd/root-app.yaml
```

### 5. Access Services

```bash
# ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Visit: https://localhost:8080

# Grafana (default: admin/admin - CHANGE THIS!)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Visit: http://localhost:3000

# Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit: http://localhost:9090
```

## 📁 Repository Structure

```
.
├── bootstrap/
│   └── argocd/              # ArgoCD installation
│       ├── install-argocd.sh
│       └── root-app.yaml
├── infrastructure/           # Infrastructure components
│   ├── ingress-nginx/
│   ├── cert-manager/
│   ├── sealed-secrets/
│   ├── velero/              # Backup (commented out)
│   └── monitoring/
│       ├── prometheus/
│       ├── grafana/
│       └── loki/
├── applications/            # Your applications
│   └── sample-app/
├── README.md
├── Makefile
└── .gitignore
```

## 🔧 Configuration

### SSL Certificates

1. Update email in `infrastructure/cert-manager/cluster-issuers.yaml`
2. After cert-manager is running:
   ```bash
   kubectl apply -f infrastructure/cert-manager/cluster-issuers.yaml
   ```

### Sealed Secrets

```bash
# Install kubeseal CLI
KUBESEAL_VERSION=0.24.0
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz
tar xfz kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

# Create a sealed secret
kubectl create secret generic my-secret   --from-literal=password=secretpassword   --dry-run=client -o yaml |   kubeseal -o yaml > my-sealedsecret.yaml

# Commit to Git (safe - encrypted!)
git add my-sealedsecret.yaml
git commit -m "Add sealed secret"
git push
```

### Backups with Velero

1. Configure storage backend (S3, GCS, Azure)
2. Uncomment `infrastructure/velero/application.yaml`
3. Update credentials and bucket configuration
4. Commit and push

## 📊 Monitoring

### Access Grafana

**Default credentials:** admin / admin (⚠️ CHANGE IMMEDIATELY!)

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

### Pre-configured Dashboards

Grafana comes with these dashboards out of the box:
- Kubernetes Cluster Monitoring
- Node Exporter
- Pod Resources
- Persistent Volumes

### Query Logs with Loki

1. Open Grafana
2. Go to Explore
3. Select "Loki" datasource
4. Query example: `{namespace="sample-app"}`

## 🔒 Security Best Practices

### ✅ Implemented

- Resource limits on all pods
- Sealed secrets for encryption
- RBAC enabled by default
- TLS for ingress traffic
- Separate namespaces for isolation

### ⚠️ TODO for Production

1. **Change default passwords**
   ```bash
   # Grafana
   kubectl -n monitoring exec -it deployment/kube-prometheus-stack-grafana -- grafana-cli admin reset-admin-password NEW_PASSWORD
   
   # ArgoCD
   argocd account update-password
   ```

2. **Enable SSO for ArgoCD**
   - Configure OIDC, GitHub, or Okta
   - Disable local admin user

3. **Configure Network Policies**
   - Install Calico or Cilium
   - Define ingress/egress rules

4. **Enable Pod Security Standards**
   ```bash
   kubectl label namespace sample-app pod-security.kubernetes.io/enforce=restricted
   ```

5. **Use External Secrets Operator**
   - For cloud-native secret management
   - Integration with AWS Secrets Manager, GCP Secret Manager, Azure Key Vault

## 🔄 Daily Workflow

### Adding a New Application

```bash
# 1. Create application directory
mkdir -p applications/my-app

# 2. Add Kubernetes manifests
cat > applications/my-app/deployment.yaml <<'DEPLOYEOF'
# Your deployment manifests
DEPLOYEOF

# 3. Create ArgoCD Application
cat > applications/my-app/application.yaml <<'APPEOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/karthik-cbe/k8s-homelab.git
    targetRevision: main
    path: applications/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
APPEOF

# 4. Commit and push
git add applications/my-app/
git commit -m "Add my-app"
git push

# ArgoCD syncs automatically within 3 minutes!
```

### Updating Infrastructure

```bash
# 1. Edit the manifest
vim infrastructure/ingress-nginx/application.yaml

# 2. Test locally (optional)
kubectl apply --dry-run=client -f infrastructure/ingress-nginx/application.yaml

# 3. Commit and push
git add infrastructure/ingress-nginx/
git commit -m "Update ingress-nginx configuration"
git push

# 4. Monitor in ArgoCD UI
```

## 🛠️ Useful Commands

```bash
# View all applications
make status
# or: kubectl get applications -n argocd

# Force sync all applications
make sync-all

# Create backup
make backup

# Watch all pods
watch kubectl get pods -A

# Check resource usage
kubectl top nodes
kubectl top pods -A

# View logs
kubectl logs -n NAMESPACE -l app=APP_NAME --tail=100 -f

# Check ingress IP
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

## 🐛 Troubleshooting

### ArgoCD not syncing

```bash
# Check application status
kubectl describe application APP_NAME -n argocd

# View ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Manual sync
kubectl patch application APP_NAME -n argocd   --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

### Certificate issues

```bash
# Check certificates
kubectl get certificate -A

# Describe certificate
kubectl describe certificate CERT_NAME -n NAMESPACE

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager --tail=100

# Force renewal
kubectl delete secret TLS_SECRET_NAME -n NAMESPACE
```

### Pod not starting

```bash
# Check pod status
kubectl get pod POD_NAME -n NAMESPACE -o yaml

# View events
kubectl get events -n NAMESPACE --sort-by='.lastTimestamp'

# Check logs
kubectl logs POD_NAME -n NAMESPACE

# Describe pod
kubectl describe pod POD_NAME -n NAMESPACE
```

### Storage issues

```bash
# Check PVCs
kubectl get pvc -A

# Check storage classes
kubectl get storageclass

# Install local-path-provisioner if needed
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml
```

## 📈 Scaling

### Adding Worker Nodes

Follow the same process used during cluster setup:

```bash
# On new node, join the cluster
kubeadm join CONTROL_PLANE_IP:6443 --token TOKEN --discovery-token-ca-cert-hash sha256:HASH

# Verify
kubectl get nodes
```

### Horizontal Pod Autoscaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
  namespace: my-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
```

## 💾 Backup & Disaster Recovery

### etcd Backup (Manual)

```bash
# On control plane node
sudo ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-TIMESTAMP.db   --cacert=/etc/kubernetes/pki/etcd/ca.crt   --cert=/etc/kubernetes/pki/etcd/server.crt   --key=/etc/kubernetes/pki/etcd/server.key

# Verify backup
sudo ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-*.db
```

### Velero Backup (Automated)

After configuring Velero:

```bash
# Create backup
velero backup create my-backup

# Schedule daily backups
velero schedule create daily-backup --schedule="0 2 * * *"

# Restore from backup
velero restore create --from-backup my-backup

# List backups
velero backup get
```

## 🔄 Upgrade Strategy

### Kubernetes Cluster

Follow the sequential upgrade path (one minor version at a time).

### Infrastructure Components

1. Update chart version in application manifest
2. Commit and push
3. ArgoCD syncs automatically
4. Monitor in ArgoCD UI

Example:
```yaml
# infrastructure/ingress-nginx/application.yaml
targetRevision: 4.12.0  # Update this line
```

## 🎯 Next Steps

### Short Term
- [ ] Change default passwords (Grafana, ArgoCD)
- [ ] Configure DNS for your domain
- [ ] Update `DEMO_DOMAIN` in sample-app ingress
- [ ] Apply cert-manager cluster issuers
- [ ] Test sample application

### Medium Term
- [ ] Set up monitoring alerts in Alertmanager
- [ ] Configure Velero backups
- [ ] Add your first real application
- [ ] Implement network policies
- [ ] Set up CI/CD integration

### Long Term
- [ ] Enable SSO for ArgoCD
- [ ] Migrate to External Secrets Operator
- [ ] Add more monitoring dashboards
- [ ] Implement pod security policies
- [ ] Document disaster recovery procedures

## 📚 Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Cert-Manager Docs](https://cert-manager.io/docs/)
- [Sealed Secrets Guide](https://github.com/bitnami-labs/sealed-secrets)
- [Velero Documentation](https://velero.io/docs/)

## 🤝 Contributing

1. Create a feature branch
2. Make changes
3. Test in development
4. Submit pull request
5. Merge after review

## 📝 License

This is a personal homelab setup. Use as reference or template for your own setup.

## ⚠️ Important Notes

- This is designed for homelab/development environments
- For production, additional hardening is required
- Always backup before making changes
- Monitor resource usage regularly
- Keep components updated

---

Generated by bootstrap-gitops.sh on Fri Dec 12 01:45:47 AM EST 2025
