import dataTable, query, jsonStorage, json, idQuery, database, jsonUtils 

var base = createDB("test.json", makeStorage = jsonStorage.create)
let t = base.table("people")
discard t.insert(@[%* {"name": "Angena", "age": 73}, %* {"name": "John", "age": 41}, %* {"name": "Will", "age": 8}, %* {"name": "Joe", "age": 19}])

echo t.update(proc(n: JsonNode) =
    n["age"] = n["age"] + %* 1,
    Create[seq[int]](where("name") == %* "Angena")
)

echo t.search(where("name") == %* "Angena")