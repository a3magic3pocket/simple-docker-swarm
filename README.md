# simple-docker-swarm
docker swarm으로 simple locker 애플리케이션을 운영합니다.

# 환경설정
- ```
    sudo apt-get update
    sudo apt-get upgrade

    # 도커 설치
    curl -fsSL https://get.docker.com -o get-docker.sh
    DRY_RUN=1 sudo sh ./get-docker.sh

    # 웹훅 서버 설치
    sudo apt-get install webhook
    ```

# 홈 디렉토리
- /home/ubuntu/simple-docker-swarm

# ssl 인증서 발급
- ```
    # certbot을 이용하여 *.coinlocker.link, coinlocker.link의 ssl 인증서 발급
    # - 다른 도메인일 경우, coinlocker.link만 본인 도메인으로 변경
    # - dns을 이용하여 소유권 인증을 하므로 본인이 dns를 설정할 수 있어야 함
    bash ./set_ssh.sh init

    # 결과 확인
    # - 파일 출력이 정상적으로 된다면 성공
    cat /etc/letsencrypt/live/coinlocker.link/fullchain.pem
    cat /etc/letsencrypt/live/coinlocker.link/privkey.pem
    ```

# ssl 인증서 갱신
- ```
    # 갱신 명령
    bash ./set_ssl.sh renew
    
    # 2달에 한 번씩 갱신하도록 crontab에 설정 
    crontab -e
    # 아래 내용 추가 후 저장
    0 0 1 */2 * /usr/bin/env bash /home/ubuntu/simple-docker-swarm/set_ssl.sh renew && docker service update a3_nginx
    ```

# 배포 명령
- ```
    # 스택 배포
    # - docker-compose.yml에서 이미지 외 다른 변수 들이 변경되었을 경우, 스택 배포 해야 함
    # - 주로 secrets이나 configs가 변경되었을 경우 사용
    bash ./deploy.sh stack

    # 서비스 배포
    # - 이미지만 변경되었을 경우, 해당 서비스를 새 이미지로 교체하여 재배포하는 것
    # simple-api-example 서비스 배포
    bash ./deploy.sh service:api

    # simple-web-example 서비스 배포
    bash ./deploy.sh service:web

    # 권한 설정
    # - 프로그램이 실행할 수 있도록 실행권한 부여
    chmod +x ./deploy.sh
    ```

# 웹훅 서버
- ```
    # 역할
    # - 웹훅 서버는 dockerhub에서 새로운 이미지가 push 되었을 경우,
    #   dockerhub에서 웹훅 서버 URL로 요청을 보내고,
    #   웹훅 서버는 해당 URL과 연결된 스크립트를 실행하여 서비스배포를 진행함

    # 설정 변경
    # - hooks.json을 수정하여 설정을 변경할 수 있음
    vim ./webhook/hooks.json

    # simple-api-example 배포 스크립트
    vim ./webhook/scripts/simple-api-deploy.sh

    # simple-web-example 배포 스크립트
    vim ./webhook/scripts/simple-web-deploy.sh

    # 권한 설정
    # - 프로그램이 실행할 수 있도록 실행권한 부여
    chmod +x ./webhook/scripts/simple-api-deploy.sh
    chmod +x ./webhook/scripts/simple-web-deploy.sh

    # 웹훅 서버 실행(또는 재실행)
    bash ./run_webhook.sh

    # 로그 조회(Ctrl+c를 눌러 종료)
    tail -f ./webhook.log
    ```
