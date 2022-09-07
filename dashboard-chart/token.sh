#!/bin/bash

# 查看 dashboard-admin 的 token
TOKENS=$(kubectl describe serviceaccount dashboard-admin -n kube-system | grep "Tokens:" | awk '{ print $2}')
kubectl describe secret $TOKENS -n kube-system | grep "token:" | awk '{ print $2}'

echo ''
echo 'new-sa-root'
echo ''
kubectl describe secret $(kubectl describe sa new-sa-root -nweb |grep Tokens|awk '{print $2}') -nweb