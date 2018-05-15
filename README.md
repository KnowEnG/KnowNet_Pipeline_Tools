# Knowledge Network Build Pipeline

## Table of Contents
1. Requirements
2. Run Pipeline
2.a. Example commands for species/sources
2.b. What the output means
3. Output files
4. Cleanup
5. Troubleshooting


### Requirements

0.a. Need 4cpu, 16GB RAM machine, recommend 2TB disk
0.b. No Mesos/Zookeeper/Chronos/Marathon Running
1. make
2. Docker:
3. Docker Compose <https://docs.docker.com/compose/install/#install-compose>:

### Run Pipeline

#### Example commands for species/sources

First, check out this repo:

```
git clone https://github.com/KnowEnG/KnowNet_Pipeline_Tools
cd KnowNet_Pipeline_Tools
```

Then, running the pipeline is as simple as running `make`.

```
make knownet
```

This will start up our mesos environment, and then run the pipeline for all officially supported species and sources. (TODO: add lists)

To specify a list of species or sources, you can specify them as `,,`-separated variables, like so:

```
make knownet SPECIES=homo_sapiens,,mus_musculus SOURCES=kegg,,stringdb
```

#### What the output means

The make command will produce a large amount of output.  First it will show the status of starting up mesos and chronos, and then starting up the databases.  After it finishes with that, it will start the processing pipeline, and periodically print the status of the pipeline.

### Output files

Running the pipeline will create several directories:

|Directory	|Contents|
|--------	|--------|
|kn-redis	|Stores the redis database.|
|kn-rawdata	|Stores the downloaded and processed data.|
|kn-mysql	|Stores the MySQL database.|
|kn-logs	|Stores the log files.|
|kn-final	|Stores the final processed output files.|

Information about the output and intermediate file and database formats can be found [here]()

### Cleanup

To clean up the files (except `kn-final`), as well as chronos, marathon, and mesos, run:

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
