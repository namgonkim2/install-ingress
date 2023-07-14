
# Nginx Ingress Controller (v1.5.1) 설치 가이드

## 개요
- 인그레스 오브젝트의 기능(e.g. 각 모듈에 접근하기 위한 라우팅 규칙 설정, IP에 대해 상이한 도메인 이름으로 처리, SSL/TLS 인증 등)을 사용하기 위해 배포한다.
- 쿠버네티스 API서버를 통해 Ingress 리소스의 변화를 추적하고 그에 맞게 L7 로드밸런서를 설정하는 역할을 한다.

## 구성 요소 및 버전
* ingress-nginx-controller 
    * registry.k8s.io/ingress-nginx/controller:v1.5.1@sha256:4ba73c697770664c1e00e9f968de14e08f606ff961c76e5d7033a4a9c593c629
* kube-webhook-certgen 
    * registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20220916-gd32f8c343@sha256:39c5b2e3310dc4264d638ad28d9d1d96c4cbb2b2dcfb52368fe4e3c63f61e10f

## Prerequisites
* kubernetes v1.25

## 폐쇄망 구축 가이드
설치를 진행하기 전 아래의 과정을 통해 필요한 이미지 및 yaml 파일을 준비한다.
1. **폐쇄망에서 설치하는 경우** 사용하는 image repository에 istio 설치 시 필요한 이미지를 push한다. 

    * 작업 디렉토리 생성 및 환경 설정
    ```bash
    $ mkdir -p ~/install-ingress-nginx-system
    $ export NGINX_INGRESS_HOME=~/install-ingress-nginx-system
    $ export NGINX_INGRESS_VERSION=v1.5.1@sha256:4ba73c697770664c1e00e9f968de14e08f606ff961c76e5d7033a4a9c593c629
    
    # image를 push할 폐쇄망 Registry 주소 입력(예:192.168.6.150:5000)
    $ export REGISTRY=<REGISTRY_IP_PORT>
    
    $ cd $NGINX_INGRESS_HOME
    ```
    * 외부 네트워크 통신이 가능한 환경에서 필요한 이미지를 다운받는다.
    ```bash
    $ sudo docker pull registry.k8s.io/ingress-nginx/controller:${NGINX_INGRESS_VERSION}
    $ sudo docker save registry.k8s.io/ingress-nginx/controller:${NGINX_INGRESS_VERSION} > ingress-nginx_${NGINX_INGRESS_VERSION}.tar
    ```
    * install yaml을 다운로드한다.
    ```bash
    $ wget https://raw.githubusercontent.com/tmax-cloud/install-ingress/k8s-1.25/manifest/ingress-nginx-system.yaml
    # 위 주소가 다운로드가 안될 시 아래 주소로 다운
    $ wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml
    ```
  
2. 위의 과정에서 생성한 tar 파일들을 폐쇄망 환경으로 이동시킨 뒤 사용하려는 registry에 이미지를 push한다.
    ```bash
    $ sudo docker load < ingress-nginx_${NGINX_INGRESS_VERSION}.tar
    $ sudo docker tag registry.k8s.io/ingress-nginx/controller:${NGINX_INGRESS_VERSION} ${REGISTRY}/ingress-nginx/controller:${NGINX_INGRESS_VERSION}
    $ sudo docker push ${REGISTRY}/ingress-nginx/controller:${NGINX_INGRESS_VERSION}
    ```


## 설치 가이드 (Nginx Ingress Controller 배포)
* 생성 : 
    * [ingress-nginx-system.yaml](manifest/ingress-nginx-system.yaml) 실행 
	```bash
	$ kubectl apply -f ingress-nginx-system.yaml
	```
	* 설치 확인
	```console
	$ kubectl get pods -n ingress-nginx-system
    NAME                                        READY   STATUS      RESTARTS   AGE
    ingress-nginx-system-admission-create-jxcjs        0/1     Completed   0          11s
    ingress-nginx-system-admission-patch-h7kv5         0/1     Completed   0          11s
    ingress-nginx-system-controller-579fddb54f-xhvmn   1/1     Running     0          11s
    ```
* 삭제
    ```bash
    $ kubectl delete -f ingress-nginx-system.yaml
    ```