#!/usr/bin/env bash
#TODO: backup function
#TODO: backupdb: docker exec some-mysql sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > /some/path/on/your/host/all-databases.sql
#TODO: restoredb: docker exec -i some-mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < /some/path/on/your/host/all-databases.sql
#TODO: doc: https://hub.docker.com/_/mysql
#TODO: log function to view logs
#TODO: check if we are in correct directory
#TODO: check if compose files are available
#TODO: eve-universe sql import function

# Decide which docker-compose file to use
COMPOSE_FILE="dev"

# Create docker-compose command to run
COMPOSE="docker-compose -f docker-compose-${COMPOSE_FILE}.yml --env=.env.${COMPOSE_FILE}"

# If we pass any arguments...
if [ $# -gt 0 ];then
        $COMPOSE "$@"

else
    $COMPOSE ps
fi
