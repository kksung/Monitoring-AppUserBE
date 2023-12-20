#!/bin/bash  
sudo docker run \
        --rm -d \
        -p 9090:9090 \
        -v /test/prometheus.yml:/etc/prometheus.yml \
        prom/prometheus-linux-amd64
