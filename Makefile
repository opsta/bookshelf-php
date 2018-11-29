PWD = $(shell pwd)

all: install run

update:
	docker run --rm -v "$(PWD):/app" composer:1.7.3 composer update
	docker run --rm -v "$(PWD):/app" composer:1.7.3 composer install

install:
	docker run --rm -v "$(PWD):/app" composer:1.7.3 composer install

run:
	docker-compose up

build:
	docker build -t bookshelf:dev .

test: install
	docker run --rm -v "$(PWD):/app" composer:1.7.3 vendor/bin/phpunit test

clean:
	docker-compose down
	docker run --rm -v "$(PWD):/app" composer:1.7.3 rm -rf vendor
