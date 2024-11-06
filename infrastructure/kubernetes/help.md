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
