#!/bin/bash
nexus_host=http://localhost:8081
admin_password="P@ssw0rd1234"
container_name="dep-pipeline-nexus"
docker_repo="docker-hosted"
docker_repo_port=5000
docker_blobstore="docker-blobstore"

setup_docker_repo_hosted() {
    if docker inspect -f '{{.State.Running}}' "$container_name" &> /dev/null; then
        echo "Info: Creating hosted repository for docker image..."
        status_code=$(curl --location $nexus_host'/service/rest/v1/repositories/docker/hosted' \
            --header 'Content-Type: application/json' \
            --header 'Authorization: Basic YWRtaW46YWRtaW4xMjM=' \
            --data '{
                "name": "'$docker_repo'",
                "online": true,
                "storage": {
                    "blobStoreName": "'$docker_blobstore'",
                    "strictContentTypeValidation": true,
                    "writePolicy": "allow",
                    "latestPolicy": true
                },
                "cleanup": {
                    "policyNames": [
                        "string"
                    ]
                },
                "component": {
                    "proprietaryComponents": true
                },
                "docker": {
                    "v1Enabled": true,
                    "forceBasicAuth": false,
                    "httpPort": '$docker_repo_port',
                    "subdomain": "docker-a"
                }
            }' \
            --write-out %{http_code} --silent --output /dev/null)
        if [[ "$status_code" -ne 201 ]] ; then
            echo "Error: unable to create docker repo, please ensure nexus is online with the default admin password."
            exit 1
        else
            sleep 2
        fi
    else
        echo "Error: Container $container_name is not running."
        exit 1
    fi
}

setup_docker_blob_store() {
    if docker inspect -f '{{.State.Running}}' "$container_name" &> /dev/null; then
        echo "Info: Container $container_name is running, creating blob store for docker repo..."
        status_code=$(curl --location $nexus_host'/service/rest/v1/blobstores/file' \
                        --header 'Content-Type: application/json' \
                        --header 'Authorization: Basic YWRtaW46YWRtaW4xMjM=' \
                        --data '{
                        "path": "/nexus-data/blobs/'$docker_blobstore'/",
                        "name": "'$docker_blobstore'"
                        }' \
            --write-out %{http_code} --silent --output /dev/null)
        if [[ "$status_code" -ne 204 ]] ; then
            echo "Error: unable to create docker blob store, please ensure nexus is online with the default admin password."
            exit 1
        else
            sleep 2
        fi
    else
        echo "Error: Container $container_name is not running."
        exit 1
    fi
}

add_realms() {
    echo "Info: Updating realms..."
    status_code=$(curl --location --request PUT $nexus_host'/service/rest/v1/security/realms/active' \
        --header 'Content-Type: application/json' \
        --header 'Authorization: Basic YWRtaW46YWRtaW4xMjM=' \
        --data '[
            "NexusAuthenticatingRealm",
            "DockerToken"
        ]' \
        --write-out %{http_code} --silent --output /dev/null)
    if [[ "$status_code" -ne 204 ]] ; then
        echo "Error: unable to add Docker Bearer Token to realms, please ensure nexus is online with the default admin password."
        exit 1
    else
        sleep 2
    fi
}

