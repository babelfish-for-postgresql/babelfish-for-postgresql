# Building Images

Requirements:

- pipenv or j2cli system-wide


Steps:

- Install and switch to Python virtual env:

```sh
pipenv sync
pipienv shell
```

Or, you can install `j2cli` system-wide:

```sh
sudo pip install j2cli
```

- Render the Dockerfiles using the templates:

```sh
./render.sh -o ubuntu -v focal -T BABEL_2_1_1__PG_14_3
```

- Build:

```sh
./build.sh -o ubuntu -v focal -T BABEL_2_1_1__PG_14_3
```

## Helpers

`build-wrapper.sh` does the render and build of the images. Use `-b` to do the 
build or `-r` for rendering the templates.


## Additional tagging and push


```bash
docker tag babelfishpg:ubuntu.focal registry.gitlab.com/ongresinc/labs/babelfish-on-docker
docker tag babelfishpg:ubuntu.focal ghcr.io/ongres/babelfish-on-docker-compose
docker push registry.gitlab.com/ongresinc/labs/babelfish-on-docker
docker push ghcr.io/ongres/babelfish-on-docker-compose
```

See that you can add more distros in the same compose, and build by build argument as above.


## Building and starting with docker-compose

```yaml
version: "3"

services:
  babelfishpg-ubuntu-focal:
    container_name: babelfishpg-ubuntu-focal
    build:
      context: .
      dockerfile: Dockerfile.ubuntu-focal
      args:
        buildno: 1
        MAX_JOBS: 4
        TAG: BABEL_2_1_1__PG_14_3
    image: babelfishpg:ubuntu.focal
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

networks:
  babelfish:
      
```