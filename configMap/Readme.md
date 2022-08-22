# 四种存储类型

### configMap
#### 创建方式
1. 目录方式
创建一个目录./configmap, 创建属性文件
```shell
# test1.properties
cat >test1.properties<<EOF
test.name=test1
test.port=3001
test.env=dev
EOF

cat >test2.properties<<EOF
test2.properties
test.name=test2
test.port=3002
test.env=prod
EOF
```

**根据以上文件创建configmap**
```shell
kubectl create configmap test-config --from-file=./configmap/
```

2. 文件创建
```shell
# test3.properties
cat >test3.properties<<EOF
test.name=test3
test.port=3003
test.env=dev
EOF

# 根据单一文件创建
kubectl create cm single-config --from-file=test3.properties
# 获取config配置
kubectl get cm single-config -o yaml
```

3. 字面创建

```shell
kubectl create cm literal-config --from-literal=test4.name=test4 --from-literal=test4.port=3004 --from-literal=test4.dev=dev
```

#### POD中使用configmap

参考文件`configmap.yaml`
两种导入方式
1. 全量导入
```yaml
envFrom:
  - configMapRef:
      name: app-configmap
```
1. 按值导入
```yaml
env:
  - name: env
    valueFrom:
      configMapKeyRef:
        name: app-configmap
        key: app.env
```

还可以直接使用做命令行变量
command: ["sh", "-c", "env; echo 'port:$(port)'"]

### secret 加密方案


### volume


### PV PVC

