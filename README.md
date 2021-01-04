Forked from https://github.com/KryptedGaming/pathfinder-docker

Dockerfile for running [Pathfinder](https://github.com/exodus4d/pathfinder), the mapping tool for EVE Online.

## Two setups are available:
### Production
- You already tested pathfinder in local testing mode and want to get going
- Requirements:
- - Docker host/server with docker-compose installed
- - Domain
- - A/AAAA records pointing to your serverip
- TLS certificates will be pulled from lets encrypt

### Development/local testing
- You want to setup a local pathfinder instance to test stuff or develop plugins
- Requirements:
- - Docker host/server with docker-compose installed
- - Modified hostsfile with pathfinder.lan pointing to 127.0.0.1
-  TLS cerificate will be caddy-internal
-  Final URL will be  `https://pathfinder.lan:9000`

## Wrapper scripts
- To enable non-IT people to use this repository, there are two docker-compose wrapper scripts included:
- - `production.sh` is a wrapper for `docker-compose -f docker-compose-prod.yml --env=.env.prod`
- - `development.sh` is a wrapper for `docker-compose -f docker-compose-dev.yml --env=.env.dev`
-  Additional functions (WIP) are creating/restoring sql backups, viewing logfiles, creating a support zip, etc...
-  Further information available below [Administration.](#Administration)

# Installation production
1. Clone this repo and change directory
2. Copy the example `.env.sample` file to `.env.prod`
3. Copy the example `config/Caddyfile.sample` file to `config/Caddyfile-prod`
4. Edit `.env.prod` and `config/Caddyfile-prod` and check your config with `./production.sh config`
5. If satisfied, start up your instance with `./production.sh up -d` 
6. If youre getting the pathfinder setup page with letsencrypt staging TLS-certificate , everything is working
7. Stop the cluster with `./production.sh stop` and comment `acme_ca` in `config/Caddyfile-prod` to receive live letsencrypt TLS-certificate
8. Start  cluster with `./production.sh up -d`

# Installation development/local testing
1. Clone this repo and change directory
2. Copy the example `.env.sample` file to `.env.dev`
3. Copy the example `config/Caddyfile.sample` file to `config/Caddyfile-dev`
4. Edit `.env.dev` and `config/Caddyfile-dev` and check your config with `./development.sh config`
5. Start your instance with `./development.sh up -d`

# Setup
1. Navigate to your Pathfinder page, go through setup.
2. Create the databases using the database controls in the setup page.
3. [Import static database.](#Importing-static-database)
4. Import from ESI at the Cronjob section of the setup page.
5. Build Systems data index under `Build search index` in the Administration section of the setup page.
5. Restart your container with `SETUP=False`.
6. You're live!

# Importing static database
1. `wget https://github.com/exodus4d/pathfinder/raw/master/export/sql/eve_universe.sql.zip`
2. `unzip eve_universe.sql.zip`
3. `docker cp eve_universe.sql "$(./production.sh ps | grep db | awk '{ print $1}'):/eve_universe.sql"`
4. `./production.sh exec db sh -c 'exec mysql -uroot -p eve_universe < /eve_universe.sql'`
5. **Optional** `rm eve_universe.sql*`
6. [Complete Setup.](#Setup)

# Administration
- The wrapper scripts pass every argument to `docker-compose`, just with modified `docker-compose` file location and `.env` file location
- Additional planned functions are 
- - Creating SQL backups
- - Restoring SQL backups 
- - Viewing application/webserver logs from volumes
- - Creating a support zip, containing application and webserver logs for further analyzing

# Updating pathfinder
- TODO




Feel free to contribute, there are many improvements (check TODO strings in repo) that still need to be made. 
