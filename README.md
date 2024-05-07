
# Nginx Ingress Controller 설치 가이드
- hypercloud 5.3

## 개요
- 인그레스 오브젝트의 기능(e.g. 각 모듈에 접근하기 위한 라우팅 규칙 설정, IP에 대해 상이한 도메인 이름으로 처리, SSL/TLS 인증 등)을 사용하기 위해 배포한다.
- 쿠버네티스 API서버를 통해 Ingress 리소스의 변화를 추적하고 그에 맞게 L7 로드밸런서를 설정하는 역할을 한다.

## 구성 요소 및 버전
* ingress-nginx-controller 
    * registry.k8s.io/ingress-nginx/controller:v1.10.1@sha256:e24f39d3eed6bcc239a56f20098878845f62baa34b9f2be2fd2c38ce9fb0f29e
* kube-webhook-certgen 
    * registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.1@sha256:36d05b4077fb8e3d13663702fa337f124675ba8667cbd949c03a8e8ea6fa4366

## Prerequisites
* kubernetes v1.29, 1.28, 1.27, 1.26

## 폐쇄망 구축 가이드
설치를 진행하기 전 아래의 과정을 통해 필요한 이미지 및 yaml 파일을 준비한다.
1. **폐쇄망에서 설치하는 경우** 사용하는 image repository에 istio 설치 시 필요한 이미지를 push한다. 

    * 작업 디렉토리 생성 및 환경 설정
    ```bash
    $ mkdir -p ingress-nginx
    $ export NGINX_INGRESS_HOME=path-to/ingress-nginx
    $ export NGINX_INGRESS_VERSION=v1.10.1@sha256:e24f39d3eed6bcc239a56f20098878845f62baa34b9f2be2fd2c38ce9fb0f29e
    $ export NGINX_INGRESS_CERTGEN=v1.4.1@sha256:36d05b4077fb8e3d13663702fa337f124675ba8667cbd949c03a8e8ea6fa4366
    
    # image를 push할 폐쇄망 Registry 주소 입력(예:192.168.6.150:5000)
    $ export REGISTRY=<REGISTRY_IP_PORT>
    
    $ cd $NGINX_INGRESS_HOME
    ```
    * 외부 네트워크 통신이 가능한 환경에서 필요한 이미지를 다운받는다.
    ```bash
    $ sudo docker pull registry.k8s.io/ingress-nginx/controller:${NGINX_INGRESS_VERSION}
    $ sudo docker save registry.k8s.io/ingress-nginx/controller:${NGINX_INGRESS_VERSION} > ingress-nginx_${NGINX_INGRESS_VERSION}.tar

    $ sudo docker pull registry.k8s.io/ingress-nginx/kube-webhook-certgen:${NGINX_INGRESS_CERTGEN}
    $ sudo docker save registry.k8s.io/ingress-nginx/kube-webhook-certgen:${NGINX_INGRESS_CERTGEN} > ingress-nginx_${NGINX_INGRESS_CERTGEN}.tar
    ```
    * install yaml을 다운로드한다.
    ```bash
    $ wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
    ```
  
2. 위의 과정에서 생성한 tar 파일들을 폐쇄망 환경으로 이동시킨 뒤 사용하려는 registry에 이미지를 push한다.
    ```bash
    $ sudo docker load < ingress-nginx_${NGINX_INGRESS_VERSION}.tar
    $ sudo docker tag registry.k8s.io/ingress-nginx/controller:${NGINX_INGRESS_VERSION} ${REGISTRY}/ingress-nginx/controller:${NGINX_INGRESS_VERSION}
    $ sudo docker push ${REGISTRY}/ingress-nginx/controller:${NGINX_INGRESS_VERSION}

    // NGINX_INGRESS_CERTGEN 동일 
    ...

    ```


## 설치 가이드 (Nginx Ingress Controller 배포)
* 생성 : 
    * [ingress-nginx.yaml](manifest/ingress-nginx.yaml) 실행 
	```bash
	$ kubectl apply -f ingress-nginx.yaml
	```
	* 설치 확인
	```console
	$ kubectl get pods -n ingress-nginx
    NAME                                        READY   STATUS      RESTARTS   AGE
    ingress-nginx-admission-create-jxcjs        0/1     Completed   0          11s
    ingress-nginx-admission-patch-h7kv5         0/1     Completed   0          11s
    ingress-nginx-controller-579fddb54f-xhvmn   1/1     Running     0          11s
    ```
* 삭제
    ```bash
    $ kubectl delete -f ingress-nginx.yaml
    ```

## AWS 설치
### NLB
1. kubectl apply
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/aws/deploy.yaml
```