### pv (persistentvolume)

#### 概念
1. PV PsistentVolume 
由管理员设置的存储，是集群中的资源。独立于pod的生命周期。

2. PVC PersistentVolumeClaim

是用户存储的请求。与pod类似，pod消费节点资源，pvc消费pv资源。Pod可以请求特定级别的资源（CPU和内存），声明可以请求特定的大小和访问模式（eg：读/写一次或只读多次挂在）

3. 静态PV

集群管理员创建的一些PV。他们带有可供集群用户使用的实际存储细节。存在于k8s的API中用于消费。

4. 动态PV

相对于静态PV，动态PV可以动态的基于PVC的请求去创建PV的方式

5. 绑定

master中控制环路监视新的PVC，寻找匹配的PV，将他们绑定到一起。PV和PVC是一一对应的。

6. 持久卷生命保护

PVC保护的目的是pod被移除时，PVC绑定的PV不会被移除，避免数据丢失。

7. PV的类型

目前PV的类型以插件的形式实现
常见的有：NFS, HostPath, Clusterfs, iSCSi


#### PV文件说明

PV声明文件
```yaml
apiVersion: v1
kind: PersistentVolume
metadata: 
  name: pv001
spec:
  capacity: 
    storage: 5Gi
  volumeMode: Filesystem
  accessModes: 
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: slow
  mountOptions:
    - hard
    - nfsvers=4.1
  nfs:
    path: '/tmp'
    server: 172.17.0.2

```
1. accessModes 访问模式

- ReadWriteOnce（RWO） 该卷可以被单个节点以读/写模式挂载
- ReadOnlyMany（ROX） 该卷可以被多个节点以只读模式挂载
- ReadWriteMany（RWX） 该卷可以被多个节点以读/写模式挂载

2. persistentVolumeReclaimPolicy 回收策略

- Retain 保留，手动回收
- Recycle 回收，基本擦除
- Delete 删除，关联的存储资产被删除

当前只有NFS和HostPath支持回收策略

3. PV状态

Available 可用 还没有任何声明绑定
Bound 绑定 卷已经被资源绑定
Released 已释放 声明被删除，还未被重新绑定
Failed 失败 该卷的自动回收失败


### 持久化演示说明 - NFS

NFS（network file system）是网络文件系统。主要是通过网络让不同的机器，不同的操作系统能够彼此分享文件，让客户端通过网络访问位于服务器磁盘中的数据。
NFS使用RPC协议进行通信，通过不同的客户端及服务端通过RPC分享相同的文件系统

debian 10 安装nfs过程

```shell
# 准备目录 /src/nfs 作为授权目录
mkdir /src/nfs
# 给目录授权
chmod 777 /src/nfs

# 安装nfs服务
sudo apt install nfs-kernel-server

# 配置授权的目录，ip写* 表示全部。生产中ip，根据实际情况配置
sudo sh -c 'echo "/srv/nfs *(rw,sync,no_subtree_check)" >> /etc/exports'

# 重启nfs服务
sudo systemctl restart nfs-kernel-server

# 安装nfs客户端
sudo apt install nfs-common
# 把客户端目录挂在到nfs server上
sudo mount -t nfs 10.37.156.156:/srv/nfs ~/platform

# 此时在客户端的platform目录中创建文件，即可在服务端的目录中看到
# 在服务端创建文件也可以在客户端看到

# 取消挂载目录
sudo umount ~/platform
```

参考文档： https://blog.csdn.net/allway2/article/details/107546648

创建一个PV

```yaml
apiVersion: v1
kind: PersistentVolume
metadata: 
  name: pv-nfs-001
spec:
  capacity: 
    storage: 5Gi
  volumeMode: Filesystem
  accessModes: 
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  nfs:
    path: '/srv/nfs'
    server: 10.37.156.156

```

同理可以创建多个pv，创建一个statefulset资源，使用多个

```shell
# 创建多个目录
mkdir nfs{1..3}
# 授权
chmod 777 nfs1 nfs2 nfs3
# 增加多个pv目录
sudo sh -c 'echo "/srv/nfs1 *(rw,sync,no_subtree_check)" >> /etc/exports'
sudo sh -c 'echo "/srv/nfs2 *(rw,sync,no_subtree_check)" >> /etc/exports'
sudo sh -c 'echo "/srv/nfs3 *(rw,sync,no_subtree_check)" >> /etc/exports'
sudo systemctl restart nfs-kernel-server

# 先创建pv资源
kubectl apply -f pv.yaml
# 创建svc和statefulset
kubectl apply -f pvc.yaml

kubectl get pv
# NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                  STORAGECLASS   REASON   AGE
# pv-nfs-001   5Gi        RWX            Retain           Bound       default/volume-www-pvc-statefulset-0   nfs                     11m
# pv-nfs-002   5Gi        RWX            Retain           Bound       default/volume-www-pvc-statefulset-1   nfs                     11m
# pv-nfs-003   5Gi        RWX            Retain           Bound       default/volume-www-pvc-statefulset-2   nfs                     11m
# pv-nfs-004   5Gi        RWX            Retain           Available                                          nfs                     11m
kubectl get pvc 
# NAME                           STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# volume-www-pvc-statefulset-0   Bound    pv-nfs-001   5Gi        RWX            nfs            11m
# volume-www-pvc-statefulset-1   Bound    pv-nfs-002   5Gi        RWX            nfs            11m
# volume-www-pvc-statefulset-2   Bound    pv-nfs-003   5Gi        RWX            nfs            11m
kubectl get pod 
# pvc-statefulset-0                   1/1     Running            0                2m41s
# pvc-statefulset-1                   1/1     Running            0                10m
# pvc-statefulset-2                   1/1     Running            0                10m
```


#### 关于statefulset

1. 匹配pod name（网络标识）的模式为[statefulset名称].[序列号]。比如我们 pvc-statefulset-0 
2. Statefulset为每个Pod副本创建了一个DNS域名，域名的格式为[podName].[headlessServerName]。服务之间是通过Pod域名来进行通信的而非pod ip，当Pod所在node发生故障时会飘移到其他node上，Pod ip会发生变化，但是Pod域名不会
3. StatefuleSet使用headless服务来控制Pod的域名。域名的格式为[serviceName].[namespace].svc.cluster.local，其中cluster.local是集群的域名
4. 根据volumeClaimTemplates为每个pod创建一个pvc，pvc的命名规则时[volumeClaimTemplates.name]-[podName]。如上文中的 `volume-www-pvc-statefulset-0`
5. 删除pod不会删除pvc，需要手动删除pvc释放pv
   
statefulset的启动顺序
1. 有序部署 所有pod被按照顺序从0开始有序串行的创建出来
2. 有序删除 删除时终止的顺序时从N-1到0
3. 有序扩展 扩展时之前的pod必须时running或者ready状态

statefulset的使用场景
1. 稳定的持久化存储，Pod重新调度后还是能访问相同的持久化数据，基于PVC来实现
2. 稳定的网络标识，Pod重新调度指挥PodName和HostName不变
3. 有序部署，有序扩展，基于initContainers来实现
4. 有序收缩
