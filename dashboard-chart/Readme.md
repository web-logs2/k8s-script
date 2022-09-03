# helm 安装 dashboard

1. helm 资源下载到本地

```yaml
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

helm pull kubernetes-dashboard/kubernetes-dashboard

tar -zxvf kubernetes-dashboard-5.10.0.tgz
```

2. 修改配置 values.yaml

```
service.type=NodePort
service.externalPort=80
protocolHttp=true
```

3. 绑定关系

部署好 K8S dashboard 之后，首次登录，通常会在右上角通知面板中出现很多告警：cannot list xxx
是 rbac 权限问题

可以将服务账户 kubernetes-dashboard 跟 cluster-admin 这个集群管理员权限对象绑定起来

```shell
echo >>kubernetes-dashboard-ClusterRoleBinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
  
kubectl create -f kubernetes-dashboard-ClusterRoleBinding.yaml
```
