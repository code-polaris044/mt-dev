MAKEFILE_DIR=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))

export BASE_SITE_PATH=${MAKEFILE_DIR}/site
export DOCKER=docker
export DOCKER_COMPOSE=docker-compose
export DOCKER_COMPOSE_YML_MIDDLEWARES=-f ./mt/mysql.yml -f ./mt/memcached.yml
export UP_ARGS=-d
export MT_HOME_PATH=${MAKEFILE_DIR}/../movabletype
export MT_CONFIG_CGI=${MAKEFILE_DIR}/${shell [ -e mt-config.cgi ] && echo mt-config.cgi || echo mt-config.cgi-original}

WITHOUT_MT_CONFIG_CGI=
ifneq (${WITHOUT_MT_CONFIG_CGI},)
export MT_CONFIG_CGI_DEST_PATH=/tmp/mt-config.cgi
endif

export DOCKER_MT_IMAGE
export DOCKER_MYSQL_IMAGE
export DOCKER_MEMCACHED_IMAGE
export MT_RUN_VIA

_DC=${DOCKER_COMPOSE} -f ./mt/common.yml ${DOCKER_COMPOSE_YML_MIDDLEWARES}
BASE_ARCHIVE_PATH=${MAKEFILE_DIR}/archive

.PHONY: db up down

up: up-cgi

init-repo:
	@[ -e ${MT_HOME_PATH} ] || \
		git clone git@github.com:movabletype/movabletype ${MT_HOME_PATH};

fixup:
	@for f in mt-config.cgi mt-tb.cgi mt-comment.cgi; do \
		fp=${MT_HOME_PATH}/$$f; \
		[ -d $$fp ] && rmdir $$fp || true; \
		[ -f $$fp ] && perl -e 'exit((stat(shift))[7] == 0 ? 0 : 1)' $$fp && rm -f $$fp || true; \
	done

setup-mysql-volume:
	$(eval export DOCKER_MYSQL_VOLUME=$(shell echo ${DOCKER_MYSQL_IMAGE} | sed -e 's/\..*//; s/[^a-zA-Z0-9]//g'))


ifneq (${SQL},)
MYSQL_COMMAND_ARGS=-e '${SQL}'
endif

exec-mysql:
	${_DC} exec db mysql -uroot -ppassword -h127.0.0.1 ${MYSQL_COMMAND_ARGS}


up-cgi: MT_RUN_VIA=cgi
up-cgi: up-common

up-psgi: MT_RUN_VIA=psgi
up-psgi: up-common

up-common: down
ifeq (${RECIPE},)
	${MAKE} up-common-without-recipe
else
	${MAKE} up-common-with-recipe
endif

up-common-without-recipe:
ifneq (${ARCHIVE},)
	${MAKE} down-mt-home-volume
	# TODO random name
	$(eval MT_HOME_PATH=mt-dev-mt-home-tmp)
	${DOCKER} volume create --label mt-dev-mt-home-tmp ${MT_HOME_PATH}
	${MAKEFILE_DIR}/bin/extract-archive ${BASE_ARCHIVE_PATH} ${MT_HOME_PATH} $(shell echo ${ARCHIVE} | tr ',' '\n')
endif
	${MAKE} up-common-invoke-docker-compose MT_HOME_PATH=${MT_HOME_PATH}

up-common-with-recipe:
	$(eval export _ARGS=$(shell ${MAKEFILE_DIR}/bin/setup-environment ${RECIPE}))
	@perl -e 'exit(length($$ENV{_ARGS}) > 0 ? 0 : 1)'
	${MAKE} up-common-invoke-docker-compose ${_ARGS} RECIPE="" $(shell [ -n "${DOCKER_MT_IMAGE}" ] && echo "DOCKER_MT_IMAGE=${DOCKER_MT_IMAGE}") $(shell [ -n "${DOCKER_MYSQL_IMAGE}" ] && echo "DOCKER_MYSQL_IMAGE=${DOCKER_MYSQL_IMAGE}")

up-common-invoke-docker-compose: init-repo fixup setup-mysql-volume
	@echo MT_HOME_PATH=${MT_HOME_PATH}
	@echo BASE_SITE_PATH=${BASE_SITE_PATH}
	@echo DOCKER_MT_IMAGE=${DOCKER_MT_IMAGE}
	@echo DOCKER_MYSQL_IMAGE=${DOCKER_MYSQL_IMAGE}
	@echo DOCKER_MYSQL_VOLUME=${DOCKER_MYSQL_VOLUME}
	${_DC} -f ./mt/${MT_RUN_VIA}.yml ${DOCKER_COMPOSE_YML_OVERRIDE} up ${UP_ARGS}


ifneq (${REMOVE_VOLUME},)
DOWN_ARGS=-v
endif

down:
	${_DC} down ${DOWN_ARGS}
	${MAKE} down-mt-home-volume

down-mt-home-volume:
	@for v in `docker volume ls -f label=mt-dev-mt-home-tmp | sed -e '1d' | awk '{print $$2}'`; do \
		docker volume rm $$v; \
	done


docker-compose:
	${_DC} ${ARGS}


build:
	${MAKE} -C docker