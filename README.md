
# Nginx Ingress Controller 설치 가이드

## 구성 요소 및 버전
* nginx-ingress-controller ([kubernetes/ingress-nginx:release-1.5](https://github.com/kubernetes/ingress-nginx/tree/release-1.5))

## Prerequisites

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
    $ wget https://raw.githubusercontent.com/tmax-cloud/hypercloud-install-guide/master/IngressNginx/system/yaml/deploy.yaml
    ```
  
2. 위의 과정에서 생성한 tar 파일들을 폐쇄망 환경으로 이동시킨 뒤 사용하려는 registry에 이미지를 push한다.
    ```bash
    $ sudo docker load < ingress-nginx_${NGINX_INGRESS_VERSION}.tar
    
    $ sudo docker tag registry.k8s.io/ingress-nginx/controller:${NGINX_INGRESS_VERSION} ${REGISTRY}/ingress-nginx/controller:${NGINX_INGRESS_VERSION}
    
    $ sudo docker push ${REGISTRY}/ingress-nginx/controller:${NGINX_INGRESS_VERSION}
    ```


## 설치 가이드 (Nginx Ingress Controller 배포)
* 생성 순서 : 
    * [deploy.yaml](manifest/deploy.yaml) 실행 
	```bash
	$ kubectl apply -f deploy.yaml
	```
	* 설치 확인
	```console
	$ kubectl get pods -n ingress-nginx
    NAME                                        READY   STATUS      RESTARTS   AGE
    ingress-nginx-shared-admission-create-jxcjs        0/1     Completed   0          11s
    ingress-nginx-shared-admission-patch-h7kv5         0/1     Completed   0          11s
    ingress-nginx-shared-controller-579fddb54f-xhvmn   1/1     Running     0          11s
    ```
* Ingress 를 통한 nginx-ingress 활용 방법 : 
    * spec.ingressClassName에 nginx 추가 (ingressClassName: nginx)
    * metadata.annotations에 kubernetes.io/ingress.class: nginx 추가
