#!/bin/sh
TEST_QUICK_INSTALL=${TEST_QUICK_INSTALL:-false}
parse_commandline() {
  while test $# -gt 0
  do
    key="$1"
    case "$key" in
      --test-quick-install)
         echo "--test-quick-install detected, quick install scripts will be tested"
         TEST_QUICK_INSTALL="true"
         shift
      ;;        
      *)
        die "Got an unexpected argument: $1"
      ;;
    esac
  done
}

build_docker(){
  python dockerfile-templater.py "$1"
  docker build \
    -t "babelfish:$1" \
    -f "distros/$1/Dockerfile" \
  . > "output/$1/$1.out" 2>&1
}

add_to_report() {
  DISTRO=$1
  STATUS=$2
  cat << EOF >> report.md
| $DISTRO | $STATUS |
EOF
}

test_create_extension(){
  DISTRO=$1

  docker run --rm -d --name babelfish "babelfish:$DISTRO"
  sleep 5
  run_in_babelfish_container "CREATE USER babelfish_user WITH CREATEDB CREATEROLE PASSWORD 'babelfish' INHERIT;"
  run_in_babelfish_container "CREATE DATABASE demo OWNER babelfish_user;"
  run_in_babelfish_container "ALTER SYSTEM SET babelfishpg_tsql.database_name = 'demo'; SELECT pg_reload_conf();"
  run_in_babelfish_container "ALTER DATABASE demo SET babelfishpg_tsql.migration_mode = 'single-db';"
  run_in_babelfish_container 'CREATE EXTENSION IF NOT EXISTS "babelfishpg_tds" CASCADE;' "demo"
  run_in_babelfish_container "CALL SYS.INITIALIZE_BABELFISH('babelfish_user');" "demo"
  docker stop babelfish
}

run_in_babelfish_container(){  
  STATEMENT=$1
  if [ -z "${2+x}" ]
  then
    docker exec babelfish /usr/local/pgsql-13.4/bin/psql -c "$STATEMENT"
  else
    docker exec babelfish /usr/local/pgsql-13.4/bin/psql -c "$STATEMENT" -d "$2"
  fi
}

get_distro_id(){
  DISTRO=$1
  BASE_CONTAINER=$(echo "$DISTRO" | sed -e 's/\./:/ ')

  ID=$(docker run --rm --name "$distro" "$BASE_CONTAINER" grep "^ID=" /etc/os-release | cut -d "=" -f 2 | sed -e 's/^"//' -e 's/"$//')
  VERSION=$(docker run --rm --name "$distro" "$BASE_CONTAINER" grep "^VERSION_ID=" /etc/os-release | cut -d "=" -f 2 | sed -e 's/^"//' -e 's/"$//')
  echo "$ID.$VERSION"
}

generate_quickinstall_script(){
  DISTRO=$1
  DISTRO_ID=$2
  python quick-start-templater.py "$DISTRO" "$DISTRO_ID"
  cp quick-install.sh "output/quickinstall/install.sh"
}

build_quickstart_container(){
  DISTRO=$1
  BASE_CONTAINER=$(echo "$DISTRO" | sed -e 's/\./:/ ')
  rm -rf tmp
  mkdir tmp
  
  cat << EOF > tmp/Dockerfile
FROM $BASE_CONTAINER
ENV TZ="Europe/Madrid"
ENV DEBIAN_FRONTEND=noninteractive
ADD output/quickinstall /quickinstall
WORKDIR /quickinstall
CMD ["sh", "-e", "install.sh"]
EOF

  docker build -t "babelfish:$DISTRO" -f tmp/Dockerfile . 
}

run_quickstart_container(){
  DISTRO=$1
  docker run --rm --name babelfish "babelfish:$DISTRO"
}

parse_commandline "$@"

cat << EOF > report.md
## Babelfish Docker images builed 
| Distro | Status |
| ------ | ------ |
EOF

rm -rf output
mkdir output
mkdir output/quickinstall
mkdir output/quickinstall/prerequisites
find distros -mindepth 1 -maxdepth 1 -printf "%f\n" | while read -r distro
do 
  echo "Building docker image for $distro"

  mkdir "output/$distro"

  DISTRO_ID=$(get_distro_id "$distro")
  if build_docker "$distro"
  then
    echo "Testing extension creation for $distro"
    if test_create_extension "$distro" > "output/$distro/$distro.out" 2>&1
    then
      generate_quickinstall_script "$distro" "$DISTRO_ID" 
      if [ "$TEST_QUICK_INSTALL" = "true" ]
      then
        build_quickstart_container "$distro" "$DISTRO_ID" > /dev/null 2>&1
        echo "Testing quick install script for $distro"
        if run_quickstart_container "$distro" > "output/$distro/$distro.out" 2>&1
        then 
          add_to_report "$distro" "OK"
          echo "Generating installation documentation for $distro"
          python doc-templater.py "$distro"
        else
          add_to_report "$distro" "QUICK INSTALL FAILED"
        fi  
      else 
        echo "Skipping testing of quickinstall scripts for $distro"
        add_to_report "$distro" "OK"
        echo "Generating installation documentation for $distro"
        python doc-templater.py "$distro"
      fi      
    else
      add_to_report "$distro" "CREATE EXTENSION FAILED"
    fi
  else
    add_to_report "$distro" "BUILD FAILED"
  fi

done
