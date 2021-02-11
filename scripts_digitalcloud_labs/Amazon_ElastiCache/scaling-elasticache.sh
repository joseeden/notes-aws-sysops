#1 Scaling Memcached horizontally

aws elasticache modify-cache-cluster --cache-cluster-id my-memcached --num-cache-nodes 2 --apply-immediately --region ap-southeast-2

#2 Delete a cluster

aws elasticache delete-cache-cluster --cache-cluster-id my-memcached --region ap-southeast-2

#3 Redis cluster mode enabled - adding shards online 

aws elasticache modify-replication-group-shard-configuration --replication-group-id my-redis-cme --node-group-count 3 --apply-immediately --region ap-southeast-2

#4 Redis cluster mode enabled - scaling vertically 

aws elasticache list-allowed-node-type-modifications --replication-group-id my-redis-cme --region ap-southeast-2

aws elasticache modify-replication-group --replication-group-id my-redis-cme --cache-node-type cache.t3.small --apply-immediately --region ap-southeast-2

#5 Redis cluster mode disabled - scaling reads (add read replica)

aws elasticache create-cache-cluster --cache-cluster-id my-read-replica --replication-group-id my-redis-cmd --region ap-southeast-2

#6 Redis cluster mode disabled - scaling vertically

aws elasticache list-allowed-node-type-modifications --replication-group-id my-redis-cmd --region ap-southeast-2

aws elasticache modify-replication-group --replication-group-id my-redis-cmd --cache-node-type cache.t3.small --apply-immediately --region ap-southeast-2



