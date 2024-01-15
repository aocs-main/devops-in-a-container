#!/bin/bash
echo "
---------------------------------
Welcome to the Dep-pipeline Docker Compose Setup Script
---------------------------------
Purpose: 
    1. Prepare local directories for docker compose volume mount. 
    2. Run docker-compose.yaml.
"
echo -e "\n[Stopping exisitng dep-pipeline containers]"
docker container stop $(docker container ls -q --filter name=dep-pipeline*)
docker container ls --filter name=dep-pipeline -aq | xargs docker container rm
sleep 2

echo -e "\n[Prepare local directories]"
path_gitlab="./gitlab"
if [ ! -d "$path_gitlab" ]; then
    mkdir "$path_gitlab"
    mkdir "$path_gitlab/config"
    mkdir "$path_gitlab/logs"
    mkdir "$path_gitlab/data"
else
    rm -rf "$path_gitlab/config/*"
    rm -rf "$path_gitlab/logs/*"
    rm -rf "$path_gitlab/data/*"
fi

path_runner="./gitlab-runner"
if [ ! -d "$path_runner" ]; then
    mkdir "$path_runner"
    mkdir "$path_runner/config"
else
    rm -rf "$path_runner/config/*"
fi

path_nexus="./nexus-data"
if [ ! -d "$path_nexus" ]; then
    mkdir "$path_nexus"
else
    rm -rf "$path_nexus/*"
fi
sleep 2

echo -e "\n[Start docker-compose]"
docker-compose up -d

echo "Press any key to exit..."
read -s -n 1
exit 0