#!/bin/bash

## 说明
# 借用github的wokrflow, 下载google的镜像文件到dockerhub

step=1
# ****************** fun ******************
fun_check()
{
    # 1. 获取dockerfile中的tag
    tag=`sed -n '/tag=/p' $1/Dockerfile | awk -F '=' '{print $2}'`
    echo $tag

    # 2. 比较dockerfile_tag 与 $2 是否一致, 不一致, 则更新dockerfile && yaml
    if [[ $tag == $2 ]]; then
	return 0
    fi

    sed -i "/tag=/ c\ARG tag=$2" $1/Dockerfile
    ## 根据'#auto-make'来查找
    sed -i "/#auto-make/ c\          tags: $2 #auto-make" .github/workflows/$1.yml
    
    # 3. 添加新的tag = $1_$2, 触发github的workflow
    git commit -am "update $1:$2"
    git tag $1_$2
    git push
    git push --tags

    echo -e "push tag $1_$2"
}

# ****************** main ******************
## kubeadm init need images
fun_check  kube-apiserver             v1.22.3
fun_check  kube-controller-manager    v1.22.3
fun_check  kube-proxy                 v1.22.3
fun_check  kube-scheduler             v1.22.3
fun_check  pause                      3.1
fun_check  etcd                       3.3.10
fun_check  coredns                    1.3.1
