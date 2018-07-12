# Knowledge Network Build Pipeline

## Table of Contents
1. [Requirements](#requirements)
2. [Run Pipeline](#run-pipeline)
    1. [Example commands for species/sources](#example-commands-for-speciessources)
    2. [What the output means](#what-the-output-means)
3. [Output files](#output-files)
4. [Cleanup](#cleanup)
5. [Troubleshooting](#troubleshooting)


### Requirements

0a. Need 4cpu, 16GB RAM machine, recommend 2TB disk
0b. No Mesos/Zookeeper/Chronos/Marathon Running
1. make
2. Docker
3. Docker Compose: <https://docs.docker.com/compose/install/#install-compose>

### Run Pipeline

#### Example commands for species/sources

First, check out this repo:

```
git clone https://github.com/KnowEnG/KnowNet_Pipeline_Tools
cd KnowNet_Pipeline_Tools
```

Note: Depending on your setup, some of the following commands may require root.  This is because docker by default does not allow nonroot processes to start jobs.  In addition, the jobs are run as root inside docker, so all the output and intermediate files will be created as root.

Then, running the pipeline is as simple as running `make`.

```
make knownet
```

This will start up our mesos environment, and then run the pipeline for all officially supported species and sources. (TODO: add lists)

##### Parameters

To specify a list of species or sources, you can specify them as `,,`-separated variables, like so:

```
make knownet SPECIES=homo_sapiens,,mus_musculus SOURCES=kegg,,stringdb
```

#### What the output means

The make command will produce a large amount of output.  First it will show the status of starting up mesos and chronos, and then starting up the databases.  After it finishes with that, it will start the processing pipeline, and periodically print the status of the pipeline.  It should return when either an error occurs or the pipeline finishes running.

### Output files

Running the pipeline will create several directories:

|Contents                                   |Directory	|
|--------                                   |--------	|
|Stores the redis database.                 |kn-redis	|
|Stores the downloaded and processed data.  |kn-rawdata	|
|Stores the MySQL database.                 |kn-mysql	|
|Stores the log files.                      |kn-logs	|
|Stores the final processed output files.   |kn-final	|

Information about the output and intermediate file and database formats can be found [here](http://knowredis.knoweng.org/)

### Cleanup

To clean up the files (except `kn-logs` and `kn-final`), as well as chronos, marathon, and mesos, run:

```
make clean
make destroy
```

### Troubleshooting

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
