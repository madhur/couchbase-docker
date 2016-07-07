set -m

/entrypoint.sh couchbase-server &

sleep 60

# Setup index and memory quota
curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=300 -d indexMemoryQuota=300

# Setup services
curl -v http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex

# Setup credentials
curl -v http://127.0.0.1:8091/settings/web -d port=8091 -d username=Administrator -d password=kar.95424

# Load travel-sample bucket
#curl -v -u Administrator:password -X POST http://127.0.0.1:8091/sampleBuckets/install -d '["travel-sample"]'
curl -X POST -u Administrator:kar.95424 -d name=default -d ramQuotaMB=100 -d authType=none -d replicaNumber=2 -d proxyPort=11215 http://127.0.0.1:8091/pools/default/buckets


curl -X POST -u Administrator:kar.95424 -d name=feed -d ramQuotaMB=100 -d authType=none -d replicaNumber=2 -d proxyPort=11215 http://127.0.0.1:8091/pools/default/buckets


# Setup Memory Optimized Indexes
curl -i -u Administrator:kar.95424 -X POST http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'

echo "Type: $TYPE, Master: $COUCHBASE_MASTER"

if [ "$TYPE" = "worker" ]; then
  sleep 15
  set IP=`hostname -I`
  couchbase-cli server-add --cluster=$COUCHBASE_MASTER:8091 --user Administrator --password kar.95424 --server-add=$IP
  # TODO: Hack with the cuts, use jq may be better.
  #KNOWN_NODES=`curl -X POST -u Administrator:password http://$COUCHBASE_MASTER:8091/controller/addNode \
  #  -d hostname=$IP -d user=Administrator -d password=password -d services=kv,n1ql,index | cut -d: -f2 | cut -d\" -f 2 | sed -e   's/@/%40/g'`

  if [ "$AUTO_REBALANCE" = "true" ]; then
    echo "Auto Rebalance: $AUTO_REBALANCE"
    sleep 10
    couchbase-cli rebalance -c $COUCHBASE_MASTER:8091 -u Administrator -p kar.95424 --server-add=$IP
    #curl -v -X POST -u Administrator:kar.95424 http://$COUCHBASE_MASTER:8091/controller/rebalance --data "knownNodes=$KNOWN_NODES&ejectedNodes="
  fi;
fi;

fg 1

