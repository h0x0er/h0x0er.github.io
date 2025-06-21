#!/bin/bash

msg="${1:-updated}"

git add .
git commit -m "memories: $msg"
git push