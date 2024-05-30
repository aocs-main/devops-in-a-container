#!/bin/bash

file_config_toml="config.toml"
file_runner_config_template="runner.template"
path_runner_config_toml="./gitlab-runner/config"
container_name="dep-pipeline-gitlab"

initialise_config_toml() {
    initial_content="concurrent = 1\ncheck_interval = 0\nshutdown_timeout = 0\n\n[session_server]\n\tsession_timeout = 1800\n"
    # Check if the file exists, create it if not
    if [ ! -e "$path_runner_config_toml/$file_config_toml" ]; then
        echo -e $initial_content > "$path_runner_config_toml/$file_config_toml"
        echo "Info: Runner config file '$file_config_toml' created with initial content in $path_runner_config_toml"
        sleep 2
    else
        echo "Info: Found $file_config_toml in $path_runner_config_toml"
    fi
}

retrieve_runner_token() {
    if docker inspect -f '{{.State.Running}}' "$container_name" &> /dev/null; then
        echo "Info: Container $container_name is running, creating new instance runner..."
        new_runner_token=$(docker exec -it $container_name gitlab-rails runner "new_runner = Ci::Runner.create(runner_type:'instance_type', run_untagged:'true', registration_type:1, description:'Shared runner'); puts new_runner.token")
        new_runner_token="${new_runner_token%"${new_runner_token##*[![:space:]]}"}"
        echo "Info: Got token $new_runner_token from gitlab." 
        sleep 2
    else
        echo "Error: Container $container_name is not running."
        exit 1
    fi
}

register_runner_to_config_toml() {
    if [ -e $file_runner_config_template ]; then
        sed -e "s;%TOKEN%;$new_runner_token;g" $file_runner_config_template >> "$path_runner_config_toml/$file_config_toml"
        echo "Info: Runner registed in $path_runner_config_toml"
        sleep 2
    else 
        echo "Error: $file_runner_config_template file not found"
    fi
}

# ===================================================================================================================
# Main script
# ===================================================================================================================
echo "
---------------------------------
Welcome to the Gitlab Runner Setup Script
---------------------------------
Purpose: 
    1. Create a shared runner in gitlab for CI/CD jobs. 

Note:
    1. Ensure Gitlab is in fully deployed.
    2. Ensure a valid runner template file is available.
"
echo -e "[Optional Script Configs]"
read -p "- Enter Gitlab container name 
  Info: use to check for container status.
  ($container_name): " i_container_name
read -p "
- Enter gitlab-runner config path 
  Info: custom output path for the generated config.toml.
  Warn: ensure the path matches the volume mapping in docker-compose.yaml
  ($path_runner_config_toml): " i_path_runner_config_toml
read -p "
- Enter runner template file 
  Info: name of the custom runner config template.
  ($file_runner_config_template): " i_file_runner_config_template

if [[ ! -z "$i_container_name" ]]; then
    container_name=$i_container_name
fi
if [[ ! -z "$i_path_runner_config_toml" ]]; then
    path_runner_config_toml=$i_path_runner_config_toml
fi
if [[ ! -z "$i_file_runner_config_template" ]]; then
    file_runner_config_template=$i_file_runner_config_template
fi
sleep 2

echo -e "\n[Create config.toml]"
initialise_config_toml

echo -e "\n[Requesting Runner Token]"
retrieve_runner_token

echo -e "\n[Registering Runner]"
register_runner_to_config_toml

echo "
---------------------------------
Setup Completed
---------------------------------
1. Shared runner is ready, refer to http://<gitlab.domain>/admin/runners for more options.

2. Gitlab is accessible at http://localhost/
     account : root
     password: P@ssw0rd1234
     
3. To access gitlab by hostname:
     add a loopback entry to host file in your local machine.
"
echo "Press any key to exit..."
read -s -n 1
exit 0