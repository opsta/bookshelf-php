#!/bin/bash

for i in {1..20}; do
  echo "Access front page.."
  curl -s -X GET http://localhost:8080/books/
  echo "Create book number ${i}..."
  curl -s -X POST -F "title=book-${i}" -F "author=book-${i}" http://localhost:8080/books/add
done
