// enables sharding
sh.enableSharding( "test" );
// creates index
db.test_collection.createIndex( { number : 1 } );
// start shardign
sh.shardCollection( "test.test_collection", { "number" : 1 } );
