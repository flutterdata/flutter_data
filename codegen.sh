#!/bin/bash

mv build.yaml /tmp
dart run build_runner build -d
mv lib/objectbox* /tmp
mv /tmp/build.yaml .
dart run build_runner build -d
mv /tmp/objectbox* lib/
dart run build_runner build -d