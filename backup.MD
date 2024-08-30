Backup Gitlab in docker
Locate backup path
gitlab_rails[‘backup_path’] is commented in the Gitlab configuration file gitlab.rb, its value is the default backup path which is at /var/opt/gitlab/backups.
```
# From Gitlab docker
root@gitlab:/etc/gitlab# cat /etc/gitlab/gitlab.rb | grep backup_path
# gitlab_rails['manage_backup_path'] = true
# gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
```

Create the backup
You don’t need to stop anything before creating the backup.
```
docker exec -it gitlab gitlab-rake gitlab:backup:create
```

Backup configuration and secret files
Yes, the configuration and secret files are not backed up during the previous backup procedure. This is because the previous one encrypts some Gitlab data by using the secret key in the configuration and secret files. If you save them to the same place, you’re just defeating the encryption.

So please also backup /etc/gitlab/gitlab.rb and /etc/gitlab/gitlab-secrets.json and save them to a secure place from other Gitlab backup data.

Stop some Gitlab services
```
# From Gitlab docker
gitlab-ctl reconfigure
gitlab-ctl start
gitlab-ctl stop unicorn
gitlab-ctl stop sidekiq
gitlab-ctl status
ls -lart /var/opt/gitlab/backups
```

Copy the backup files to the [‘backup_path’] in the docker container
```
# From host outside of the Gitlab docker
$ docker cp path/to/backupfile dep-pipeline-gitlab:/var/opt/gitlab/backups/
```

Start the restore
The backup file must can be found in the backup path, which is defined in the configuration file /etc/gitlab/gitlab.rb by the key gitlab_rails[‘backup_path’].
```
# From host outside of the Gitlab docker
$ docker exec -it dep-pipeline-gitlab gitlab-rake gitlab:backup:restore BACKUP=<backupfile> --trace
```

Restart the Gitlab services by gitlab-ctl restart:
```
$ gitlab-ctl restart
```

Launch the Gitlab sanity check by gitlab-rake gitlab: check SANITIZE=true:
```
$ gitlab-rake gitlab:check SANITIZE=true
```
