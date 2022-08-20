# 实验一

创建一个 deployment，一个 service，对外提供服务

service 分类实现

ClusterIP 创建一个集群，在集群内部访问
headless 是一种特殊的 ClusterIP
NodePort 基于 node 的 port 对外暴露服务
LoadBalancer 依赖第三方的 LB 服务
ExternalName 相当于是一个 service 的别名

暴露之后可以直接访问 nodeport 暴露的端口进行访问

以nodeport模式为例
1. 创建一个deployment，运行pod


```shell
# 创建deployment，并通过deployment创建pod
kubectl apply -f app.deployment.yaml
# 列出所有的pod
kubectl get pod
```

2. 创建nodeport svc，指定selector为pod标识的label `app: myapp`

```shell
# 创建svc
kubectl apply -f nodeport.service.yaml
# 打印svc详细信息
kubectl get svc -o wide
# NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE     SELECTOR
# kubernetes        ClusterIP   10.96.0.1       <none>        443/TCP          4h43m   <none>
# myapp-clusterip   ClusterIP   10.104.59.238   <none>        8080/TCP         17m     app=myapp
# myapp-nodeport    NodePort    10.109.142.92   <none>        8080:31030/TCP   13m     app=myapp

# 查看服务启动情况
curl 10.109.142.92:8080

# 查看特定pod处理情况，刷新多次看 {"hostname":"myapp-574c68d4f6-fr65v"} 会有差异
curl 10.109.142.92:8080/hostname
```
在浏览器中输入 `http://10.37.156.156:31030/hostname` 也可访问集群内部的服务

