# 简单 mysql 安装部署

需要考虑的部分包括：pv, pvc, statefulset, svc

1. 创建一个 hostpath 的 pv

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-single-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data00/tmp/pvs"
```

2. 创建一个 pvc

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-single-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```

3. 创建一个 statefulset

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-single
spec:
  selector:
    matchLabels:
      app: mysql-single
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql-single
    spec:
      containers:
        - image: mysql:5.7
          name: mysql-single
          env:
            # Use secret in real usage
            - name: MYSQL_ROOT_PASSWORD
              value: password
          ports:
            - containerPort: 3306
              name: mysql
          volumeMounts:
            - name: mysql-persistent-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-persistent-storage
          persistentVolumeClaim:
            claimName: mysql-single-pv-claim
```

4. 创建一个 headless 的 svc

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-single
spec:
  ports:
    - port: 3306
  selector:
    app: mysql-single
  clusterIP: None
```

5. 验证当前 mysql 的可用性

实际中可以加上 namespace

```shell
kubectl run -it --rm --image=mysql:5.7 --restart=Never mysql-client -- mysql -h mysql-single -uroot -ppassword
```
