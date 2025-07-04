-include .env # Applies to every target in the file!
-include ../aaf-terraform/Makefile

BUILD_TARGET=development
VERSION := $(shell cat .ruby-version)
ADDITIONAL_BUILD_ARGS=--build-arg BASE_IMAGE=${DOCKER_ECR}ruby-base:${VERSION}
APP_NAME=reporting-service

COMMON_ARGS=\
--env-file=.env \
-p 8080:8080 \
-v ${PWD}/app:/app/app \
-v ${PWD}/config:/app/config \
-v ${PWD}/lib:/app/lib \
-v ${PWD}/tmp:/app/tmp \
-v ${PWD}/tmp:/tmp \
-v ${PWD}/lib:/app/lib \
-v ${PWD}/log:/app/log \
-v ${PWD}/db:/app/db \
-v ${PWD}/Gemfile.lock:/app/Gemfile.lock \
-e REPORTING_DB_HOST=${LOCAL_IP} \
-e REDIS_HOST=${LOCAL_IP}

RUN_ARGS=

run-image:
	make run-generic-image-command ADDITIONAL_ARGS="${RUN_ARGS}"
TARGET=

TESTS_ARGS=\
-p 12347:12347 \
-e RUBY_DEBUG_OPEN=true \
-e RUBY_DEBUG_HOST=0.0.0.0 \
-e RUBY_DEBUG_PORT=12347 \
-v ${PWD}/coverage:/app/coverage \
-v ${PWD}/spec:/app/spec \
-v ${PWD}/tmp:/app/tmp \
-e RAILS_ENV=test \
-e REPORTING_DB_HOST=${LOCAL_IP} \
-e REDIS_HOST=${LOCAL_IP} \
-e REPORTING_DB_USERNAME=root \
-e REPORTING_DB_PASSWORD='' \
-e COVERAGE=true \
-e CI=true

run-image-tests:
	@make run-generic-image-command \
		APP_NAME_POSTFIX="-tests" \
		ADDITIONAL_ARGS="${TESTS_ARGS}" \
		COMMAND="bundle exec rspec -fd ${TARGET}"


test: docker-login
	REPORTING_IMAGE=${DOCKER_ECR}${APP_NAME}:development docker compose -f compose.yml run reporting rspec

lint:
	@bundle exec rake lint


PROMETHEUS_EXPORTER_ARGS=\
--read-only \
-p 9394:9394 \
-e PROMETHEUS_TYPE=exporter \
--entrypoint  /app/bin/metrics.sh

run-promtheus-exporter:
	@make run-generic-image-command \
		APP_NAME_POSTFIX="-prometheus" \
		ADDITIONAL_ARGS="${PROMETHEUS_EXPORTER_ARGS}"
