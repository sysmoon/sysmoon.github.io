#!/bin/bash

bundle exec jekyll build
cd /Users/sysmoon/blog/sysmoon.github.io
git add .
git commit -m "jasper build"
git push -u origin master
