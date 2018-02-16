# Knowledge Network Build Notes

#### First Test

- on knowdev4.knoweng.org
- m4.large, 2cpus, 8GB ram, EBS-only storage, 450Mbps
- login with:

```
ssh -i /workspace/home/ubuntu/knowdev4.pem ubuntu@knowdev4.knoweng.org
sudo -s
cd /home/ubuntu/p1_knbuild/
```

#### Requirements

0a. need 2cpu, 8GB RAM machine, recommend 2TB disk
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


#### For Monitoring

1. Download dockprom <https://github.com/stefanprodan/dockprom>:

```
git clone https://github.com/stefanprodan/dockprom
cd dockprom
```

2. Start dockprom:

```
ADMIN_USER=admin ADMIN_PASSWORD=knoweng docker-compose up -d
```

3. Navigate to:

```
http://knowdev4.knoweng.org:3000/login
# "Docker Containers" dashboard
```

#### Setup Pipeline

1. Make clean directory:

```
TAG="_"`date +'%y%m%d'`
mkdir p1_build$TAG
cd p1_build$TAG
```

2. Clone the KnowEnG git repo:

```
git clone https://github.com/KnowEnG/KnowNet_Pipeline.git
cd KnowNet_Pipeline
git checkout build_testing
```

#### Run Pipeline

1. Turn on Mesos frameworks, databases, fetch maps, fetch and import data, export as networks:

```
make destroy && \
make start && \
docker run -it --rm --name=p1build --net=host \
  -v ${PWD}/../:${PWD}/../ cblatti3/py3_skl_redis_mysql_s3_yml:0.1 \
    sh -c "cd ${PWD}/ && \
    wget --tries 100 --retry-connrefused -O/dev/null \
      http://localhost:8080/ui/ http://localhost:8888/ http://localhost:5050/ && \
    python3 code/job_status.py -s pfam_prot kegg pathcom enrichr blast -p drosophila_melanogaster homo_sapiens "
```

#### Notes about docker state before running job_status

1. Number of directories

```
ls -d /var/lib/docker/*/*/*/ | wc -l
#349
```

2. Size of directories

```
du -sh /var/lib/docker/
#14G     /var/lib/docker/
```

#### Useful Commands

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

- check marathon tasks

```
curl -X GET 127.0.0.1:8080/v2/apps/mysql-3306-2test-1801/tasks
curl -X GET 127.0.0.1:8080/v2/apps/redis-6380-2test-1801/tasks
```

- manually start marathon jobs

```
curl -X POST -H "Content-type: application/json" 127.0.0.1:8080/v2/apps/ \
  -d@/home/ubuntu/p1_knbuild/p1_build_180110/logs-2test-1801/marathon_jobs/p1mysql-3306.json
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

- Find container name by mesos id

```
docker ps -a --no-trunc --format "{{.Names}}: {{.Command}}" | grep -oP "mesos-\S*|[^/]*\.log /" | grep -A XXXXX
```

- Find mesos ids per stage

```
for i in mysqld redis-server check_utilities fetch_utilities table_utilities conv_utilities import_utilities export_utilities KN_starter next_step; do
  echo $i
  docker ps -a --no-trunc | grep $i | rev | cut -d' ' -f 1 | rev | awk -v LABEL="$i" '{print $1"\t"LABEL}'
done;
```


#### Reset to job_status.py

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
curl -X DELETE 127.0.0.1:8080/v2/apps/mysql-3306-2test-1801
curl -X DELETE 127.0.0.1:8080/v2/apps/redis-6380-2test-1801
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
rm -r ../*2test-1801/
```


#### Fixes and change requests from first runs

- need to change mysql/redis port because already have redis running
- need to change db memory mins because over total (docker-compose up instead)
  - old mins -mym 10000 -myc 0.5 -rm 8000 -rc 0.5
- MySQL recommends for a database specific server setting innodb_buffer_pool_size at a max of around 80% of physical memory
- need to change redis port usage because not used (done)
- custom select species / edge types / run all
- custom? tag name for datapath, logpath, dbpaths
- need to change container mem mins becuase over total
- print currently running/pending/completed chronos job every 30 seconds (scheduler/graph/csv)
- if a container cannot be scheduled, then the build hangs, check is none running at two consecutive intervals?
- container/file cleanup and shutdown
- necessary containers `cblatti3/py3_skl_redis_mysql_s3_yml` (fig out numpy) `cblatti3/py3_redis_mysql`  (add source code)
- check failing / html error for stringdb, reactome, blast, enrichr
- when a chronos job fails, job_status dies, but other containers keep running on chronos
- next full run on knowcluster with grafana to get best mem estimates for each type of step
- create a release branch with unneccessary content removed /
  - still usable for our knowcluster purposes?

enrichr-check
Comparing versions for Disease_Signatures_from_GEO_up_2014

import-raw_line
mysql.connector.errors.OperationalError: 2055: Lost connection to MySQL server at '127.0.0.1:3306', system error: 104 Connection reset by peer


#### Notes on release products

- github public release branch for makefile
  - readme
    - git clone
    - start pipeline
      - requirements
      - options
      - commands
  - license info
  - makefile code

- github public release branch for container with tags
  - container code
  - source code
  - documentation source
  - license info
  - github readme
  - pylinted

git_readme
git_license
docs/
tests/
docker/
    Dockerfile
    docker_readme
    src/
    samples/


- one autobuilding image on docker hub with readme for how to
    - documentation
    - contact

- readme documentation
  - start pipeline
    - requirements
    - options
    - commands
  - use its outputs
    - userKN
    - dbdumps
  - monitor its progress
    - faqs
      - <https://docs.google.com/document/d/1bxJpuES2SdylZyNYgIeySD85Brm_2UvLjbtcO-UXsm8/edit>

- public documentation
  - compiled and nginx running on knowredis?
  - output format definitions
  - options walkthrough
  - glossary of functions





