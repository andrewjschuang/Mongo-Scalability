#!/bin/bash

# creates shards
N_SHARDS=3
N_SHARD_REPLICAS=2
N_CONFIG_REPLICAS=3
SHARD_PORT=27050
CONFIG_PORT=27100
MONGOS_PORT=27018

echo "Initiating servers..."
N=0
PORT=$SHARD_PORT
for ((j=0;j<N_SHARDS;j++)); do
    for ((i=0;i<N_SHARD_REPLICAS;i++)); do
        mkdir -p dbs/db$N
        mongod --replSet "rs$j" --shardsvr --port $PORT --bind_ip localhost --dbpath "dbs/db$N" &>/dev/null &
        ((N++))
        ((PORT++))
    done
done

# creates configdb servers
PORT=$CONFIG_PORT
for ((i=0;i<N_CONFIG_REPLICAS;i++)); do
    mkdir -p dbs/cfg$i
    mongod --configsvr --replSet configReplSet --port $PORT --bind_ip localhost --dbpath "dbs/cfg$i" &>/dev/null &
    ((PORT++))
done

sleep 30

# adds data to db
echo "Adding data"
PORT=$SHARD_PORT
mongo localhost:$SHARD_PORT/test add_data.js &>/dev/null

echo "Initiating replicas"
# initiates replicas
PORT=$SHARD_PORT
for ((i=0;i<N_SHARDS;i++)); do
    mongo --port $PORT --eval \
    "rs.initiate( {
       _id : 'rs$i',
       members: [
           { _id: 0, host: 'localhost:$PORT' },
           { _id: 1, host: 'localhost:$((PORT+1))' },
       ]
    })" &>/dev/null
    ((PORT+=2))
done

PORT=$CONFIG_PORT
mongo --port $PORT --eval \
"rs.initiate( {
   _id: 'configReplSet',
   configsvr: true,
   members: [
      { _id: 0, host: 'localhost:$PORT' },
      { _id: 1, host: 'localhost:$((PORT+1))' },
      { _id: 2, host: 'localhost:$((PORT+2))' }
   ]
})" &>/dev/null

echo "Starting mongos"
# creates mongos router
mongos --configdb configReplSet/localhost:$CONFIG_PORT,localhost:$((CONFIG_PORT+1)),localhost:$((CONFIG_PORT+2)) --bind_ip localhost --port $MONGOS_PORT &>/dev/null &

sleep 5

# adds shard
PORT=$SHARD_PORT
for ((j=0;j<N_SHARDS;j++)); do
    mongo localhost:$MONGOS_PORT/admin --eval \
    "sh.addShard( 'rs$j/localhost:$PORT,localhost:$((PORT+1))' )" &>/dev/null
    ((PORT+=2))
done

echo "Enabling sharding"
# shards collection
mongo localhost:$MONGOS_PORT/test shard.js &>/dev/null
