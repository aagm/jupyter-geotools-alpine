# Geodata Science Notebooks for Reproducible Science

Use this as a template for your data science computing notebooks. You need docker and docker-compose.

Just type `sh jupyter.sh develop` and you will be able to connect to `0.0.0.0:8888`.

run this if you wanna access the docker

``` bash
docker  exec -i -t 07fdb1ffde2c /bin/bash
```

To be able to connect to ee run in the internal console `earthengine authenticate` and follow the instructions

## For development

To remove unwanted images:  

``` bash
docker rmi -f $(docker images -q)
```

To clear space let's remove volumes:  

``` bash
docker rm -v $(docker ps -a -q -f status=exited)
docker volume ls -qf dangling=true
docker volume rm $(docker volume ls -qf dangling=true)
```

To remove unwanted containers:  

``` bash
docker rm $(docker ps -a -q)
```
