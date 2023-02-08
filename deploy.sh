#!/usr/bin/env bash
STACK_NAME=a3
WORKING_DIR_PATH="$(dirname $0)"
API_DIR_PATH="${WORKING_DIR_PATH}/simple-api-example"
WEB_DIR_PATH="${WORKING_DIR_PATH}/simple-web-example"
export IDENTITY_KEY=`cat ${WORKING_DIR_PATH}/secrets/IDENTITY_KEY`
export AUTH_SECRET_KEY=`cat ${WORKING_DIR_PATH}/secrets/AUTH_SECRET_KEY`

# 초기화, git 최신화
function git_init {
    git --git-dir=${API_DIR_PATH}/.git pull origin main
    git --git-dir=${WEB_DIR_PATH}/.git pull origin main
}

# API_TAG, WEB_TAG 할당
function set_tags {
    api_image_url=`get_image_url ${API_DIR_PATH}/simple-api.yml api`
    web_image_url=`get_image_url ${WEB_DIR_PATH}/simple-web.yml web`
    export API_TAG=`echo ${api_image_url} | cut -d ":" -f 2`
    export WEB_TAG=`echo ${web_image_url} | cut -d ":" -f 2`
}

# 새 이미지가 업데이트 되었는지 확인
function is_image_updated {
    local is_different=0

    declare -a arr=("simple-api:${API_TAG}" "simple-web:${WEB_TAG}")

    for row in "${arr[@]}"
    do
        local prefix=${row%%:*}
        local yml_tag=${row##*:}

        local current_tag=`docker ps | grep ${prefix} | awk -F ' ' '{ print $2 }' | awk -F ':' '{ print $2 }'`

        if [[ ${current_tag} != ${yml_tag} ]];then
            is_different=1
            break
        fi
    done

    return ${is_different}
}

# 초기 세팅
function init {
    git_init
    set_tags
    is_image_updated

    local is_different=$?
    if [[ ${is_different} -eq 0 ]];then
        echo "image is not updated"
        exit 1;
    fi
}

# api, web manifest 파일에서 이미지 URL 추출
function get_image_url {
    local yml_file_path=$1
    local keyword=$2

    line=`cat ${yml_file_path} | grep "image: " | grep ${keyword}`
    prefix=`echo ${line} | cut -d ":" -f 2`
    tag=`echo ${line} | cut -d ":" -f 3`

    echo ${prefix}:${tag}
}

# 스택배포
function deploy_stack {
    docker stack rm ${STACK_NAME}
    
    while [[ $(docker network ls | grep "${STACK_NAME}_" | wc -c) -ne 0 ]];
    do
        sleep 1;
    done
    
    docker stack deploy -c docker-compose.yml ${STACK_NAME}
}

# 서비스배포
function deploy_service {
    local service_suffix=$1
    local image_url=""
    if [[ $service_suffix = "api" ]];then
        image_url=`get_image_url ${API_DIR_PATH}/simple-api.yml api`
    elif [[ $service_suffix = "web" ]];then
        image_url=`get_image_url ${WEB_DIR_PATH}/simple-web.yml web`
    else
        echo "deploy_service::service_suffix is not allowed. ${service_suffix}"
        exit 1;
    fi

    docker service update --image ${image_url} "${STACK_NAME}_${service_suffix}"
}

# 도움말
function help {
    echo "+----- HOW TO RUN -----+"
    echo "ex) bash deploy.sh <mode>"
    echo "    allowed mode = [stack, service:api, service:web]"
    echo "+----------------------+"
}

# secret 파일 존재 유무 확인
if [[ ${IDENTITY_KEY} = "" ]]; then
    echo "${WORKING_DIR_PATH}/secrets/IDENTITY_KEY is empty"
    exit 1
fi
if [[ ${AUTH_SECRET_KEY} = "" ]]; then
    echo "${WORKING_DIR_PATH}/secrets/AUTH_SECRET_KEY is empty"
    exit 1
fi

# 실행
if [[ $1 = "stack" ]];then
    init
    deploy_stack
elif [[ $1 = "service:api" ]];then
    init
    deploy_service "api"
elif [[ $1 = "service:web" ]];then 
    init
    deploy_service "web"
else
    echo "mode is empty"
    help
fi
