# 实验一

创建一个 deployment，一个 service，对外提供服务

service 分类实现

ClusterIP 创建一个集群，在集群内部访问
headless 是一种特殊的 ClusterIP
NodePort 基于 node 的 port 对外暴露服务
LoadBalancer 依赖第三方的 LB 服务
ExternalName 相当于是一个 service 的别名

暴露之后可以直接访问 nodeport 暴露的端口进行访问
