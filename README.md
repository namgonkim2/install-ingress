


# Nginx Ingress Controller 설치 가이드

## 구성 요소 및 버전
* nginx-ingress-controller ([quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.33.0](https://quay.io/repository/kubernetes-ingress-controller/nginx-ingress-controller?tab=tags))
* kube-webhook-certgen ([docker.io/jettech/kube-webhook-certgen:v1.2.2](https://hub.docker.com/layers/jettech/kube-webhook-certgen/v1.2.2/images/sha256-4ecb4e11ce3b77a6ca002eeb88d58652d0a199cc802a0aae2128c760300ed4de?context=explore))

## Prerequisites

## 폐쇄망 구축 가이드
설치를 진행하기 전 아래의 과정을 통해 필요한 이미지 및 yaml 파일을 준비한다.
1. **폐쇄망에서 설치하는 경우** 사용하는 image repository에 istio 설치 시 필요한 이미지를 push한다. 

    * 작업 디렉토리 생성 및 환경 설정
    ```bash
    mkdir -p ~/install-ingress-nginx-system
    export NGINX_INGRESS_HOME=~/install-ingress-nginx-system
    export NGINX_INGRESS_VERSION=0.33.0
    export KUBE_WEBHOOK_CERTGEN_VERSION=v1.2.2
    
    # image를 push할 폐쇄망 Registry 주소 입력(예:192.168.6.150:5000)
    export REGISTRY=<REGISTRY_IP_PORT>
    
    cd $NGINX_INGRESS_HOME
    ```
    * 외부 네트워크 통신이 가능한 환경에서 필요한 이미지를 다운받는다.
    ```bash
    sudo docker pull quay.io/kubernetes-ingress-controller/nginx-ingress-controller:${NGINX_INGRESS_VERSION}
    sudo docker save quay.io/kubernetes-ingress-controller/nginx-ingress-controller:${NGINX_INGRESS_VERSION} > ingress-nginx_${NGINX_INGRESS_VERSION}.tar
    sudo docker pull jettech/kube-webhook-certgen:${KUBE_WEBHOOK_CERTGEN_VERSION}
    sudo docker save jettech/kube-webhook-certgen:${KUBE_WEBHOOK_CERTGEN_VERSION} > kube-webhook-certgen_${KUBE_WEBHOOK_CERTGEN_VERSION}.tar
    ```
    * install yaml을 다운로드한다.
    ```bash
    wget https://raw.githubusercontent.com/tmax-cloud/install-ingress/4.1/manifest/system.yaml
    wget https://raw.githubusercontent.com/tmax-cloud/install-ingress/4.1/manifest/shared.yaml
    ```
  
2. 위의 과정에서 생성한 tar 파일들을 폐쇄망 환경으로 이동시킨 뒤 사용하려는 registry에 이미지를 push한다.
    ```bash
    sudo docker load < ingress-nginx_${NGINX_INGRESS_VERSION}.tar
    sudo docker load < kube-webhook-certgen_${KUBE_WEBHOOK_CERTGEN_VERSION}.tar
    
    sudo docker tag quay.io/kubernetes-ingress-controller/nginx-ingress-controller:${NGINX_INGRESS_VERSION} ${REGISTRY}/kubernetes-ingress-controller/nginx-ingress-controller:${NGINX_INGRESS_VERSION}
    sudo docker tag jettech/kube-webhook-certgen:${KUBE_WEBHOOK_CERTGEN_VERSION} ${REGISTRY}/jettech/kube-webhook-certgen:${KUBE_WEBHOOK_CERTGEN_VERSION}
    
    sudo docker push ${REGISTRY}/kubernetes-ingress-controller/nginx-ingress-controller:${NGINX_INGRESS_VERSION}
    sudo docker push ${REGISTRY}/jettech/kube-webhook-certgen:${KUBE_WEBHOOK_CERTGEN_VERSION}
    ```


## 설치 가이드
0. [system yaml, shared yaml 수정](#step0-deploy-yaml-%EC%88%98%EC%A0%95)
1. [System Nginx Ingress Controller 배포](#step-1-system-nginx-ingress-controller-%EB%B0%B0%ED%8F%AC)
1. [Shared Nginx Ingress Controller 배포](#step-2-shared-nginx-ingress-controller-%EB%B0%B0%ED%8F%AC)


## Step 0. system yaml, shared yaml 수정
* 목적 : `설치 yaml에 이미지 registry, 버전 정보를 수정`
* 생성 순서 : 
	* 다운로드 받은 install yaml(system.yaml, shared.yaml) 파일을 작업디렉토리($NGINX_INGRESS_HOME)를 만들고 넣는다
	```bash
    export NGINX_INGRESS_HOME=~/install-ingress-nginx-system
    cd $NGINX_INGRESS_HOME
	```
    * 아래의 command를 수정하여 사용하고자 하는 image 버전 정보를 수정한다.
	```bash
    export NGINX_INGRESS_VERSION=0.33.0
    export KUBE_WEBHOOK_CERTGEN_VERSION=v1.2.2
	
	sed -i 's/{nginx_ingress_version}/'${NGINX_INGRESS_VERSION}'/g' system.yaml
	sed -i 's/{kube_webhook_certgen_version}/'${KUBE_WEBHOOK_CERTGEN_VERSION}'/g' system.yaml
	
	export INGRESS_NGINX_NAME=ingress-nginx-shared
	export INGRESS_CLASS=nginx-shd
	
	sed -i 's/ingress-nginx/'${INGRESS_NGINX_NAME}'/g' shared.yaml
	sed -i 's/--ingress-class=nginx/--ingress-class='${INGRESS_CLASS}'/g' shared.yaml
	sed -i 's/ingress-controller-leader-nginx/ingress-controller-leader-'${INGRESS_CLASS}'/g' shared.yaml
	sed -i 's/{nginx_ingress_version}/'${NGINX_INGRESS_VERSION}'/g' shared.yaml
	sed -i 's/{kube_webhook_certgen_version}/'${KUBE_WEBHOOK_CERTGEN_VERSION}'/g' shared.yaml
	```
* 비고 :
    * `폐쇄망에서 설치를 진행하여 별도의 image registry를 사용하는 경우 registry 정보를 추가로 설정해준다.`
	```bash
	# 폐쇄망 Registry 주소 입력(예:192.168.6.150:5000)
    export REGISTRY=<REGISTRY_IP_PORT>
	
	sed -i 's/quay.io\/kubernetes-ingress-controller\/nginx-ingress-controller/'${REGISTRY}'\/kubernetes-ingress-controller\/nginx-ingress-controller/g' deploy.yaml
	sed -i 's/docker.io\/jettech\/kube-webhook-certgen/'${REGISTRY}'\/jettech\/kube-webhook-certgen/g' deploy.yaml
	
	sed -i 's/quay.io\/kubernetes-ingress-controller\/nginx-ingress-controller/'${REGISTRY}'\/kubernetes-ingress-controller\/nginx-ingress-controller/g' deploy.yaml
	sed -i 's/docker.io\/jettech\/kube-webhook-certgen/'${REGISTRY}'\/jettech\/kube-webhook-certgen/g' deploy.yaml
	```

## Step 1. System Nginx Ingress Controller 배포
* 목적 : `ingress-nginx-shared system namespace, clusterrole, clusterrolebinding, serviceaccount, deployment 생성`
* 생성 순서 : 
    * [system.yaml](manifest/system.yaml) 실행 
	```bash
	kubectl apply -f system.yaml
	```
	* 설치 확인
	```console
	$ kubectl get pods -n ingress-nginx
    NAME                                        READY   STATUS      RESTARTS   AGE
    ingress-nginx-admission-create-jxcjs        0/1     Completed   0          11s
    ingress-nginx-admission-patch-h7kv5         0/1     Completed   0          11s
    ingress-nginx-controller-579fddb54f-xhvmn   1/1     Running     0          11s
    ```
	* Trouble Shoot 1:  
        * 현상: 
            - ingress에 정의한 host주소로 연결이 안됨
            - 아래의 명령어로 ingress controller의 로그를 확인했을 때 `fork() failed` 와 같은 문구가 반복적으로 보이면서 정상 동작하지 못하는 경우(cpu의 수가 너무 많아서 발생할 수 있음)
			```bash
			kubectl logs $(kubectl get pods -n ingress-nginx | grep ingress-nginx-controller | awk '{ print $1 }') -n ingress-nginx
			```
		* 해결: worker process의 수 조절 (아래의 명령어 실행하여 process의 수 조절 및 controller pod)
			```bash
			export PROCESS_NUMS="4"
			sed -i 's/# worker-processes: "4"/worker-processes: \"'${PROCESS_NUMS}'\"/g' shared.yaml
			kubectl apply -f system.yaml
			kubectl delete pod $(kubectl get pods -n ingress-nginx | grep ingress-nginx-controller | awk '{ print $1 }') -n ingress-nginx
			```

## Step 2. Shared Nginx Ingress Controller 배포
* 목적 : `ingress-nginx-shared system namespace, clusterrole, clusterrolebinding, serviceaccount, deployment 생성`
* 생성 순서 : 
    * [shared.yaml](manifest/shared.yaml) 실행 
    ```bash
    kubectl apply -f shared.yaml
    ```
    * 설치 확인
    ```console
    $ kubectl get pods -n ingress-nginx-shared
    NAME                                        READY   STATUS      RESTARTS   AGE
    ingress-nginx-shared-admission-create-jxcjs        0/1     Completed   0          11s
    ingress-nginx-shared-admission-patch-h7kv5         0/1     Completed   0          11s
    ingress-nginx-shared-controller-579fddb54f-xhvmn   1/1     Running     0          11s
    ```
	* Trouble Shoot 1:  
        * 현상: 
            - ingress에 정의한 host주소로 연결이 안됨
            - 아래의 명령어로 ingress controller의 로그를 확인했을 때 `fork() failed` 와 같은 문구가 반복적으로 보이면서 정상 동작하지 못하는 경우(cpu의 수가 너무 많아서 발생할 수 있음)
			```bash
			kubectl logs $(kubectl get pods -n ingress-nginx-shared | grep ingress-nginx-shared-controller | awk '{ print $1 }') -n ingress-nginx-shared
			```
		* worker process의 수 조절 (아래의 명령어 실행하여 process의 수 조절 및 controller pod)
			```bash
			export PROCESS_NUMS="4"
			sed -i 's/# worker-processes: "4"/worker-processes: \"'${PROCESS_NUMS}'\"/g' shared.yaml
			kubectl apply -f shared.yaml
			kubectl delete pod $(kubectl get pods -n ingress-nginx-shared | grep ingress-nginx-shared-controller | awk '{ print $1 }') -n ingress-nginx-shared
			```

## 삭제 가이드
## Step 0. system yaml, shared yaml 수정
* 목적 : `설치 yaml에 이미지 registry, 버전 정보를 수정`
* 생성 순서 : 
	* 다운로드 받은 install yaml(system.yaml, shared.yaml) 파일을 작업디렉토리($NGINX_INGRESS_HOME)를 만들고 넣는다
	```bash
    export NGINX_INGRESS_HOME=~/install-ingress-nginx-system
    cd $NGINX_INGRESS_HOME
	```
    * 아래의 command를 수정하여 사용하고자 하는 image 버전 정보를 수정한다.
	```bash
    export NGINX_INGRESS_VERSION=0.33.0
    export KUBE_WEBHOOK_CERTGEN_VERSION=v1.2.2
	
	sed -i 's/{nginx_ingress_version}/'${NGINX_INGRESS_VERSION}'/g' system.yaml
	sed -i 's/{kube_webhook_certgen_version}/'${KUBE_WEBHOOK_CERTGEN_VERSION}'/g' system.yaml
	
	export INGRESS_NGINX_NAME=ingress-nginx-shared
	export INGRESS_CLASS=nginx-shd
	
	sed -i 's/ingress-nginx/'${INGRESS_NGINX_NAME}'/g' shared.yaml
	sed -i 's/--ingress-class=nginx/--ingress-class='${INGRESS_CLASS}'/g' shared.yaml
	sed -i 's/ingress-controller-leader-nginx/ingress-controller-leader-'${INGRESS_CLASS}'/g' shared.yaml
	sed -i 's/{nginx_ingress_version}/'${NGINX_INGRESS_VERSION}'/g' shared.yaml
	sed -i 's/{kube_webhook_certgen_version}/'${KUBE_WEBHOOK_CERTGEN_VERSION}'/g' shared.yaml
	```

## Step 1. System Nginx Ingress Controller 삭제
* 목적 : `ingress-nginx-shared system namespace, clusterrole, clusterrolebinding, serviceaccount, deployment 삭제`
* 생성 순서 : 
    * [system.yaml](manifest/system.yaml) 실행
	```bash
	kubectl delete -f system.yaml
	```

## Step 2. Shared Nginx Ingress Controller 삭제
* 목적 : `ingress-nginx-shared system namespace, clusterrole, clusterrolebinding, serviceaccount, deployment 삭제`
* 생성 순서 : 
    * [shared.yaml](manifest/shared.yaml) 실행
    ```bash
    kubectl delete -f shared.yaml
    ```