#!/bin/bash

set -e

docker-compose run --rm go test -v ./...
