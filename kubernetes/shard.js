sh.enableSharding( "test" ); db.test_collection.createIndex( { number : "hashed" } ); sh.shardCollection( "test.test_collection", { "number" : "hashed" } );
