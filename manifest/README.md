# Install Script을 통한 설치 가이드

## Step 0. ingress.config 수정
* 목적 : `설치 yaml에 이미지 registry, 버전 정보를 수정`
	* NGINX_INGRESS_CONTROLLER와 KUBE_WEBHOOK_CERTGEN의 이미지 주소 및 버전 설정
    * 수정하지 않는 경우 default 값으로 설치 진행

## Step 1. nginx ingress controller 설치
* system nginx : 
	```bash
	./install-ingress.sh install_system
	```
* shared nginx : 
	```bash
	./install-ingress.sh install_shared
	```

## Step 2. nginx ingress controller 삭제
* system nginx : 
	```bash
	./install-ingress.sh uninstall_system
	```
* shared nginx : 
	```bash
	./install-ingress.sh uninstall_shared
	```
