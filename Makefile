.PHONY: dev install test

console:
	./bin/console

dev:
	./bin/api-server --port 5001

guard:
	# used in dev environment
	./scripts/guard

install: Gemfile
	bundle install

test:
	./bin/test