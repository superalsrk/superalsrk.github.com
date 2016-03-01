#!/bin/bash

hexo clean
hexo generate

cd public

mkdir feed
cp atom.xml feed/index.xml

git init .
git remote add origin git@github.com:superalsrk/superalsrk.github.com.git
git add .
git commit -m ':green_book:'
git push -f origin master 
#cp atom.xml feed/index.xml
