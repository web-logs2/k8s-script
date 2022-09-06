# helm chart 安装 mysql

获取 https://artifacthub.io/ 相关 chart 的地址

### 使用 helm 安装 mysql chart

```shell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-release bitnami/mysql -n web
```

**安装完成之后会打印下边的测试方式**

NAME: my-release
LAST DEPLOYED: Sun Sep 4 15:15:30 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: mysql
CHART VERSION: 9.3.1
APP VERSION: 8.0.30

** Please be patient while the chart is being deployed **

Tip:

Watch the deployment status using the command: kubectl get pods -w --namespace default

Services:

echo Primary: my-release-mysql.default.svc.cluster.local:3306

Execute the following to get the administrator credentials:

echo Username: root
MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace default my-release-mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d)

To connect to your database:

1. Run a pod that you can use as a client:

   kubectl run my-release-mysql-client --rm --tty -i --restart='Never' --image docker.io/bitnami/mysql:8.0.30-debian-11-r6 --namespace default --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD --command -- bash

2. To connect to primary service (read/write):\*\*\*\*

   mysql -h my-release-mysql.default.svc.cluster.local -uroot -p"$MYSQL_ROOT_PASSWORD"

### 设置合适的 pv

```shell
# 查看当前的 pvc
kubectl get pvc data-my-release-mysql-0 -o yaml
```

输出文件

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    pv.kubernetes.io/bind-completed: "yes"
    pv.kubernetes.io/bound-by-controller: "yes"
  creationTimestamp: "2022-09-04T07:46:53Z"
  finalizers:
    - kubernetes.io/pvc-protection
  labels:
    app.kubernetes.io/component: primary
    app.kubernetes.io/instance: my-release
    app.kubernetes.io/name: mysql
  name: data-my-release-mysql-0
  namespace: default
  resourceVersion: "2223342"
  uid: dc384c70-4a7e-41cb-a6a4-e52a9f1cdf70
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
  volumeMode: Filesystem
  volumeName: pv-nfs-001
status:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 8Gi
  phase: Bound
```

确定 pvc 的 accessModes，storage，storageClassName 等是否有合适的 pv

```shell
# 查看pv
kubectl get pv
```

### 基于 chart 使用新的 values 重新部署一个服务

Values.yaml

helm install helm-mysql-2 bitnami/mysql -n web