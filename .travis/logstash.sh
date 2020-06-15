#!/bin/sh -eu

DIFF="$(git diff --name-status --diff-filter=M HEAD~1..HEAD pipeline)"

[ -z "${DIFF}" ] && exit 0

docker pull logstash:${LOGSTASH_VERSION}
docker run -v ${PWD}/pipeline:/usr/share/logstash/pipeline logstash:${LOGSTASH_VERSION} --config.test_and_exit