enable_anonymous_access() {
    echo "Info: Enable global anonymous access..."
    status_code=$(curl --location --request PUT $nexus_host'/service/rest/v1/security/anonymous' \
        --header 'Content-Type: application/json' \
        --header 'Authorization: Basic YWRtaW46YWRtaW4xMjM=' \
        --data '
        {
            "enabled": true,
            "userId": "anonymous",
            "realmName": "NexusAuthorizingRealm"
        }
        ' \
        --write-out %{http_code} --silent --output /dev/null)
    if [[ "$status_code" -ne 200 ]] ; then
        echo "Error: unable to add Docker Bearer Token to realms, please ensure nexus is online with the default admin password."
        exit 1
    else
        sleep 2
    fi
}

change_admin_password() {
    echo "Info: Changing the default admin password"
    status_code=$(curl --location --request PUT $nexus_host'/service/rest/v1/security/users/admin/change-password' \
        --header 'Content-Type: text/plain' \
        --header 'Authorization: Basic YWRtaW46YWRtaW4xMjM=' \
        --data $admin_password \
        --write-out %{http_code} --silent --output /dev/null)
    if [[ "$status_code" -ne 204 ]] ; then
        echo "Error: changing admin password, please ensure nexus is online with the default admin password."
        exit 1
    else
        sleep 2
    fi
}

# ===================================================================================================================
# Main script
# ===================================================================================================================
echo "
---------------------------------
Welcome to the Nexus Setup Script
---------------------------------
Purpose: 
    1. Setup a docker hosted repo and blobstore in Nexus. 
    2. Config realms and global anonymous access(required for anonymous pull). 
    2. Update default admin credentials.

Note:
    1. Ensure Nexus is in fully deployed.
    2. Ensure Nexus is in the inital state.
    3. This script will not work after changing the default admin password.
"

echo -e "[Optional Script Configs]"
read -p "- Enter Nexus webui url
  Info: api endpoint for the script to function properly.
  Warn: ensure port number matches with docker-compose.yaml.
  ($nexus_host): " i_nexus_host
read -p "
- Enter Nexus container name
  Info: use to check for container status.
  ($container_name): " i_container_name
read -p "
- Enter docker repo name
  Info: custom name for the local docker repo.
  ($docker_repo): " i_docker_repo
read -p "
- Enter docker repo port number
  Info: custom port number for the local docker repo.
  Warn: 1. ensure that the custom port number is defined in docker-compose.yaml.
        2. port 5000, 5001 is predefined.
  ($docker_repo_port): " i_docker_repo_port
read -p "
- Enter docker blob store name 
  Info: 1. custom name for the blob store of the local docker repo.
        2. enter "default" if you do not wish to create a seperate blob store.
  ($docker_blobstore): " i_docker_blobstore
read -p "
- Enter Nexus admin password  
  Info: use to replace the default admin account password.
  ($admin_password): " i_admin_password

if [[ ! -z "$i_nexus_host" ]]; then
    nexus_host=$i_nexus_host
fi
if [[ ! -z "$i_container_name" ]]; then
    container_name=$i_container_name
fi
if [[ ! -z "$i_docker_repo" ]]; then
    docker_repo=$i_docker_repo
fi
if [[ ! -z "$i_docker_repo_port" ]]; then
    docker_repo_port=$i_docker_repo_port
fi
if [[ ! -z "$i_docker_blobstore" ]]; then
    docker_blobstore=$i_docker_blobstore
fi
if [[ ! -z "$i_admin_password" ]]; then
    admin_password=$i_admin_password
fi
sleep 2

case $docker_blobstore in
    "default")
        ;;
    *)
        echo -e "\n[Setting up Blob Store]"
        setup_docker_blob_store
        ;;
esac

echo -e "\n[Setting up Repositories]"
setup_docker_repo_hosted

echo -e "\n[Updating security configs]"
add_realms
enable_anonymous_access
change_admin_password

echo "
---------------------------------
Setup Completed
---------------------------------
1. Nexus is accessible at $nexus_host
    account : admin
    password: $admin_password

2. Docker repo can be accessed through:
    $ docker pull localhost:5000/<image-name>:<version>
    $ docker push localhost:5000/<image-name>:<version>

    Note: add login credential to docker before pushing images to Nexus repo.
    $ docker login localhost:5000 -u admin

3. If you wish to pull images from Docker Hub through Nexus:
    - setup a docker-proxy repo through$nexus_host'/
    - ensure port is defined in docker-compose.yaml.
"
echo "Press any key to exit..."
read -s -n 1
exit 0