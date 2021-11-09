#!/bin/bash

## 说明
# 借用github的wokrflow, 下载google的镜像文件到docker.io/clay. 
# 仓库名字与gogole镜像的相同
# 不需要手动在dockerhub中创建repository, 如果不存在, 会自动在dockerhub中创建rep

## 使用说明
# 需要mirror到docker.io的镜像, 只需要调用fun_mirror即可
# 不需要操作Dockerfile 或者main.yml

step=1
# ****************** fun ******************
fun_mirror()
{
    # $1为源仓库, $2为tag
    srep=$1
    trep=${srep##*/}
    tag=$2

    # 1. 判断文件是否存在
    if ! [ -f $trep/Dockerfile ]; then
	mkdir -p $trep
	echo -e "ARG tag=0"               >  $trep/Dockerfile
	echo -e "ARG srep=$srep"          >> $trep/Dockerfile
	echo -e 'FROM $srep:$tag'         >> $trep/Dockerfile
    fi
    
    # 1. 获取dockerfile中的tag
    ftag=`sed -n '/tag=/p' $trep/Dockerfile | awk -F '=' '{print $2}'`

    # 2. 比较dockerfile_tag 与 $tag 是否一致, 不一致, 则更新dockerfile && yaml
    if [[ $tag == $ftag ]]; then
	return 0
    fi

    sed -i "/tag=/ c\ARG tag=$tag" $trep/Dockerfile

    ## 根据'#auto-'来查找
    yml=.github/workflows/main.yml
    sed -i "/#auto-on-tags/ c\      - '$trep*' #auto-on-tags"                $yml
    sed -i "/#auto-images/ c\          images: clay2019/$trep  #auto-images" $yml
    sed -i "/#auto-context/ c\          context: ./$trep #auto-context"      $yml
    sed -i "/#auto-tags/ c\          tags: clay2019/$trep:$tag #auto-tags"   $yml

    # 3. 添加新的tag = $trep_$tag, 触发github的workflow
    git add .
    git commit -m "update $trep:$tag" > /dev/null
    git tag ${trep}_$tag
    git push -q 
    git push -q --tags

    echo -e "push tag ${trep}_$tag"
}

# ****************** main ******************
## kubeadm init need images
fun_mirror  k8s.gcr.io/kube-apiserver                           v1.22.3
fun_mirror  k8s.gcr.io/kube-controller-manager                  v1.22.3
fun_mirror  k8s.gcr.io/kube-scheduler                           v1.22.3
fun_mirror  k8s.gcr.io/kube-proxy                               v1.22.3
fun_mirror  k8s.gcr.io/pause                                    3.5
fun_mirror  k8s.gcr.io/etcd                                     3.5.0-0
#fun_mirror  coredns                    v1.8.4  #use docker.io/coredns/corendns

## kube-prometheus
fun_mirror  k8s.gcr.io/prometheus-adapter/prometheus-adapter    v0.9.0
fun_mirror  k8s.gcr.io/kube-state-metrics/kube-state-metrics    v2.1.1

## ingress-nginx
fun_mirror  k8s.gcr.io/ingress-nginx/controller                 v1.0.4 
fun_mirror  k8s.gcr.io/ingress-nginx/kube-webhook-certgen       v1.1.1
