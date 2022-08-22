### secret 加密方案

解决了密码，密钥，token等敏感数据的配置问题。不需要把这些敏感的数据暴露到镜像或者pod中。secret可以通过环境变量或者volume使用

secret有三种类型
1. Service Account 用来访问kubernets api，并自动挂在到pod的/run/secrets/kubernetes.id/serviceaccount 目录中
2. Opaque base64格式编码的secret 用来存储密码和密钥（一般使用这个）
3. Kubernetes.id/dockerconfigjson 用来存储私有docker registry的认证信息

Opaque

**通过volume方式使用secret**
创建一个secret，设置两个值 name和password,

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret-volume
type: Opaque
data:
  name: YWRtaW4K
  password: MTIzNDU2Cg==
```
name和password通过base64编码进行存储

```shell
echo 'admin'|base64
# YWRtaW4K
echo '123456'|base64
# MTIzNDU2Cg==
```
创建一个pod，在pod中使用volume对secret进行挂载和存储

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret
spec:
  volumes:
    - name: secret-volume
      secret:
        secretName: my-secret-volume
  containers:
    - image: ansike/ansike:test-docker-node-v2
      name: pod-secret-container
      volumeMounts:
        - name: secret-volume
          mountPath: "/etc/secrets"
          readOnly: true
```
可以直接使用本目录下的secret-volume.yaml文件进行创建

进入pod中，cd到/etc/secrets目录下 ls
```shell
ls
# 有两个文件
name  password
# 输出文件内容就是挂载进来的secret
cat name
# admin
```

**通过env方式使用secret**

使用env的方式传入
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret-env
spec:
  containers:
    - image: ansike/ansike:test-docker-node-v2
      name: pod-secret-container
      env:
        - name: name
          valueFrom:
            secretKeyRef:
              name: my-secret-env
              key: name
        - name: pass
          valueFrom:
            secretKeyRef:
              name: my-secret-env
              key: password
      envFrom:
        - secretRef:
            name: my-secret-env
```