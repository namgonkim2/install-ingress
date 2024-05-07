# admission CA 수동 생성 가이드
* Job에 의해 create와 patch 파드가 실행되며 ```ingress-nginx-admission```의 CA를 생성 및 controller에 적용하게 되는데, Job이 정상적으로 실행되지 못할 경우 시크릿 리소스를 수동으로 생성해 ```validatingwebhookconfiguration`````` 리소스와 controller에 적용해야 한다.
* openssl 패키지 필요
    * openssl ca 생성 확인 명령어
```
openssl x509 -text -in ca.crt -noout
```

### 1. Root CA 개인키(private key) 생성
```
openssl genrsa -out rootca.key 2048
```

### 2. Root CA의 CSR(인증서 서명 요청서) 생성
* 2-1. csr 생성을 위한 설정(config)파일 생성
  * rootca.conf
```
[ req ]
default_bits           = 2048
default_md             = sha1
default_keyfile        = rootca.key
distinguished_name     = req_distinguished_name
extensions             = v3_ca
req_extensions = v3_ca

[ v3_ca ]
basicConstraints       = critical, CA:TRUE, pathlen:0
subjectKeyIdentifier   = hash
keyUsage               = keyCertSign, cRLSign
nsCertType             = sslCA, emailCA, objCA

[ req_distinguished_name ]
countryName                     = Country Name
countryName_default             = KR
```
* 2-2. csr 생성 
```
openssl req -new -key rootca.key -out rootca.csr -config rootca.conf
```

### 3. Root CA 인증서 생성
```
openssl x509 -req \
-days 365 \
-extensions v3_ca \
-set_serial 1 \
-in rootca.csr \
-signkey rootca.key \
-out rootca.crt \
-extfile rootca.conf
```

### 4. 하위 인증서 개인키 생성
```
openssl genrsa -out subcert.key 2048
```

### 5. 하위 인증서 csr 생성
* 5-1. subcert.conf 파일 생성 
   * DNS.1: ingress nginx admission 명으로 변경 
   * DNS.2: ingress nginx admission 명.네임스페이스.svc 로 변경
```
[ req ]
default_bits            = 2048
default_md              = sha1
default_keyfile         = rootca.key
distinguished_name      = req_distinguished_name
extensions             = v3_user

[ v3_user ]
basicConstraints = CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectKeyIdentifier = hash
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
subjectAltName          = @alt_names
[alt_names]
DNS.1   = ingress-nginx-controller-admission
DNS.2   = ingress-nginx-controller-admission.ingress-nginx.svc

[ req_distinguished_name ]
countryName                     = Country Name
countryName_default             = KR
```
* 5-2. csr 생성
```
openssl req -new -key subcert.key -out subcert.csr -config subcert.conf
```

### 6. 하위 인증서 CA 생성
```
openssl x509 -req \
-days 365 \
-extensions v3_user \
-CA rootca.crt \
-CAcreateserial \
-CAkey rootca.key \
-in subcert.csr \
-out subcert.crt \
-extfile subcert.conf
```

### 7. 해당 인증서를 기반으로 시크릿(secret) 리소스 생성 및 controller에 적용
* 7-1. secret.yaml 파일 생성
```

```
```
kubectl apply -f secret.yaml
```
* 7-2. ingress-nginx-controller deployment 리소스의 webhook-cert.secretName에 시크릿 적용
```
kubectl edit deploy -n <ingress-nginx-namespace> <ingress-nginx-controller-deployment>
```
```
apiVersion: apps/v1
kind: Deployment
metadata:
...
  name: ingress-nginx-system-controller
...
  spec:
    containers:
...
      volumes:
      - name: webhook-cert
        secret:
          secretName: <ingress-nginx-secret-name>
...
```

### 8. ingress-nginx 관련 validatingwebhookconfiguration 리소스에 CA 적용
``` 
CA=$(kubectl -n <ingress-nginx-namespace> get secret <ingress-nginx-secret-name> -ojsonpath='{.data.ca}')

kubectl patch validatingwebhookconfigurations <ingress-nginx-admission-name> --type='json' -p='[{"op": "add", "path": "/webhooks/0/clientConfig/caBundle", "value":"'$CA'"}]'
```

### 9. ingress-nginx-controller 파드 재기동
```
kubectl delete pod -n <ingress-nginx-namespace> <ingress-nginx-controller-pod>
```