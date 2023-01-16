function init_ssl {
    # Reference by:
    #   https://lynlab.co.kr/blog/72
    #   https://www.lesstif.com/system-admin/dns-txt-record-let-s-encrypt-ssl-59343172.html
    #   https://oasisfores.com/letsencrypt-wildcard-ssl-certificate/
    docker run -it --rm --name certbot \
      -v '/etc/letsencrypt:/etc/letsencrypt' \
      -v '/var/lib/letsencrypt:/var/lib/letsencrypt' \
      certbot/certbot certonly -d '*.coinlocker.link' -d 'coinlocker.link' --manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory
}

function renew_ssl {
    docker run -it --rm --name certbot \
      -v '/etc/letsencrypt:/etc/letsencrypt' \
      -v '/var/lib/letsencrypt:/var/lib/letsencrypt' \
      certbot/certbot renew --manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory
}

if [[ $1 = "init" ]]; then
    init_ssl
elif [[ $1 = "renew" ]]; then
    renew_ssl
else
    echo "argument is not allowed"
    echo "allowed argument: [init, renew]"
    echo "ex. bash set_ssl.sh init"
fi
