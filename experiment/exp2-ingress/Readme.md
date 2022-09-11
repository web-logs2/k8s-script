# 实验二 ingress 

安装ingress

https://kubernetes.github.io/ingress-nginx/deploy/#quick-start

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/cloud/deploy.yaml
```

### 单deployment ingress 实验
1. 一个deployment.yaml
replicas:3
image: ansike/ansike:test-docker-node-v2
env: PORT: 8080

2. 一个svc svc.yaml
NodePort: 
containerPort: 8080

3. 一个ingress ingress.yaml

```shell
# 直接 cat 可能没有权限
sudo sh -c 'echo "10.37.156.156 www.node.com" >> /etc/hosts'
# 获取 svc
kubectl get svc
# NAME              TYPE           CLUSTER-IP      EXTERNAL-IP        PORT(S)          AGE
# svc-ingress       NodePort       10.110.33.7     <none>             8080:32456/TCP   30m

curl www.node.com:32456/hostname
```

### 多deployment ingress 实验