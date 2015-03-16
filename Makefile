unit:
	./node_modules/mocha/bin/_mocha --compilers coffee:coffee-script/register ./test/unit

cov-report:
	./node_modules/mocha/bin/_mocha --compilers coffee:coffee-script/register --require ./node_modules/blanket-node/bin/index.js -R html-cov > coverage.html ./test/unit ./test/integration
	open coverage.html

cov:
	./node_modules/mocha/bin/_mocha --compilers coffee:coffee-script/register --require ./node_modules/blanket-node/bin/index.js -R travis-cov ./test/unit ./test/integration


integration:
	./node_modules/mocha/bin/_mocha --compilers coffee:coffee-script/register ./test/integration

lint:
	./node_modules/coffeelint/bin/coffeelint ./lib ./test

check-dependencies:
	./node_modules/david/bin/david.js

test:
	$(MAKE) unit
	$(MAKE) integration
	$(MAKE) cov
	$(MAKE) lint
	$(MAKE) check-dependencies

kill-node:
	kill `ps -eo pid,comm | awk '$$2 == "node" { print $$1 }'`


.PHONY: all test clean unit integration
