# 实验二 多deployment, ingress 实验
1. 2个deployment
replicas:3

- deployment1.yaml
image1: ansike/ansike:test-docker-node-v1
env: PORT: 8081

- deployment2.yaml
image2: ansike/ansike:test-docker-node-v2
env: PORT: 8082

2. 2个svc svc.yaml

- svc1.yaml
containerPort: 8081

- svc2.yaml
containerPort: 8082

3. 2个ingress 

ingress1.yaml
host: www.node1.com
service.name: svc-ingress-1

ingress2.yaml
host: www.node2.com
service.name: svc-ingress-2

```shell
# 直接 cat 可能没有权限
sudo sh -c 'echo "10.37.156.156 www.node1.com" >> /etc/hosts'
sudo sh -c 'echo "10.37.156.156 www.node2.com" >> /etc/hosts'

# 获取 svc
kubectl get svc
# NAME              TYPE           CLUSTER-IP      EXTERNAL-IP        PORT(S)          AGE
# svc-ingress       NodePort       10.110.33.7     <none>             8080:32456/TCP   30m

curl www.node1.com:32456/hostname
curl www.node2.com:32456/hostname
```