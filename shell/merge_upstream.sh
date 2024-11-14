#!/bin/sh

git remote -v

git fetch upstream


git checkout dev


git merge upstream/dev

git push origin dev


