#!/bin/bash

sudo docker run --rm --privileged -it -p8850:8850 -p80:80 \
-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-v /opt/tableau/tableau_driver:/opt/tableau/tableau_driver \
-v /storage/tableau:/var/opt/tableau \
-v /etc/odbcinst.ini:/etc/odbcinst.ini \
wrenchpilot/tableau:2020.1.2
