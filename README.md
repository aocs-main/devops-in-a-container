# Setup Repository
1. Create docker-hosted and docker-proxy Blob on Nexus

```
Gear > Repository > Blob Stores > Create blob store
You need to create docker-hosted and docker-hub
```

2. Create docker-hosted and docker-proxy Repository on Nexus
```
Gear > Repository > Repositories > Create repository
You need to create docker-hosted and docker-hub(https://registry-1.docker.io).
```

3. Set Realms on Nexus
```
Gear > Realms > Move Docker Bearer Token Realm to active
```

4. Configure docker repository 
```
Create file /etc/docker/daemon.json and add
{
        "insecure-registries" : ["127.0.0.1:5000"]
}
```

5. Restart Docker Engine

Reference: https://qiita.com/leechungkyu/items/86cad0396cf95b3b6973

