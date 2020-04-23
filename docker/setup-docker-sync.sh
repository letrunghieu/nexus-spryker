#!/usr/bin/env bash

volumes=( nxsacademy-ardb-data nxsacademy-project-data nxsacademy-elastic-data nxsacademy-db-data nxsacademy-rabbitmq-data )
stores=( DE AT US )

docker-sync start -c ../docker-sync.yml

for volumename in "${volumes[@]}"
do
    docker volume create --name=${volumename}
done

docker-compose -f docker-compose.yml -f docker-compose-dev.yml up -d

rmqcontainer=$(docker ps --filter name=nxsacademy_rabbitmq -q)
appcontainer=$(docker ps --filter name=nxsacademy_app -q)

sleep 30s

docker exec -i ${rmqcontainer} rabbitmqctl add_user admin mate20mg
docker exec -i ${rmqcontainer} rabbitmqctl set_user_tags admin administrator

for store in "${stores[@]}"
do
    docker exec -i ${rmqcontainer} rabbitmqctl add_vhost /${store}_development_zed
    docker exec -i ${rmqcontainer} rabbitmqctl add_user ${store}_development mate20mg
    docker exec -i ${rmqcontainer} rabbitmqctl set_user_tags ${store}_development administrator
    docker exec -i ${rmqcontainer} rabbitmqctl set_permissions -p /${store}_development_zed ${store}_development ".*" ".*" ".*"
    docker exec -i ${rmqcontainer} rabbitmqctl set_permissions -p /${store}_development_zed admin ".*" ".*" ".*"
done

docker exec -i ${appcontainer} composer install -n
