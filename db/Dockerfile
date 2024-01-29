FROM postgres:16.1-alpine3.19

# The local path to the init files
ARG INIT_PATH
COPY $INIT_PATH /docker-entrypoint-initdb.d/

# The local path of the config file for postgres
ARG CONFIG_FILE_PATH
COPY $CONFIG_FILE_PATH /etc/postgres/postgres.conf
