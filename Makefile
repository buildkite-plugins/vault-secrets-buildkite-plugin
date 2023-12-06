.PHONY: build test clean

include integration-env

test:
	-docker-compose \
	  run --rm \
	  	-v ${PWD}:/app \
	  	tests

integration-test:
	-docker compose \
		--env-file integration-env \
		-f docker-compose-integration.yml \
	  run --rm \
	  	-v ${PWD}:/app \
	  	vault-tester \
				bash /app/.buildkite/steps/test_integration.sh

clean:
	-docker-compose \
		rm --force --stop
	-rm -f reports/* build/* tmp/*
