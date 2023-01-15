pid=`ps aux | grep "webhook -hooks ./webhook/hook.jso" | awk -F ' ' 'NR == 1 { print $2 }'`

if [[ pid != "" ]];then
    kill -9 ${pid}
fi

nohup webhook -hooks ./webhook/hook.json -verbose &> webhook.log &
