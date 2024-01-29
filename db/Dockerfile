FROM postgres:16.1-alpine3.19

# The local path to the init files
ARG INIT_PATH

# COPY $ENV_FILE_PATH /.secrets

# ENV POSTGRES_PASSWORD_FILE=/.secrets

COPY $INIT_PATH /docker-entrypoint-initdb.d/
