# chart 编写

### chart 基本组成

1. Chart/yaml 文件

```yaml
apiVersion: v1
name: demo
version: 1.0.0
```

2. templates/deployment.yaml 文件

和之前写 deployment 的方式一致

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
        - name: demo
          image: ansike/ansike:test-docker-node-v1
          env:
            - name: port
              value: "8080"
          ports:
            - name: demo
              containerPort: 8080
```

3. templates/service.yaml 文件

和之前写 service 的方式一致

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo
spec:
  type: NodePort
  ports:
    - name: demo
      port: 8080
      targetPort: 8080
  selector:
    app: demo
```

通过 helm 把 chart 运行起来

```shell
# 需要制定一个name
helm install demo .
# 列出所有的helm
helm list
# 查看状态
helm status demo
# 删除helm
helm delete demo
```

### 基于配置去更改

1. 定义 values.yaml 文件

```yaml
image:
  respository: ansike/ansike
  tag: test-docker-node-v2
```

2. 修改 deployment.yaml 文件

主要修改为 image，引用了 values.yaml 中的定义

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
        - name: demo
          image: "{{.Values.image.respository}}:{{.Values.image.tag}}"
          env:
            - name: port
              value: "8080"
          ports:
            - name: demo
              containerPort: 8080

```

通过 helm 把 chart 更新一下

```shell
# 更新配置
helm upgrade demo .
# 查看历史
helm history demo
# 回滚到第一个版本
# 会把所有操作都记录下来，这个比deployment的回滚要自然的多
helm rollback demo 1
```
