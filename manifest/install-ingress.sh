#!/bin/bash

install_dir=$(dirname "$0")
. ${install_dir}/ingress.config
yaml_dir="${install_dir}/yaml"

function set_env(){
    if [[ -z ${IMAGE_REGISTRY} ]]; then
        IMAGE_REGISTRY=quay.io
    fi

    if [[ -z ${NGINX_INGRESS_VERSION} ]]; then
        NGINX_INGRESS_VERSION=0.33.0
    fi

    if [[ -z ${KUBE_WEBHOOK_CERTGEN_VERSION} ]]; then
        KUBE_WEBHOOK_CERTGEN_VERSION=v1.2.2
    fi

    sed -i "s|{IMAGE_REGISTRY}|${IMAGE_REGISTRY}|g" ${yaml_dir}/system.yaml
    sed -i "s|{IMAGE_REGISTRY}|${IMAGE_REGISTRY}|g" ${yaml_dir}/shared.yaml

    sed -i "s|{nginx_ingress_version}|${NGINX_INGRESS_VERSION}|g" ${yaml_dir}/system.yaml
    sed -i "s|{nginx_ingress_version}|${NGINX_INGRESS_VERSION}|g" ${yaml_dir}/shared.yaml

    sed -i "s|{kube_webhook_certgen_version}|${KUBE_WEBHOOK_CERTGEN_VERSION}|g" ${yaml_dir}/system.yaml
    sed -i "s|{kube_webhook_certgen_version}|${KUBE_WEBHOOK_CERTGEN_VERSION}|g" ${yaml_dir}/shared.yaml 
}

function install_system(){
    INGRESS_NGINX_NAME=ingress-nginx-system
    sed -i "s|{ingress-nginx}|${INGRESS_NGINX_NAME}|g" ${yaml_dir}/system.yaml
    kubectl apply -f ${yaml_dir}/system.yaml
}

function install_shared(){
    INGRESS_NGINX_NAME=ingress-nginx-shd
    sed -i "s|{ingress-nginx}|${INGRESS_NGINX_NAME}|g" ${yaml_dir}/shared.yaml
    kubectl apply -f ${yaml_dir}/shared.yaml
}

function uninstall_system(){
    kubectl delete -f ${yaml_dir}/system.yaml
}

function uninstall_shared(){
    kubectl delete -f ${yaml_dir}/shared.yaml
}

function main(){
    set_env

    case "${1:-}" in
    install_system)
        install_system
        ;;
    install_shared)
        install_shared
        ;;
    uninstall_system)
        uninstall_system
        ;;
    uninstall_shared)
        uninstall_shared
        ;;
    *)
        set +x
        echo " service list:" >&2
        echo "  $0 install_system" >&2
        echo "  $0 install_shared" >&2
        echo "  $0 uninstall_system" >&2
        echo "  $0 uninstall_shared" >&2
        ;;
    esac
}

main $1