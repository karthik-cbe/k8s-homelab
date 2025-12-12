# K8s Homelab - Quick Reference

## Current Branch Structure
- `main` → Production (ArgoCD deploys from here)
- `dev` → Development/Testing

## Your Daily Workflow

### 🚀 Starting Your Day
```bash
# Switch to dev branch for work
git checkout dev
git pull origin dev
```

### ✏️ Making Changes
```bash
# Make your changes to manifests
# Then commit
git add .
git commit -m "Add: description of changes"
git push origin dev
```

### 🧪 Testing Changes
```bash
# Option 1: Test locally with kubectl
kubectl apply --dry-run=client -f your-file.yaml

# Option 2: Point ArgoCD to dev branch temporarily
# (Edit ArgoCD app to use 'dev' branch instead of 'main')
```

### ✅ Promoting to Production
```bash
# Once tested and stable
git checkout main
git merge dev
git push origin main

# ArgoCD will auto-deploy from main
```

### 🌿 Creating Feature Branches (Optional)
```bash
git checkout dev
git checkout -b feature/my-new-app
# Make changes
git push origin feature/my-new-app
# Create PR on GitHub: dev ← feature/my-new-app
```

## Repository Links
- **GitHub**: https://github.com/karthik-cbe/k8s-homelab
- **Branches**: https://github.com/karthik-cbe/k8s-homelab/branches

## Useful Commands
```bash
# Check current branch
git branch

# See what changed
git status
git diff

# View commit history
git log --oneline --graph --all

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Sync dev with main
git checkout dev
git merge main
git push origin dev
```

## Best Practices
1. ✅ Always work in `dev` branch
2. ✅ Test before merging to `main`
3. ✅ Use descriptive commit messages
4. ✅ Pull before you push
5. ❌ Never commit secrets (use sealed-secrets)
6. ❌ Don't commit directly to `main`

## Need Help?
Run: `/git-workflow` to see the full workflow guide
