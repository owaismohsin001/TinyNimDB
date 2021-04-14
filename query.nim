{.experimental: "callOperator".}

import json, jsonUtils
import sequtils
import hashes

type
    QueryInstance* = ref object of RootObj
        test: proc(_: JsonNode): bool
        path: seq[string]
        hashval: Hash

proc call*(self: QueryInstance, val: JsonNode): bool = self.test(val)
proc hash*(self: QueryInstance): Hash = self.hashval

proc Query*(): QueryInstance = QueryInstance(
    test: proc(_: JsonNode): bool = raise newException(IOError, "Empty query was evaluated"),
    hashval: hash 0,
    path: @[]
    )

proc `[]`*(self: QueryInstance, index: string): QueryInstance = 
    var query = Query()
    query.path = self.path.concat(@[index])
    query.hashval = hash("path") !& hash query.path
    return query

proc generate_test(self: QueryInstance, test: proc(_: JsonNode): bool, hashval: Hash, allow_empty_path: bool = false): QueryInstance =
    if self.path == @[] and not allow_empty_path:
        raise newException(ValueError, "Query has no path")
    return QueryInstance(
        test: proc(value_given: JsonNode): bool =
            var value = value_given
            try:
                for part in self.path:
                    value = value[part]
                return test(value)
            except:
                return false                
        )

proc `and`*(self: QueryInstance, other: QueryInstance): QueryInstance = QueryInstance(
    test: proc(value: JsonNode): bool = self.call(value) and other.call(value),
    hashval: hash("and") !& hash(self.path) !& hash(other) !& hash self,
    path: self.path
)

proc `or`*(self: QueryInstance, other: QueryInstance): QueryInstance = QueryInstance(
    test: proc(value: JsonNode): bool = self.call(value) or other.call(value),
    hashval: hash("or") !& hash(self.path) !& hash(other) !& hash self,
    path: self.path
)

proc `~`*(self: QueryInstance): QueryInstance = QueryInstance(
    test: proc(value: JsonNode): bool = not self.call(value),
    hashval: hash("and") !& hash(self.path) !& hash self,
    path: self.path
)

proc `==`*(self: QueryInstance, rhs: JsonNode): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = value == rhs,
    hash("==") !& hash(self.path) !& hash rhs
)

proc `!=`*(self: QueryInstance, rhs: JsonNode): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = value != rhs,
    hash("!=") !& hash(self.path) !& hash rhs
)

proc `>`*(self: QueryInstance, rhs: JsonNode): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = value > rhs,
    hash(">") !& hash(self.path) !& hash rhs
)

proc `>=`*(self: QueryInstance, rhs: JsonNode): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = value >= rhs,
    hash(">=") !& hash(self.path) !& hash rhs
)

proc `<=`*(self: QueryInstance, rhs: JsonNode): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = value <= rhs,
    hash("<=") !& hash(self.path) !& hash rhs
)

proc `<`*(self: QueryInstance, rhs: JsonNode): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = value < rhs,
    hash("<") !& hash(self.path) !& hash rhs
)

proc exists*(self: QueryInstance, rhs: JsonNode): QueryInstance = self.generate_test(
    proc(_: JsonNode): bool = true,
    hash("<") !& hash(self.path) !& hash rhs
)

proc any*(self: QueryInstance, cond: QueryInstance): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = 
        result = false
        for x in value:
            result = result or cond.call(x)
    ,
    hash("any") !& hash(self.path) !& hash cond
)

proc any*(self: QueryInstance, cond: seq[JsonNode]): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = 
        result = false
        for x in value:
            result = result or (x in cond)
    ,
    hash("any") !& hash(self.path) !& hash cond
)

proc any*(self: QueryInstance, cond: JsonNode): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = 
        result = false
        for x in value:
            result = result or (x in cond)
    ,
    hash("any") !& hash(self.path) !& hash cond
)

proc all*(self: QueryInstance, cond: QueryInstance): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = 
        result = true
        for x in value:
            result = result and cond.call(x)
    ,
    hash("all") !& hash(self.path) !& hash cond
)

proc all*(self: QueryInstance, cond: seq[JsonNode]): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = 
        result = true
        for x in value:
            result = result and (x in cond)
    ,
    hash("all") !& hash(self.path) !& hash cond
)

proc all*(self: QueryInstance, cond: JsonNode): QueryInstance = self.generate_test(
    proc(value: JsonNode): bool = 
        result = true
        for x in value:
            result = result and (x in cond)
    ,
    hash("all") !& hash(self.path) !& hash cond
)

proc where*(path: string) : QueryInstance = Query()[path]
