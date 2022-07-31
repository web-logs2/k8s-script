# k8s 探针（probe）

k8s 有两个探针：就绪探针（readiness probe），存活探针（liveness probe）

探测的方式：ExecAction，TCPSocketAction，HTTPGetAction

**就绪探针**

故意将 readinessProbe 检测的 port 写错，然后因为在当前端口检测不到服务，所以 READY 状态一直为 0/1
将 port 改正确之后，pod 很快 reday

```shell
kubectl get pods
# NAME   READY   STATUS    RESTARTS   AGE
# node   0/1     Running   0          2m56s

kubectl get pods
# NAME   READY   STATUS    RESTARTS   AGE
# node   1/1     Running   0          4s
```

**存活探针**

1. exec 对应 node-livenessprobe-exec.yaml 文件

使用 busybox 创建了一个 pod，当前 pod 在启动时创建一个/tmp/live 的文件，该文件将作为存活检测的依据。
在 30s 后将当前文件删除，以便于存活检测生效触发 pod 重启

```shell
kubectl get pods -w
# NAME   READY   STATUS    RESTARTS      AGE
# node   1/1     Running   1 (19s ago)   88s
# node   1/1     Running   2 (1s ago)    2m19s
```

2. httpGet 对应 node-livenessprobe-httpget.yaml 文件

启动服务之后删除 nginx 下的目标文件

```shell
# 删除nginx index.html文件
kubectl exec -it nginx -- rm -rf /usr/share/nginx/html/index.html

kubectl get pods -w
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          8m20s
# nginx   1/1     Running   1 (1s ago)   11m
```

2. httpGet 对应 node-livenessprobe-socket.yaml 文件

因为改方法就是监听 container 的端口，而容器端口监听失败时 pod 自己就会重启，所以无需验证
