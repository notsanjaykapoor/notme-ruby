.PHONY: dev install test

dev:
	./bin/api-server --port 5001

install: Gemfile
	bundle install

test:
	./bin/test