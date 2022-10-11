#!/bin/bash
set -e -o pipefail

if [[ "$1" == "apply" ]]; then
  tfswitch || true
  (cd 010-certificates && ./main.sh apply)
  (cd 020-infrastructure && ./main.sh apply)
  (cd 030-test-connectivity && ./main.sh apply)
fi

if [[ "$1" == "destroy" ]]; then
  (cd 030-test-connectivity && ./main.sh destroy) || true
  (cd 020-infrastructure && ./main.sh destroy) || true
  (cd 010-certificates && ./main.sh destroy) || true
fi

if [[ "$1" == "clean" ]]; then
  (cd 030-test-connectivity && ./main.sh clean) || true
  (cd 020-infrastructure && ./main.sh clean) || true
  (cd 010-certificates && ./main.sh clean) || true
  rm -f config/client.ovpn
  rmdir config || true
fi