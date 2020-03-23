#!/bin/sh

mkdir -p dist
docker run -v "`pwd`:/data" danielfett/markdown2rfc claim-assertions.md dist
