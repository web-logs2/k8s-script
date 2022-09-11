# helm 安装 dashboard

### 1. helm 资源下载到本地

```yaml
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

helm pull kubernetes-dashboard/kubernetes-dashboard

tar -zxvf kubernetes-dashboard-5.10.0.tgz
```

### 2. 创建配置 my-values.yaml

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

### 3. 授权 绑定 role

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

### 4. 登录

- NodePort 模式直接访问
  因为是 https 的缘故，需要建议使用火狐浏览器进行访问 https://${ip}:30644
  chrome 需要导入证书较为麻烦

- 自签名证书 + ingress

调用 `token.sh` 获取页面登录需要的 token

> 以下为优化部分

---

### 5. openssl 生成 CA 证书

- 什么是 x509 证书链
  - x509 证书一般会用到三类文件，key，csr，crt。
  - key 是私用密钥，openssl 格式，通常是 rsa 算法。
  - csr 是证书请求文件，用于申请证书。在制作 csr 文件的时候，必须使用自己的私钥来签署申请，还可以设定一个密钥。
  - crt 是 CA 认证后的证书文件（windows 下面的 csr，其实是 crt），签署人用自己的 key 给你签署的凭证。

1. 生产证书

```shell
# Generate CA private key (制作ca.key 私钥)
openssl genrsa -out ca.key 2048

# Generate CSR
openssl req -new -key ca.key -out ca.csr

#OpenSSL创建的自签名证书在chrome端无法信任，需要添加如下
echo "subjectAltName=DNS:rojao.test.com,IP:10.10.2.137" > cert_extensions

# Generate Self Signed certificate（CA 根证书）
openssl x509 -req -days 365 -in ca.csr -signkey ca.key -extfile cert_extensions -out ca.crt
```

2. 将证书和密钥写入 secret 中
   编辑 kubernetes-dashboard-certs 的 secret 文件，新增 data 部分
   使用上文生产的 ca.crt 和 ca.key 做 base64 编码 分别对应 tls.crt 和 tls.key

```yaml
data:
  tls.crt: "xxx"
  tls.key: "xxx"
```

3. 编辑 my-values.yaml

```yaml
service:
  type: ClusterIP
  externalPort: 443 # 使用443端口
# 开启ingress
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"

  paths:
    - /
  customPaths:
    - pathType: ImplementationSpecific
      backend:
        service:
          name: >-
            {{ include "kubernetes-dashboard.fullname" . }}
          port:
            number: 443
  hosts:
    - kubernetes-dashboard.domain.com
  tls:
    - secretName: kubernetes-dashboard-certs
      hosts:
        - kubernetes-dashboard.domain.com
```

4. 更新 helm

```shell
 helm upgrade -f my-values.yaml kubernetes-dashboard . -n kube-system
```

5. 检查配置，确认访问

```shell
# 配置域名解析
sudo sh -c 'echo "10.37.156.156 kubernetes-dashboard.domain.com" >> /etc/hosts'

# 查看 ingress 的配置
kubectl describe ingress kubernetes-dashboard -n kube-system

# 可以看到以下 host 对应的 svc 和 endpoint
# Name:             kubernetes-dashboard
# Namespace:        kube-system
# Address:          10.37.156.21
# Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
# TLS:
#   kubernetes-dashboard-certs terminates kubernetes-dashboard.domain.com
# Rules:
#   Host                             Path  Backends
#   ----                             ----  --------
#   kubernetes-dashboard.domain.com
#                                       kubernetes-dashboard:443 (192.168.3.25:8443)
# Annotations:                       kubernetes.io/ingress.class: nginx
#                                    kubernetes.io/tls-acme: true
#                                    meta.helm.sh/release-name: kubernetes-dashboard
#                                    meta.helm.sh/release-namespace: kube-system
#                                    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
#                                    service.alpha.kubernetes.io/app-protocols: {"https":"HTTPS"}
# Events:
#   Type    Reason  Age                  From                      Message
#   ----    ------  ----                 ----                      -------
#   Normal  Sync    28m (x5 over 5h51m)  nginx-ingress-controller  Scheduled for sync

kubectl get svc -n ingress-nginx
# 因为ingress的请求都是通过该svc进行转发的，如果不是80:80或者443:443 这种时需要注意域名加port访问
# 如 80:31052/TCP,443:31054/TCP 需要 curl http://kubernetes-dashboard.domain.com:31052
# NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                 AGE
# ingress-nginx-controller             NodePort    10.98.63.226    <none>        80:80/TCP,443:443/TCP   22d
```

此时即可直接在浏览器中访问
