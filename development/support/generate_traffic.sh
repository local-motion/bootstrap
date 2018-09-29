#!/usr/bin/env bash

URL=$1
while true; do curl -o /dev/null -s -w "%{http_code}\\n" "${URL}"; sleep 1; done;