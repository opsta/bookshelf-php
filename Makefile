PWD = $(shell pwd)

all: install run

install:
	docker run --rm -v "$(PWD):/app" composer:1.6.4 composer install

run:
	docker-compose up

build:
	docker build -t bookshelf:dev .

test: install
	docker run --rm -v "$(PWD):/app" composer:1.6.4 vendor/bin/phpunit test

clean:
	docker-compose down
	docker run --rm -v "$(PWD):/app" composer:1.6.4 rm -rf vendor
