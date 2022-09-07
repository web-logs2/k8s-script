# helm 安装 dashboard

1. helm 资源下载到本地

```yaml
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

helm pull kubernetes-dashboard/kubernetes-dashboard

tar -zxvf kubernetes-dashboard-5.10.0.tgz
```

2. 创建配置 my-values.yaml

```shell
cat >my-values.yaml<<EOF
service:
  type: NodePort               # 由于需要对外暴露服务，所以在此直接采取Nodeport方式
  nodePort: 30644              # 自定义对外暴露的端口

ingress:
  enabled: false               # 我这里无需使用ingress，所以直接使用false禁用ingress，如果需要通过域名访问，则参考values.yaml文件进行ingress的自定义修改

metrics-server:
  enabled: true                # 同理，如果没有预先装过metrics插件，则需要手动开启
  args:
  - --kubelet-preferred-address-types=InternalIP
  - --kubelet-insecure-tls

rbac:
  create: true
  clusterRoleMetrics: true
  clusterReadOnlyRole: true
  clusterAdminRole: true       # 让 dashboard 的权限够大，这样我们可以方便操作多个 namespace

serviceAccount:
  create: true
  name: dashboard-admin        # 自定义账户名称，自动创建，方便用脚本查询登录令牌
EOF

# 根据自己的配置进行安装
helm install -f my-values.yaml --namespace kube-system kubernetes-dashboard .
```

3. 登录

因为是 https 的缘故，需要建议使用火狐浏览器进行访问 https://${ip}:30644
chrome 需要导入证书较为麻烦

调用 `token.sh` 获取页面登录需要的 token

4. 绑定关系

部署好 K8S dashboard 之后，首次登录，可能会在右上角通知面板中出现很多告警：cannot list xxx
是 rbac 权限问题，说明当前 sa 的用户没有足够的权限去看到所有的内容
可以将服务账户 kubernetes-dashboard 跟 cluster-admin 这个集群管理员权限对象绑定起来

```shell
cat >kubernetes-dashboard-ClusterRoleBinding.yaml<<EOF
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
EOF
kubectl create -f kubernetes-dashboard-ClusterRoleBinding.yaml
```

或者参考文件`new-sa.yaml`文件 创建新的 clusterRole 进行绑定

```shell
kubectl apply -f new-sa.yaml
# 获取刚创建的token，在页面上登录
kubectl describe secret $(kubectl describe sa new-sa-root -nweb |grep Tokens|awk '{print $2}') -nweb
```
