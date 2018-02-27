# Knowledge Network Build Notes

### Requirements

0a. need 4cpu, 16GB RAM machine, recommend 2TB disk
0b. No Mesos/Zookeeper/Chronos/Marathon Running
1. make
2. Docker:
3. Docker Compose <https://docs.docker.com/compose/install/#install-compose>:

```
curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version
```



### Setup Pipeline

1. Make clean directory:

```
TAG="_"`date +'%y%m%d'`
mkdir kn_build$TAG
cd kn_build$TAG
```

2. Clone the KnowEnG git repo:

```
git clone https://github.com/cblatti3/KnowEnG_KnowNet.git
cd KnowEnG_KnowNet
```

### Run Pipeline

1. Turn on Mesos frameworks, databases, fetch maps, fetch and import data, export as networks:

```
make destroy && \
make start && \
docker run -it --rm --name=kn_build --net=host \
  -v ${PWD}/../:${PWD}/../ knoweng/kn_builder \
    sh -c "cd ${PWD}/ && \
    wget --tries 100 --retry-connrefused -O/dev/null \
      http://localhost:8080/ui/ http://localhost:8888/ http://localhost:5050/ && \
    python3 /kn_builder/code/job_status.py -s pfam_prot kegg pathcom enrichr blast -p drosophila_melanogaster homo_sapiens "
```


### Useful Commands

- get mesos tasks

```
curl -L -X GET 127.0.0.1:5050/tasks
curl -L -X GET 127.0.0.1:5050/system/stats.json
curl -L -X GET 127.0.0.1:5050/metrics/snapshot
curl -L -X GET 127.0.0.1:5050/master/slaves
```

- get marathon job status

```
curl -X GET 127.0.0.1:8080/v2/apps/
```

- get chronos jobs

```
curl -L -X GET 127.0.0.1:8888/scheduler/jobs
```

- get chronos job statuses

```
for i in {1..10}; do
  echo $i
  curl -L -s -X GET 127.0.0.1:8888/scheduler/graph/csv | grep node, | \
    awk -F, '{print $3"\t"$4"\t"$1"\t"$2}' | sort | uniq | grep -v success
  sleep 30
done
```

- remove stopped containers

```
docker ps -aq --no-trunc | xargs docker rm
```

- get docker usage stats

```
eval "docker inspect --format='{{.Name}}' \$(docker ps -aq --no-trunc) | \
  cut -c 2- | xargs docker stats --no-stream=true"
```

- Find mesos ids per stage

```
for i in mysqld redis-server check_utilities fetch_utilities table_utilities conv_utilities import_utilities export_utilities KN_starter next_step; do
  echo $i
  docker ps -a --no-trunc | grep $i | rev | cut -d' ' -f 1 | rev | awk -v LABEL="$i" '{print $1"\t"LABEL}'
done;
```


### Reset to job_status.py

1. Clean chronos:

```
curl -L -X GET 127.0.0.1:8888/scheduler/jobs | sed 's#,#\n#g' | sed 's#\[##g' \
  | grep '"name"' | sed 's#{"name":"##g' | sed 's#"##g' > /tmp/t.txt
for JOB in `cat /tmp/t.txt`; do
  CMD="curl -L -X DELETE 127.0.0.1:8888/scheduler/job/$JOB";
  echo "$CMD";
  eval "$CMD";
done;
```

2. Clean marathon:

```
curl -X DELETE 127.0.0.1:8080/v2/apps/mysql-[port]-[tag]
curl -X DELETE 127.0.0.1:8080/v2/apps/redis-[port]-[tag]
```

3. Turn off mesos and frameworks

```
make destroy
```

4. Clean docker

```
docker ps -aq --no-trunc | xargs docker rm
```

5. Clean file system

```
rm -r ../*[tag]/
```


