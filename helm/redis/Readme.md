# helm chart 安装 redis

获取 https://artifacthub.io/ 相关 chart 的地址

### 使用 helm 安装 redis chart

```shell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install helm-redis bitnami/redis -n web --set auth.password=redis
```

**安装完成之后会打印下边的测试方式**
NAME: helm-redis
LAST DEPLOYED: Sun Sep 4 17:04:05 2022
NAMESPACE: web
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: redis
CHART VERSION: 17.1.3
APP VERSION: 7.0.4

** Please be patient while the chart is being deployed **

Redis&reg; can be accessed on the following DNS names from within your cluster:

    helm-redis-master.web.svc.cluster.local for read/write operations (port 6379)
    helm-redis-replicas.web.svc.cluster.local for read-only operations (port 6379)

To get your password run:

    export REDIS_PASSWORD=$(kubectl get secret --namespace web helm-redis -o jsonpath="{.data.redis-password}" | base64 -d)

To connect to your Redis&reg; server:

1. Run a Redis&reg; pod that you can use as a client:

   kubectl run --namespace web redis-client --restart='Never' --env REDIS_PASSWORD=$REDIS_PASSWORD --image docker.io/bitnami/redis:7.0.4-debian-11-r17 --command -- sleep infinity

   Use the following command to attach to the pod:

   kubectl exec --tty -i redis-client \
   --namespace web -- bash

2. Connect using the Redis&reg; CLI:
   REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h helm-redis-master
   REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h helm-redis-replicas

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace web svc/helm-redis-master 6379:6379 &
    REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h 127.0.0.1 -p 6379
