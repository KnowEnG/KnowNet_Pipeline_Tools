DOCKER_IP ?= 127.0.0.1
export DOCKER_IP

SPECIES ?= 'homo_sapiens'
SOURCES ?= ''
PWD ?= $(shell pwd)

.PHONY: knownet
knownet: start
	docker run -it --rm --name=kn_build --net=host \
	  -v ${PWD}/../:${PWD}/../ knoweng/kn_builder \
	    sh -c "cd ${PWD}/ && \
	    wget --tries 100 --retry-connrefused -O/dev/null \
	      http://localhost:8080/ui/ http://localhost:8888/ http://localhost:5050/ && \
	    python3 /kn_builder/code/build_status.py -es ${SPECIES} -srcs ${SOURCES}"

.PHONY: clean
clean: clean_chronos clean_marathon clean_intermediate

.PHONY: clean_chronos
clean_chronos:
	#TODO: Use a better temporary file? 
	curl -L -X GET 127.0.0.1:8888/scheduler/jobs | sed 's#,#\n#g' | sed 's#\[##g' \
	  | grep '"name"' | sed 's#{"name":"##g' | sed 's#"##g' > /tmp/t.txt
	for JOB in `cat /tmp/t.txt`; do \
	  CMD="curl -L -X DELETE 127.0.0.1:8888/scheduler/job/$$JOB";\
	  echo "$$CMD"; \
	  eval "$$CMD"; \
	done;

.PHONY: clean_marathon
clean_marathon:
	curl -X DELETE 127.0.0.1:8080/v2/apps/kn-mysql
	curl -X DELETE 127.0.0.1:8080/v2/apps/kn-redis

.PHONY: clean_intermediate
clean_intermediate:
	rm -rf kn-mysql/* kn-redis/* kn-rawdata/*

.PHONY: clean_logs
clean_logs:
	rm -rf kn_logs/*

.PHONY: clean_export
clean_export:
	rm -rf kn_final/*

.PHONY: export_mysql
export_mysql:
	mysqldump -h localhost -u root -pKnowEnG KnowNet | gzip > kn-final/mysql.gz

.PHONY: export_redis
export_redis:
	redis-cli -h localhost -a KnowEnG SAVE && gzip -c kn-redis/dump.rdb > kn-final/redis.gz

.PHONY: run
run:
	docker-compose up

.PHONY: start
start:
	docker-compose up -d

.PHONY: stop
stop:
	docker-compose stop

.PHONY: destroy
destroy: stop
	docker-compose rm -fv
