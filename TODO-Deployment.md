# TODO: Environment-Based Database Deployment

## Context

This TODO is based on a discussion about improving the blue-green deployment process to support separate databases for production and staging environments. The goal is to have different databases that switch when environments are switched, while maintaining zero-downtime deployments.

**Chat Reference**: [Cursor Chat - Deployment Process Analysis](https://cursor.sh/chat)

## Current State Analysis

### Current Architecture

- **Blue-Green Deployment**: Two parallel environments (blue/green) for zero-downtime deployments
- **Single Database**: Both environments currently use the same database (`atelier-cadrart`)
- **Environment Variables**: Database configuration via Kubernetes ConfigMaps
- **Deployment Process**: GitHub Actions trigger on release, deploy to current test environment

### Current Pain Points

1. **Shared Database**: Production and staging share the same database
2. **No Real Data Testing**: Staging doesn't have production data for realistic testing
3. **Limited Environment Separation**: No environment-specific configurations
4. **Manual Environment Switching**: Requires manual intervention for production deployments

## Proposed Solution: Environment-Based Configuration

### Key Changes Required

#### 1. Environment-Specific ConfigMaps

**Create new ConfigMaps:**

`infrastructure/kubernetes/config/configmap-prod.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cadrart-config-prod
  namespace: cadrart
data:
  DATABASE_TYPE: mysql
  DATABASE_HOST: db
  DATABASE_PORT: "3306"
  DATABASE_DATABASE: atelier-cadrart
  ENVIRONMENT: PROD
  ENV: PROD
  STATIC_ROOT: /var/www/static
  LOG_LEVEL: info
  CORS_ORIGINS: https://ateliercadrart.com,https://www.ateliercadrart.com
```

`infrastructure/kubernetes/config/configmap-stg.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cadrart-config-stg
  namespace: cadrart
data:
  DATABASE_TYPE: mysql
  DATABASE_HOST: db
  DATABASE_PORT: "3306"
  DATABASE_DATABASE: atelier-cadrart-stg
  ENVIRONMENT: STG
  ENV: STG
  STATIC_ROOT: /var/www/static
  LOG_LEVEL: debug
  CORS_ORIGINS: https://stg.ateliercadrart.com
```

#### 2. Database Setup

**Create database initialization script:**

`infrastructure/kubernetes/db/init-databases.sql`:

```sql
-- Initialize both production and staging databases
-- This script is run when the MySQL container starts for the first time

-- Create the production database
CREATE DATABASE IF NOT EXISTS `atelier-cadrart` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create the staging database
CREATE DATABASE IF NOT EXISTS `atelier-cadrart-stg` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant permissions to the application user for both databases
GRANT ALL PRIVILEGES ON `atelier-cadrart`.* TO 'atelier-cadrart'@'%';
GRANT ALL PRIVILEGES ON `atelier-cadrart-stg`.* TO 'atelier-cadrart'@'%';

-- Flush privileges to apply changes
FLUSH PRIVILEGES;
```

**Create ConfigMap for database initialization:**

`infrastructure/kubernetes/db/db-init-scripts-configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-init-scripts
  namespace: cadrart
data:
  init-databases.sql: |
    -- Initialize both production and staging databases
    -- This script is run when the MySQL container starts for the first time

    -- Create the production database
    CREATE DATABASE IF NOT EXISTS `atelier-cadrart` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    -- Create the staging database
    CREATE DATABASE IF NOT EXISTS `atelier-cadrart-stg` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    -- Grant permissions to the application user for both databases
    GRANT ALL PRIVILEGES ON `atelier-cadrart`.* TO 'atelier-cadrart'@'%';
    GRANT ALL PRIVILEGES ON `atelier-cadrart-stg`.* TO 'atelier-cadrart'@'%';

    -- Flush privileges to apply changes
    FLUSH PRIVILEGES;
```

#### 3. Update Database Deployment

**Modify `infrastructure/kubernetes/db/db-deployment.yaml`:**

- Add volume mount for initialization scripts
- Add ConfigMap volume for init scripts
- Set default database to production

#### 4. Update Backend Deployment

**Modify `cadrart2025-backend/infrastructure/kubernetes/base/deployment.yaml`:**

- Change ConfigMap references from `cadrart-config` to `cadrart-config-$COLOR_TEST`
- This allows each environment to use its own configuration

#### 5. Database Sync Strategy

**Create new sync script:**

`infrastructure/scripts/sync-staging-database.sh`:

```bash
#!/bin/bash
# Sync production database to staging
# This script clears staging DB and syncs from production

set -e

NAMESPACE="cadrart"
PROD_DB="atelier-cadrart"
STG_DB="atelier-cadrart-stg"

echo "🔄 Starting production to staging database sync"

# Get database credentials
DB_USER=$(kubectl get secret cadrart-secret -n $NAMESPACE -o jsonpath='{.data.DATABASE_USER}' | base64 -d)
DB_PASSWORD=$(kubectl get secret cadrart-secret -n $NAMESPACE -o jsonpath='{.data.DATABASE_PASSWORD}' | base64 -d)

# Get database pod
DB_POD=$(kubectl get pods -n $NAMESPACE -l io.kompose.service=db -o jsonpath='{.items[0].metadata.name}')

echo "📊 Database pod: $DB_POD"
echo "📊 Production DB: $PROD_DB"
echo "📊 Staging DB: $STG_DB"

# Create backup of production database
echo "💾 Creating backup of production database..."
kubectl exec -n $NAMESPACE $DB_POD -- mysqldump -u$DB_USER -p$DB_PASSWORD $PROD_DB > /tmp/prod_backup.sql

# Clear staging database
echo "🗑️ Clearing staging database..."
kubectl exec -n $NAMESPACE $DB_POD -- mysql -u$DB_USER -p$DB_PASSWORD -e "DROP DATABASE IF EXISTS $STG_DB; CREATE DATABASE $STG_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Restore production data to staging
echo "🔄 Restoring production data to staging..."
kubectl cp /tmp/prod_backup.sql $NAMESPACE/$DB_POD:/tmp/
kubectl exec -n $NAMESPACE $DB_POD -- mysql -u$DB_USER -p$DB_PASSWORD $STG_DB < /tmp/prod_backup.sql

# Cleanup
rm -f /tmp/prod_backup.sql
kubectl exec -n $NAMESPACE $DB_POD -- rm -f /tmp/prod_backup.sql

echo "✅ Staging database sync completed successfully!"
```

#### 6. Environment Switching Script

**Create new environment switching script:**

`infrastructure/scripts/switch-environment-with-db.sh`:

```bash
#!/bin/bash

# Environment Switch Script with Database Switching
# This script switches between blue and green environments and their corresponding databases

set -euo pipefail

NC='\033[0m'       # Text Reset
Red='\033[0;31m'   # Red
Green='\033[0;32m' # Green
Yellow='\033[0;33m' # Yellow
Blue='\033[0;34m'  # Blue
Info='ℹ️'
Success='✅'
Failure='❌'
Warning='⚠️'

# Configuration
NAMESPACE="cadrart"
CONFIGMAP_NAME="environment-config"
TIMEOUT=60

# Check if target environment is provided
if [ $# -eq 0 ]; then
  echo -e "${Red}${Failure} Target environment not specified${NC}"
  echo "Usage: $0 <blue|green>"
  exit 1
fi

TARGET_ENV=$1

if [[ "$TARGET_ENV" != "blue" && "$TARGET_ENV" != "green" ]]; then
  echo -e "${Red}${Failure} Invalid environment: $TARGET_ENV${NC}"
  echo "Valid environments: blue, green"
  exit 1
fi

echo -e "${Blue}${Info} Switching to environment: $TARGET_ENV${NC}"

# Function to check if pods are ready
check_pods_ready() {
  local color=$1
  local frontend_pod
  local backend_pod

  frontend_pod=$(kubectl get pods -n "$NAMESPACE" -l "io.kompose.service=frontend-$color" -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "")
  backend_pod=$(kubectl get pods -n "$NAMESPACE" -l "io.kompose.service=backend-$color" -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "")

  if [[ "$frontend_pod" == "Running" && "$backend_pod" == "Running" ]]; then
    return 0
  else
    return 1
  fi
}

# Function to restart deployment
restart_deployment() {
  local deployment_name=$1
  echo -e "${Yellow}${Warning} Restarting deployment: $deployment_name${NC}"
  kubectl rollout restart deployment/$deployment_name -n $NAMESPACE
  kubectl rollout status deployment/$deployment_name -n $NAMESPACE --timeout=300s
}

# Step 1: Update environment configuration
echo -e "${Blue}${Info} Step 1: Updating environment configuration${NC}"
kubectl patch configmap $CONFIGMAP_NAME -n $NAMESPACE --type='merge' -p="{\"data\":{\"COLOR_PROD\":\"$TARGET_ENV\"}}"

# Step 2: Restart the target environment pods to pick up new database configuration
echo -e "${Blue}${Info} Step 2: Restarting $TARGET_ENV environment pods${NC}"
restart_deployment "frontend-$TARGET_ENV"
restart_deployment "backend-$TARGET_ENV"

# Step 3: Wait for pods to be ready
echo -e "${Blue}${Info} Step 3: Waiting for $TARGET_ENV pods to be ready${NC}"
local start_time=$(date +%s)
while ! check_pods_ready $TARGET_ENV; do
  local current_time=$(date +%s)
  local elapsed=$((current_time - start_time))

  if [[ $elapsed -gt $TIMEOUT ]]; then
    echo -e "${Red}${Failure} Timeout waiting for $TARGET_ENV pods to be ready${NC}"
    exit 1
  fi

  echo -e "${Yellow}${Warning} Waiting for $TARGET_ENV pods... (${elapsed}s)${NC}"
  sleep 5
done

echo -e "${Green}${Success} $TARGET_ENV pods are ready${NC}"

# Step 4: Test the new environment
echo -e "${Blue}${Info} Step 4: Testing $TARGET_ENV environment${NC}"
local service_name="backend-$TARGET_ENV"
local pod_name="test-endpoint-$(date +%s)"

kubectl run "$pod_name" --image=curlimages/curl -n "$NAMESPACE" -- curl -s -o /dev/null -w "%{http_code}" "http://$service_name:3000/api/health/live" >/dev/null 2>&1

sleep 2
local response=$(kubectl logs "$pod_name" -n "$NAMESPACE" 2>/dev/null | grep -oE '^[0-9]+' || echo "000")
kubectl delete pod "$pod_name" -n "$NAMESPACE" >/dev/null 2>&1

if [[ "$response" == 200* ]]; then
  echo -e "${Green}${Success} $TARGET_ENV environment is healthy (HTTP $response)${NC}"
else
  echo -e "${Red}${Failure} $TARGET_ENV environment health check failed (HTTP $response)${NC}"
  exit 1
fi

# Step 5: Switch traffic to the new environment
echo -e "${Blue}${Info} Step 5: Switching traffic to $TARGET_ENV${NC}"

# Update proxy services to point to the new production environment
if [[ "$TARGET_ENV" == "blue" ]]; then
  # Blue becomes production
  kubectl patch service frontend-prod-proxy -n $NAMESPACE --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"frontend-blue"}}}'
  kubectl patch service backend-prod-proxy -n $NAMESPACE --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"backend-blue"}}}'

  # Green becomes staging
  kubectl patch service frontend-test-proxy -n $NAMESPACE --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"frontend-green"}}}'
  kubectl patch service backend-test-proxy -n $NAMESPACE --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"backend-green"}}}'
else
  # Green becomes production
  kubectl patch service frontend-prod-proxy -n $NAMESPACE --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"frontend-green"}}}'
  kubectl patch service backend-prod-proxy -n $NAMESPACE --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"backend-green"}}}'

  # Blue becomes staging
  kubectl patch service frontend-test-proxy -n $NAMESPACE --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"frontend-blue"}}}'
  kubectl patch service backend-test-proxy -n $NAMESPACE --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"backend-blue"}}}'
fi

echo -e "${Green}${Success} Environment switch completed successfully!${NC}"
echo -e "${Blue}${Info} Production now points to: $TARGET_ENV environment${NC}"
echo -e "${Blue}${Info} Production database: $(kubectl get configmap cadrart-config-$TARGET_ENV -n $NAMESPACE -o jsonpath='{.data.DATABASE_DATABASE}')${NC}"
```

#### 7. Update Deployment Scripts

**Modify `infrastructure/scripts/updateK3s.sh`:**

- Apply new environment-specific ConfigMaps
- Apply database initialization ConfigMap

**Update GitHub Actions workflows:**

- Modify deployment workflows to use new environment switching
- Add database sync step to staging deployments

## Implementation Steps

### Phase 1: Infrastructure Setup

1. [ ] Create environment-specific ConfigMaps (`configmap-prod.yaml`, `configmap-stg.yaml`)
2. [ ] Create database initialization script and ConfigMap
3. [ ] Update database deployment to use initialization scripts
4. [ ] Update backend deployment to use environment-specific ConfigMaps
5. [ ] Update `updateK3s.sh` to apply new ConfigMaps

### Phase 2: Database Sync

1. [ ] Create `sync-staging-database.sh` script
2. [ ] Test database sync process
3. [ ] Integrate sync into deployment workflow

### Phase 3: Environment Switching

1. [ ] Create `switch-environment-with-db.sh` script
2. [ ] Update GitHub Actions workflows
3. [ ] Test environment switching process

### Phase 4: Testing and Validation

1. [ ] Test complete deployment flow
2. [ ] Verify database separation
3. [ ] Test rollback scenarios
4. [ ] Update documentation

## Deployment Flow

### New Deployment Process

1. **Deploy to Staging**: New code goes to staging environment (green)
2. **Sync Database**: Run `sync-staging-database.sh` to sync production data to staging
3. **Test Staging**: Verify staging environment works correctly
4. **Switch Environments**: Run `switch-environment-with-db.sh` to switch blue/green

### Environment States

- **Blue Environment**: Points to production database (`atelier-cadrart`)
- **Green Environment**: Points to staging database (`atelier-cadrart-stg`)
- **After Switch**: Environments swap databases

## Important Considerations

### Downtime

- **30-60 seconds of downtime** during environment switch (pod restarts required)
- **Connection interruption** for active users during switch
- **Session loss** for users connected during the switch

### Database Sync

- **Full database sync** on every staging deployment
- **Production data safety** - sync only reads from production, never writes
- **Staging data loss** - staging database is cleared and recreated each time

### Rollback Strategy

- **Quick rollback** by switching environments back
- **Production data protection** - no changes to production database during sync
- **Staging data** - not preserved during rollback

## Benefits

1. **Real Data Testing**: Staging always has current production data
2. **Environment Separation**: Clear distinction between production and staging
3. **Environment-Specific Config**: Different log levels, CORS origins, etc.
4. **Controlled Deployment**: Only staging gets new deployments
5. **Safe Switching**: Production data is preserved during switches

## Files to Create/Modify

### New Files

- `infrastructure/kubernetes/config/configmap-prod.yaml`
- `infrastructure/kubernetes/config/configmap-stg.yaml`
- `infrastructure/kubernetes/db/init-databases.sql`
- `infrastructure/kubernetes/db/db-init-scripts-configmap.yaml`
- `infrastructure/scripts/sync-staging-database.sh`
- `infrastructure/scripts/switch-environment-with-db.sh`

### Files to Modify

- `infrastructure/kubernetes/db/db-deployment.yaml`
- `cadrart2025-backend/infrastructure/kubernetes/base/deployment.yaml`
- `infrastructure/scripts/updateK3s.sh`
- GitHub Actions workflows (`.github/workflows/switch-environment.yaml`)

## Notes

- This approach requires pod restarts for database switching
- Database sync happens on every staging deployment
- Production database is never modified during sync process
- Environment switching includes brief downtime (~30-60 seconds)
- All sensitive data remains in Kubernetes Secrets
