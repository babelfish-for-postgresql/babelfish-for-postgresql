# Babelfish on Docker

Docker templates and Dockerfiles for Babelfish.

For building the images, see `BUILD.md`.

## Building the image

```bash
./build.sh -o ubuntu -v focal -T BABEL_2_1_1__PG_14_3
```

See `releases.json` for referring to the available Dockerfiles, or
check `<version>/distro/osversion/`.


## Docker run

```bash
docker run -d -i -t  \
        -e POSTGRES_PASSWORD=password -e POSTGRES_DB=postgres \
        -e POSTGRES_USER=postgres -e BABELFISH_USER=bbf \
        -e BABELFISH_PASS=password -e BABELFISH_DB=bbf \
        -e BABELFISH_MIGRATION_MODE=multi-db \
        -e POSTGRES_HOST_AUTH_METHOD=trust \
        -p 1433:1433 -p 5432:15432 \
        --name babelfishpg-2.1.1-ubuntu.focal \
        babelfishpg:2.1.1-ubuntu.focal
```


## Docker Compose

For using the available docker-compose files, go to the corresponding
flavor folder (`<version>/distro/osversion/`) and execute:

```bash
docker-compose up
```

A basic structure with the build included would be:

eg:

```yaml
version: "3"

services:
  babelfishpg-2.1.1-amazonlinux-2:
    container_name: babelfishpg-2.1.1-amazonlinux.2
    build:
      context: .
      dockerfile: Dockerfile
      args:
        buildno: 1
        MAX_JOBS: 4
    image: babelfishpg:2.1.1-amazonlinux.2
    ports:
      # Port forwarding not supported by BabelfishPG
      - 1433:1433
      - 5432:15432
    environment:
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=postgres
      - POSTGRES_USER=postgres
      - BABELFISH_USER=bbf
      - BABELFISH_PASS=password
      - BABELFISH_DB=bbf
      - BABELFISH_MIGRATION_MODE=multi-db
      - POSTGRES_HOST_AUTH_METHOD=trust
    networks:
      - babelfish

...

networks:
  babelfish:
```

## Access 

Access through local:

```bash
docker-compose exec babelfishpg-ubuntu-focal bash -c 'sqlcmd -H localhost:1433 -P password -U bbf' 
```

To access through host mode in the same machine, it can be issued a similar command to the below (you may need to change the network name entry):

```bash
DOCKER_BBF_IP=$(docker inspect -f "{{with index .NetworkSettings.Networks \"babelfish-on-docker_babelfish\"}}{{.IPAddress}}{{end}}" babelfishpg-ubuntu-focal)
```

Then, you can either use your psql or your MSSQL Server client of preference ([FreeTDS](https://www.freetds.org/) in the following example):

```bash
/opt/babelfish/bin/psql -h ${DOCKER_BBF_IP} -p 5432 -U bbf bbf 
tsql -S ${DOCKER_BBF_IP} -p 1433 -U bbf bbf
```

> BABELFISH_DB is the Postgres database that has the Babelfish extensions, and it is called `master` in SQL Server. So, certain clients like DBeaver will need to specify the master instead of the Postgres name.

## Multi-DB / Single-DB

The current image uses multi-db as the default migration mode. It means that all the databases you create in the Babelfish database (through TDS), will be reflected as Postgres _schemas_ in the selected Babelfish database.

The mapped schemas will had the `*-dbo` suffix. This mode is useful if you rely on multi schema login against your SQL Server.

Single-DB will allow only one user database, and it might be the most recommended mode for beginners.


## Extending the image

The current entrypoint is compatible with [the Official Docker Images](https://hub.docker.com/_/postgres/).


## References

Other docker implementations found: 

- [from Toyonut](https://github.com/Toyonut/babelfish-testbed).
- [from rsubr](https://github.com/rsubr/postgres-babelfish)

