# About runner.template
A template file used by `setup-runner.sh` to register a shared runner to Gitlab. 

Refer to [Gitlab Docs](https://docs.gitlab.com/runner/configuration/advanced-configuration.html) for more details and available options. 

```
[[runners]]
name = "Shared Runner"
url = "http://gitlab/"
token = "%TOKEN%" # Required 
executor = "docker"
[runners.cache]
    MaxUploadedArchiveSize = 0
[runners.docker]
    tls_verify = false
    image = "localhost:5000/my-alpine-curl-image"
    privileged = true # Required 
    disable_cache = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    volumes = ["/cache"]
    shm_size = 0
    network_mtu = 0
    network_mode = "dep-pipeline_dep-pipeline-network"

```
1. `setup-runner.sh` requires the token field to be `%TOKEN%` for it to work properly.  
2. Privileged is required to be true to support docker in docker mode.   
3. Otherwise you may adjust the template accordingly.