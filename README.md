# TinyNimDB
TinyDB for python is a great library that I wish all languages used for scripting had, it's meant to sort of be SQLite of NoSQL. TinyDB in python is a very simple database engine 
that is supposed to be, in author's own words "designed to be simple and fun to use by providing a simple and clean API" and TinyNimDB echoes that sentiment by providing a very 
similar API while being compatible with Nim's typechecker using Nim's Json library for interfacing.

# Differences
You create queries using json module like such
```
import dataTable, query, jsonStorage, json, idQuery, database

var db = createDB("test.json", makeStorage = jsonStorage.create)
var table = db.table("default")
let User = Query()
discard table.insert(%* {"name": "John", "age": 22})
echo table.search(User["name"] == %* "John")
```
As shown in the example above, all tables also need to be created explicitly before operations and no operation on a database directly is supported. In addition to the 
aforementioned, `TinyDB` is here aliased to create `createDB` since it's no longer a class but a function.

# Todo
- [x] Basic TinyDB API
- [x] The Json storage system
- [ ] `upsert`, `one_of`, and `match` function
- [ ] Query Cache
- [ ] Custom storage support
- [ ] Custom middleware support
