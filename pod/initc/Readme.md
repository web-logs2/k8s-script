# initC (initContainers)

于 pod 启动前的容器，可以在此时做数据，文件的初始化，做基础服务的依赖检测。

initC 容器可以有多个，多个容器之间串行执行，执行完成之后才开始主容器的运行

**该 demo 展示了一个容器依赖两个服务的启动**

**1. 启动 pod**

观察 pod 的状态一直处于 init 的状态，这是因为依赖的两个服务还没有启动

```shell
# 初始化pod
kubectl apply -f /home/ansike/ansike/k8s-script/pod/initc/node-initc.yaml
# 获取pod
kubectl get pods
# NAME   READY   STATUS     RESTARTS   AGE
# node   0/1     Init:0/2   0          6s
```

**2. 启动第一个服务：myservice**

启动之后需要等几十秒看 Init 的状态变成 1/2 了说明当前服务一个被 initC 检测到了
检测的方式其实很简单，就是用了 nslookup，向 k8s 的 coredns 进行了域名解析查询。
因为每一个服务启动之后都会向 k8s 进行域名注册

```shell
# 初始化服务
kubectl apply -f /home/ansike/ansike/k8s-script/pod/initc/mydb.yaml
# 获取pod
kubectl get pods
# NAME   READY   STATUS     RESTARTS   AGE
# node   0/1     Init:1/2   0          5m44s
```

**2. 启动第二个服务：mydb**

```shell
# 初始化服务
kubectl apply -f /home/ansike/ansike/k8s-script/pod/initc/myservice.yaml
# 获取pod
kubectl get pods
# NAME   READY   STATUS    RESTARTS   AGE
# node   1/1     Running   0          7m11s
```
