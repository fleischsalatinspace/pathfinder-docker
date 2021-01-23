#!/usr/bin/env bash
#stolen from https://serversforhackers.com/dockerized-app/compose-separated
#TODO: restore function
#TODO: restoredb: docker exec -i some-mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < /some/path/on/your/host/all-databases.sql
#TODO: doc: https://hub.docker.com/_/mysql
#TODO: log function to view logs
#TODO: check if we are in correct directory
#TODO: check if compose files are available
#TODO: eve-universe sql import function

set -Eeuo pipefail

# backup location
BACKUP_LOCATION="/var/backups/"

# Decide which docker-compose file to use
COMPOSE_FILE="prod"

# check if we are root, if not use sudo
SUDO=''
if [ "${EUID}" != "0" ]; then
    SUDO='sudo'
fi

# setup_colors for message function
setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}
setup_colors

# message function
msg() {
  echo >&2 -e "${1-}"
}

# Create docker-compose command to run
COMPOSE="docker-compose -f docker-compose-${COMPOSE_FILE}.yml --env=.env.${COMPOSE_FILE}"

backup() {
	BACKUP_LOCATION=${BACKUP_LOCATION}$(date +%F_%H-%M-%S)
        msg "Creating backup location at ${BACKUP_LOCATION}"
        if ! mkdir -p "${BACKUP_LOCATION}" ; then
        	msg "${RED}Failed${NOFORMAT} to create backup location at ${BACKUP_LOCATION}"  
		exit 1
	fi
	msg "${GREEN}Successfully${NOFORMAT} created backup location at ${BACKUP_LOCATION}"
        msg "Creating MySQL backup"
	if ! ${COMPOSE} exec db sh -c "exec mysqldump --all-databases -uroot -p\${MYSQL_ROOT_PASSWORD}" | gzip > "${BACKUP_LOCATION}/backup_all-databases.sql.gz" ; then
        	msg "${RED}Failed${NOFORMAT} to create MySQL backup"  
		exit 1
	fi
	msg "${GREEN}Successfully${NOFORMAT} created MySQL backup"
        msg "Stopping docker containers"
	if ! ${COMPOSE} stop >/dev/null 2>&1 ; then
        	msg "${RED}Failed${NOFORMAT} to stop docker containers"  
		exit 1
	fi
	msg "${GREEN}Successfully${NOFORMAT} stopped docker containers"
	# tar backup volumes
	for i in $(${COMPOSE} config --volumes);
       	do 
	  PWD_BASENAME=$(basename "$(pwd)")
	  BACKUP_TARGET=$(docker volume inspect --format '{{ .Mountpoint }}' "${PWD_BASENAME}_${i}")
          msg "Creating docker container volume backup of ${i}"
	  if ! ${SUDO} tar cvfz "${BACKUP_LOCATION}"/"${i}".tar.gz "${BACKUP_TARGET}"/ >/dev/null 2>&1 ; then
        	msg "${RED}Failed${NOFORMAT} to create backup of container volume ${i}"  
		exit 1
	  fi
	  msg "${GREEN}Successfully${NOFORMAT} created backup of ${i} volume"
        done
}

restore() {
 msg "Not implemented."
}

support-zip() {
	BACKUP_LOCATION=${BACKUP_LOCATION}$(date +%F_%H-%M-%S)_support-zip
        msg "Creating support-zip location at ${BACKUP_LOCATION}"
        if ! mkdir -p "${BACKUP_LOCATION}" ; then
        	msg "${RED}Failed${NOFORMAT} to create support-zip location at ${BACKUP_LOCATION}"  
		exit 1
	fi
	msg "${GREEN}Successfully${NOFORMAT} created support-zip location at ${BACKUP_LOCATION}"
	# export docker mysql db container logs 
        msg "Creating database container logs export"
	if ! ${COMPOSE} logs --no-color -t db | gzip >> "${BACKUP_LOCATION}"/database.log.gz ; then
               msg "${RED}Failed${NOFORMAT} to create database container log export"  
               exit 1
        fi
        msg "${GREEN}Successfully${NOFORMAT} created database container log export"	
        msg "Stopping docker containers"
	if ! ${COMPOSE} stop >/dev/null 2>&1 ; then
        	msg "${RED}Failed${NOFORMAT} to stop docker containers"  
		exit 1
	fi
	msg "${GREEN}Successfully${NOFORMAT} stopped docker containers"
	# tar backup logs volumes
	for i in $(${COMPOSE} config --volumes | grep logs);
       	do 
	  PWD_BASENAME=$(basename "$(pwd)")
	  BACKUP_TARGET=$(docker volume inspect --format '{{ .Mountpoint }}' "${PWD_BASENAME}_${i}")
          msg "Creating docker container volume backup of ${i}"
	  if ! ${SUDO} tar cvfz "${BACKUP_LOCATION}"/"${i}".tar.gz "${BACKUP_TARGET}"/ >/dev/null 2>&1 ; then
        	msg "${RED}Failed${NOFORMAT} to create backup of container volume ${i}"  
		exit 1
	  fi
	  msg "${GREEN}Successfully${NOFORMAT} created backup of ${i} volume"
        done
}

# If we pass any arguments...
if [ $# -gt 0 ];then
    # "backup" 
    if [ "$1" == "backup" ]; then
        #shift 1
	echo -e "This will backup your MySQL database and then backup every container volume. In this process your pathfinder will be ${RED}stopped${NOFORMAT}.\nDo you want to continue?"
        select yn in "Yes" "No"; do
            case ${yn} in
                Yes ) backup; break;;
                No ) exit;;
		* ) exit;;
            esac
        done
    elif [ "$1" == "restore" ]; then
        #shift 1
	echo -e "This will restore a backup of your MySQL database and then restore every container volume. In this process your pathfinder will be ${RED}stopped${NOFORMAT} and all current data in the volumes will be lost.\nDo you want to continue?"
        select yn in "Yes" "No"; do
            case ${yn} in
                Yes ) restore; break;;
                No ) exit;;
		* ) exit;;
            esac
        done
    elif [ "$1" == "support-zip" ]; then
        #shift 1
	echo -e "This will create a support-zip containing application logs for further analyzing. No user data or API keys are included. In this process your pathfinder will be ${RED}stopped${NOFORMAT}.\nDo you want to continue?"
        select yn in "Yes" "No"; do
            case ${yn} in
                Yes ) support-zip; break;;
                No ) exit;;
		* ) exit;;
            esac
        done

    # Else, pass-thru args to docker-compose
    else
        ${COMPOSE} "$@"
    fi

else
    msg "No commands received. Displaying help and running docker containers"
    msg "${GREEN}COMMANDS${NOFORMAT}"
    msg "       backup: creates a backup of the mysql database and container volumes"
    msg "       restore: restores mysql database and container volumes from a provided backup"
    msg "       support-zip: creates a file containing application and service logs"
    msg ""
    ${COMPOSE} ps
fi
