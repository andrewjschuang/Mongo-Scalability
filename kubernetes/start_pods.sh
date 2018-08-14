echo 'creating namespace'
kubectl create namespace dojot

echo 'starting 3 shard replicas'
kubectl -n dojot apply -f mongosh0.yaml
kubectl -n dojot apply -f mongosh1.yaml
kubectl -n dojot apply -f mongosh2.yaml

echo 'starting config server replica'
kubectl -n dojot apply -f mongocfg.yaml

echo 'waiting for initialization to finish'
sleep 2m

echo 'starting mongos'
export CONFIG_ENDPOINTS=$(kubectl -n dojot get endpoints mongocfg | grep mongocfg | awk '{print $2}')
sed -i '/configReplSet/c\        - configReplSet/'"$CONFIG_ENDPOINTS" mongos.yaml
kubectl -n dojot apply -f mongos.yaml

sleep 30

echo 'adding shards to mongos'
export RS0_ENDPOINTS=$(kubectl -n dojot get endpoints mongosh0 | grep mongosh0 | awk '{print $2}')
export RS1_ENDPOINTS=$(kubectl -n dojot get endpoints mongosh1 | grep mongosh1 | awk '{print $2}')
export RS2_ENDPOINTS=$(kubectl -n dojot get endpoints mongosh2 | grep mongosh2 | awk '{print $2}')
kubectl -n dojot exec mongos-0 -- mongo --eval "sh.addShard('rs0/$RS0_ENDPOINTS')"
kubectl -n dojot exec mongos-0 -- mongo --eval "sh.addShard('rs1/$RS1_ENDPOINTS')"
kubectl -n dojot exec mongos-0 -- mongo --eval "sh.addShard('rs2/$RS2_ENDPOINTS')"

echo 'enabling sharding'
export SHARDJS=$(cat shard.js)
kubectl -n dojot exec mongos-0 -- mongo --eval "$SHARDJS"

echo 'adding data'
export ADDJS=$(cat add_data.js)
kubectl -n dojot exec mongos-0 -- mongo --eval "$ADDJS"
