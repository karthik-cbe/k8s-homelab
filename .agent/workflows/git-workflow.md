---
description: Git branching workflow for k8s-homelab
---

# Git Workflow for K8s Homelab

## Branch Structure

- **`main`** - Production branch (ArgoCD watches this for deployments)
- **`dev`** - Development/testing branch
- **`feature/*`** - Feature branches for specific changes

## Daily Workflow

### 1. Starting New Work

```bash
# Always start from dev branch
git checkout dev
git pull origin dev

# Create a feature branch for your work
git checkout -b feature/your-feature-name
```

### 2. Making Changes

```bash
# Make your changes to manifests/configs
# Test locally if possible

# Stage and commit
git add .
git commit -m "descriptive message about your changes"
```

### 3. Testing in Dev

```bash
# Push feature branch
git push origin feature/your-feature-name

# Merge to dev for testing
git checkout dev
git merge feature/your-feature-name
git push origin dev

# Optional: Point ArgoCD to dev branch temporarily to test
# Or use a separate ArgoCD app for dev environment
```

### 4. Promoting to Production

```bash
# Once tested and stable in dev
git checkout main
git merge dev
git push origin main

# ArgoCD will automatically sync and deploy
```

### 5. Cleanup

```bash
# Delete feature branch after merging
git branch -d feature/your-feature-name
git push origin --delete feature/your-feature-name
```

## Quick Commands

### Switch to dev for daily work
```bash
git checkout dev
```

### Create new feature
```bash
git checkout dev
git checkout -b feature/add-prometheus
```

### Promote dev to main
```bash
git checkout main
git merge dev
git push origin main
```

### Sync dev with main (if main was hotfixed)
```bash
git checkout dev
git merge main
git push origin dev
```

## ArgoCD Configuration

Your ArgoCD apps should watch the `main` branch by default. If you want a dev environment:

1. Keep production apps watching `main`
2. Create separate dev apps watching `dev` branch
3. Use different namespaces or clusters for dev

## Best Practices

1. **Never commit directly to main** - Always go through dev
2. **Use descriptive branch names** - `feature/add-monitoring`, `fix/ingress-issue`
3. **Test in dev first** - Catch issues before production
4. **Keep commits atomic** - One logical change per commit
5. **Write good commit messages** - Future you will thank you
6. **Pull before push** - Avoid merge conflicts
7. **Delete merged branches** - Keep repo clean

## Emergency Hotfix

If you need to fix something in production immediately:

```bash
git checkout main
git checkout -b hotfix/critical-fix
# Make your fix
git add .
git commit -m "hotfix: description"
git checkout main
git merge hotfix/critical-fix
git push origin main

# Sync back to dev
git checkout dev
git merge main
git push origin dev
```
