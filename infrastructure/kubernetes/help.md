# Steps for auth

## Create the dockerconfigjson-github-com image pull secret

- Create a PAT token in github with read:packages
- Run `echo -n "username:123123adsfasdf123123" | base64`
- Output will look like `d..................M=`
- Base64 again: `echo -n  '{"auths":{"ghcr.io":{"auth":"d..................M="}}}' | base64`
- create dockerconfigjson.yaml file and use previous output as :

```
kind: Secret
type: kubernetes.io/dockerconfigjson
apiVersion: v1
metadata:
  name: dockerconfigjson-github-com
  namespace: cadrart
  labels:
    app: app-name
data:
  .dockerconfigjson: *** OUTPUT HERE ***
```

- run `kubectl create -f dockerconfigjson.yaml`

Do not commit this file !

## Create KUBERNETES_SECRET

https://andrekoenig.de/articles/kubernetes-deployment-using-github-actions

## Test Endpoint Secret

The test endpoints (`/api/test/cleanup` and `/api/test/setup`) require a secret token for access.

### Generate Test Secret

1. Use the provided script:

   ```bash
   ./generate-test-secret.sh "your-secure-secret-value"
   ```

2. Or manually generate base64:
   ```bash
   echo -n "your-secure-secret-value" | base64
   ```

### Update Kubernetes Secret

1. Update `secrets.yaml` with the generated base64 value:

   ```yaml
   TEST_ENDPOINT_SECRET: <your-base64-encoded-secret>
   ```

2. Apply the updated secret:
   ```bash
   kubectl apply -f secrets.yaml
   ```

### Security Notes

- **Never commit real secrets** to version control
- **Use different secrets** for different environments (dev, staging, prod)
- **Rotate secrets** regularly
- **Test endpoints are disabled in production** regardless of the secret
