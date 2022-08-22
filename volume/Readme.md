### volume

容器磁盘的文件生命周期随着容器的销毁而丢失，而pod在运行期间通常都需要容器之间进行文件共享，volume就是为了解决容器之间文件共享的

卷的类型有很多中

**emptyDir 类型**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-volume-empty
spec:
  containers:
    - name: pod-volume-empty-container
      image: ansike/ansike:test-docker-node-v2
      volumeMounts:
        - name: empty-volume
          mountPath: "/etc/volume"
    - name: pod-volume-empty-busybox
      image: busybox:1
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: empty-volume
          mountPath: "/etc/busyxxx"
  volumes:
    - name: empty-volume
      emptyDir: {}
```

创建好pod之后进入不同的容器操作挂载的目录发现可以实现同步
```shell
kubectl apply -f volume/volume-empty.yaml
# 进第一个容器
kubectl exec -it  pod-volume-empty -c pod-volume-empty-container
# 注入文件数据
cat >/etc/volume/a.txt<<EOF
asas
EOF

kubectl exec -it pod-volume-empty -c pod-volume-empty-busybox /bin/sh
# 打印挂在目录下的文件
cat /etc/busyxxx/a.txt
# 可以看到符合预期即可
# asas
```

**hostpath 类型**

将主机节点文件系统中的文件或者目录挂载到集群中

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-volume-hostpath
spec:
  containers:
    - name: pod-volume-empty-container
      image: ansike/ansike:test-docker-node-v2
      volumeMounts:
        - name: empty-volume
          mountPath: "/etc/volume"
    - name: pod-volume-empty-busybox
      image: busybox:1
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: empty-volume
          mountPath: "/etc/busyxxx"
  volumes:
    - name: empty-volume
      hostPath:
        path: '/data00'
        type: Directory
```

ls + cat 对应目录的文件可以发现本机的目录已经挂载到对应的目录下，但是在容器中创建的文件会直接作用到主机目录中
如果看不到，确认pod所在的node是否正确

