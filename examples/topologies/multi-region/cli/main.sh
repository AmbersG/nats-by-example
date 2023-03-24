#!/bin/bash

set -euo pipefail

sleep 3

nats context save east \
  --server nats://n1.east.example.net:4222 \
  --user one \
  --password secret

nats context save west \
  --server nats://n1.west.example.net:4222 \
  --user one \
  --password secret

nats context save central \
  --server nats://n1.central.example.net:4222 \
  --user one \
  --password secret

# Creating a region-local stream requires setting a tag for the desired region.
nats --context east stream add --config /app/ORDERS_EAST.json
nats --context west stream add --config /app/ORDERS_WEST.json
nats --context central stream add --config /app/ORDERS_CENTRAL.json

# Creating a global stream involves ommitting the --tag option.
nats --context east stream add --config /app/GLOBAL.json

# Let's see the stream report.
nats --context east stream report

# Publish a message from a client in each region.
nats --context east req js.in.orders 1
nats --context west req js.in.orders 1
nats --context central req js.in.orders 1

# Publish a message to the global stream.
nats --context east req js.in.global.orders 1

sleep 1

# Let's see the stream report again.
nats --context east stream report