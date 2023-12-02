#!/bin/bash


timestamp=$(date +"%Y-%m-%d") # 2023-12-01
post_title=$(echo $1 | sed -s "s/ /-/g")

post_file_name="$timestamp-$post_title.md"


cp post-front-matter.md "_posts/$post_file_name"

