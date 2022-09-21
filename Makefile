.PHONY: build test clean

VAULT_ADDR ?= http://vault-svc:8200
BUILDKITE_PIPELINE_SLUG=my_pipeline
DUMP_ENV ?= true
VAULT_DEV_ROOT_TOKEN_ID ?= 88F4384B-98E9-4AE3-B00C-F55678F89080

TESTER_VAULT_VERSION ?= 1.11.2
SVC_VAULT_VERSION ?= 1.11.2

all:;: '$(VAULT_ADDR)' \
	'$(TESTER_VAULT_VERSION)' \
	'$(SVC_VAULT_VERSION)' \
	'$(BUILDKITE_PIPELINE_SLUG)' \
	'$(DUMP_ENV)' \
	'$(VAULT_DEV_ROOT_TOKEN_ID)'

all: clean test initegration-test

test:
	-docker-compose \
	  run --rm \
	  	-v ${PWD}:/app \
	  	tests

initegration-test:
	-docker-compose \
		-f docker-compose-integration.yml \
	  run --rm \
			-e VAULT_ADDR=$(VAULT_ADDR) \
			-e BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=$(VAULT_ADDR) \
			-e BUILDKITE_PIPELINE_SLUG=$(BUILDKITE_PIPELINE_SLUG) \
			-e BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=$(DUMP_ENV) \
			-e VAULT_DEV_ROOT_TOKEN_ID=$(VAULT_DEV_ROOT_TOKEN_ID) \
	  	-e BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_TOKEN=$(VAULT_DEV_ROOT_TOKEN_ID) \
			-e SVC_VAULT_VERSION=$(SVC_VAULT_VERSION) \
	  	-e TESTER_VAULT_VERSION=$(TESTER_VAULT_VERSION) \
	  	-v ${PWD}:/app \
	  	vault-tester \
				/app/.buildkite/steps/test_envvar.sh

clean:
	-docker-compose \
		rm --force --stop
	-rm -f reports/* build/* tmp/*
