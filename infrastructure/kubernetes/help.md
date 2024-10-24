# Steps for auth

## Create the dockerconfigjson-github-com image pull secret

- Create a PAT token in github with read:packages
- Run `echo -n "username:123123adsfasdf123123" | base64`
- Output will look like `dXNlcm5hbWU6MTIzMTIzYWRzZmFzZGYxMjMxMjM=`
- Base64 again: `echo -n  '{"auths":{"ghcr.io":{"auth":"dXNlcm5hbWU6MTIzMTIzYWRzZmFzZGYxMjMxMjM="}}}' | base64`
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
  .dockerconfigjson: eyJhdXRocyI6eyJnaGNyLmlvIjp7ImF1dGgiOiJkWE5sY201aGJXVTZNVEl6TVRJellXUnpabUZ6WkdZeE1qTXhNak09In19fQ==
```

- run `kubectl create -f dockerconfigjson.yaml`

Do not commit this file !
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

## Create KUBERNETES_SECRET

https://andrekoenig.de/articles/kubernetes-deployment-using-github-actions
