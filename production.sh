#!/usr/bin/env bash

# Decide which docker-compose file to use
COMPOSE_FILE="prod"

# Create docker-compose command to run
COMPOSE="docker-compose -f docker-compose-${COMPOSE_FILE}.yml --env=.env.${COMPOSE_FILE}"

# If we pass any arguments...
if [ $# -gt 0 ];then
        $COMPOSE "$@"

else
    $COMPOSE ps
fi
