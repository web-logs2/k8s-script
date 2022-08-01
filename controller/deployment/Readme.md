# deployment 
```shell
# 修改副本数为5
kubectl scale deployment my-deployment --replicas=5

# 修改镜像为nginx
kubectl set image deployment/my-deployment my-app=nginx:1.14.2

# 回滚到上一次
kubectl rollout undo deployment my-deployment

# 查看deployment更新历史，做定向回滚使用
kubectl rollout history deployment my-deployment
# deployment.apps/my-deployment
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         <none>

# 回滚到第一个版本
kubectl rollout undo deployment my-deployment --to-revision=1

# 以上的所有操作都可以通过直接编辑deployment实现
kubectl edit deployment my-deployment
```
