PWD = $(shell pwd)
COMPOSER_IMG = composer:1.9.0

all: install run

update:
	docker run --rm -v "$(PWD):/app" $(COMPOSER_IMG) composer update
	docker run --rm -v "$(PWD):/app" $(COMPOSER_IMG) composer install

install:
	docker run --rm -v "$(PWD):/app" $(COMPOSER_IMG) composer install

run:
	docker-compose up

build:
	docker build -t bookshelf:dev .

test: install
	docker run --rm -v "$(PWD):/app" $(COMPOSER_IMG) vendor/bin/phpunit test

clean:
	docker-compose down
	docker run --rm -v "$(PWD):/app" $(COMPOSER_IMG) rm -rf vendor
