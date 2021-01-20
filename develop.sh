#!/usr/bin/env bash
#stolen from https://serversforhackers.com/dockerized-app/compose-separated
#TODO: backup function
#TODO: add check for returncodes in backup function
#TODO: restore function
#TODO: restoredb: docker exec -i some-mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < /some/path/on/your/host/all-databases.sql
#TODO: doc: https://hub.docker.com/_/mysql
#TODO: log function to view logs
#TODO: check if we are in correct directory
#TODO: check if compose files are available
#TODO: eve-universe sql import function

# backup location
#BACKUP_LOCATION="/var/backups/"
BACKUP_LOCATION="/tmp/"

# Decide which docker-compose file to use
COMPOSE_FILE="dev"

# check if we are root, if not use sudo
SUDO=''
if (( $EUID != 0 )); then
    SUDO='sudo'
fi

# Create docker-compose command to run
COMPOSE="docker-compose -f docker-compose-${COMPOSE_FILE}.yml --env=.env.${COMPOSE_FILE}"

# If we pass any arguments...
if [ $# -gt 0 ];then
    # "backup" 
    if [ "$1" == "backup" ]; then
        #shift 1
	BACKUP_LOCATION=${BACKUP_LOCATION}$(date +%F_%H-%M-%S)
        $SUDO mkdir -p $BACKUP_LOCATION
	$COMPOSE exec db sh -c 'exec mysqldump --all-databases -uroot -p${MYSQL_ROOT_PASSWORD}' > "${BACKUP_LOCATION}/backup_all-databases.sql"
	$COMPOSE stop
	# tar backup volumes
	for i in $($COMPOSE config --volumes);
       	do 
	  PWD_BASENAME=$(basename "$(pwd)")
	  BACKUP_TARGET=$(docker volume inspect --format '{{ .Mountpoint }}' "${PWD_BASENAME}_$i")
	  $SUDO tar cvfz ${BACKUP_LOCATION}/$i.tar.gz ${BACKUP_TARGET}/
        done
    # Else, pass-thru args to docker-compose
    else
        $COMPOSE "$@"
    fi

else
    $COMPOSE ps
fi
