docker container stop $(docker container ls -q --filter name=dep-pipeline*)
docker container ls --filter name=dep-pipeline -aq | xargs docker container rm

rm -rf ./gitlab/config/*
rm -rf ./gitlab/logs/*
rm -rf ./gitlab/data/*

rm -rf ./gitlab-runner/config/*
rm -rf ./nexus-data/*

docker-compose up

# docker container exec dep-pipeline-nexus cat nexus-data/admin.password