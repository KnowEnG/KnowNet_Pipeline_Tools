DOCKER_IP ?= 127.0.0.1
export DOCKER_IP

knownet: start
	docker run -it --rm --name=kn_build --net=host \
	  -v ${PWD}/../:${PWD}/../ knoweng/kn_builder \
	    sh -c "cd ${PWD}/ && \
	    wget --tries 100 --retry-connrefused -O/dev/null \
	      http://localhost:8080/ui/ http://localhost:8888/ http://localhost:5050/ && \
	    python3 /kn_builder/code/build_status.py -es homo_sapiens "

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
