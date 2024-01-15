# GitLab 
This document contains some additional information for using self-managed GitLab instances.  
> All `gitlab_rails` arguments in this document can be configured both through `docker-compose.yaml` > `GITLAB_OMNIBUS_CONFIG` and `docker exec`.

## Docker Compose Configurations
```
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: dep-pipeline-gitlab
    restart: always
    hostname: 'gitlab.local.com'
    ports:
      - "80:80"
      - "443:443"
      - "22:22"
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        gitlab_rails['lfs_enabled'] = true
        gitlab_rails['initial_root_password'] = 'P@ssw0rd1234'
        # Add any other gitlab.rb configuration here, each on its own line
    networks:
      - dep-pipeline-network
```
1. For `hostname` to function, please add a loopback entry to the host file in your host system.
2. You may mount external directories to persist the data:
    ```
        volumes:
            - ./gitlab/config:/etc/gitlab
            - ./gitlab/logs:/var/log/gitlab
            - ./gitlab/data:/var/opt/gitlab
    ```
    >Note: see [here](#job-artifacts) for potential issues with uploading job artifacts when mounting Windows directories.
3. You may modify the `GITLAB_OMNIBUS_CONFIG` accordingly. Details available [here](https://docs.gitlab.com/ee/administration/environment_variables.html).

## Using Code Quality and SAST from GitLab
GitLab CE comes with Code Quality and SAST for CI/CD integration. Once triggered, the shared runner will spawn another runner instance with a custom GitLab image from the official GitLab registry. The image contains the appropriate scanners for your project and will perform `local` scanning on the code repository. A report will be generated and can be downloaded from Gitlab.
Reference: [GitLab Docs](https://docs.gitlab.com/ee/topics/autodevops/)  

To enable Code Quality and SAST in your project:  
1. Add the following configs to your project `.gitlab-ci.yml`:
    ```yaml
    stages:
        - test
    include:
        - template: Jobs/Code-Quality.gitlab-ci.yml
        - template: Jobs/SAST.gitlab-ci.yml
    ```
1. Push the code to GitLab instance and wait for the pipeline to be completed.
1. Go to `Build` > `Artifacts` and look for the corresponding jobs to download the scanner report.  

## Job Artifacts
The artifacts are stored by default in `/var/opt/gitlab/gitlab-rails/shared/artifacts`.
Reference: [GitLab Docs](https://docs.gitlab.com/ee/administration/job_artifacts.html?tab=Docker)  

1. Change using:
    ```
    gitlab_rails['artifacts_path'] = "/mnt/storage/artifacts"
    ```

> Issue: Problem with uploading artifact in CI/CD when GitLab is mounting `/data` to a Windows directory. More info [here](https://stackoverflow.com/questions/65324410/job-ends-with-error-warning-uploading-artifacts-as-archive-to-coordinator).