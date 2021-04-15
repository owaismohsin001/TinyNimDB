import jsonStorage
import options
import strutils
import json
import idQuery
import cache
import query

type
    Table* = ref object of RootObj
        storage: JsonStorage
        name: string
        query_cache: LruCache[string, seq[JsonNode]]
        next_id: Option[int]

proc create*(storage: JsonStorage, name: string, cache_size: int = 10) : Table = Table(storage: storage, name: name, next_id: none(int), query_cache: newLruCache[string, seq[JsonNode]](cache_size))

proc len*(self: Table): int =
    let tables: JsonNode = self.storage.read()
    if isNil(tables): return 0
    if self.name in tables: return len(tables[self.name])
    return 0

proc clear_cache*(self: Table) = self.query_cache.clear

proc read_table(self: Table) : JsonNode =
    let tables = self.storage.read
    if isNil(tables):
        return %*{}
    var table: JsonNode
    if self.name in tables:
        table = tables[self.name]
    else:
        return %*{}
    return table

proc get_next_id(self: Table) : int =
    if self.next_id != none(int):
        self.next_id = self.next_id.map(proc(x: int): int = x+1)
        return self.next_id.get - 1
    else:
        let table = self.read_table
        if table == %*{}:
            let next_id = 1
            self.next_id = some(next_id + 1)
            return next_id
        var keys: seq[int] = @[]
        for k, _ in table:
            keys.add(parseInt(k))
        let max_id = max(keys)
        let next_id = max_id + 1
        self.next_id = some(next_id + 1)
        return next_id

proc update_table(self: Table, updater: proc(_: JsonNode) : void = proc(a: JsonNode) = discard) =
    var tables = self.storage.read
    if isNil(tables):
        tables = %* {}
    var raw_table: JsonNode
    if self.name in tables:
        raw_table = tables[self.name]
    else:
        raw_table = %*{}
    var table = %*{}
    for doc_id, doc in raw_table:
        table[doc_id] = doc
    updater(table)
    var inner_table = %*{}
    for doc_id, doc in table:
        inner_table[doc_id] = doc
    tables[self.name] = inner_table
    self.storage.write(tables)
    self.clear_cache()

proc insert*(self: Table, document: JsonNode) : int =
    let doc_id = self.get_next_id
    self.update_table(
        proc(table: JsonNode) =
            table[$doc_id] = document
    )
    return doc_id

proc insert*(self: Table, docs: seq[JsonNode]) : seq[int] =
    var doc_ids: seq[int] = @[]
    self.update_table(
        proc(table: JsonNode) =
            for doc in docs:
                let doc_id = self.get_next_id
                doc_ids.add(doc_id)
                table[$doc_id] = doc
    )
    return doc_ids

iterator items*(self: Table) : JsonNode =
    let table = self.read_table
    if table.kind == JArray:
        for obj in table:  yield obj
    elif table.kind == JObject:
        for _, v in table:  yield v

iterator pairs*(self: Table): (string, JsonNode) =
    for k, v in self.read_table: yield (k, v)

proc search*(self: Table, cond: QueryInstance): seq[JsonNode] =
    result = @[]
    let hasedCond = hashToString cond
    if self.query_cache.contains(hasedCond):
        return self.query_cache[hasedCond]
    for doc in self:
        if cond.call(doc):
            result.add(doc)
    self.query_cache[hasedCond] = result

proc get*(self: Table, cond: IdOrQuery[int]): JsonNode =
    for doc in self:
        if cond.isQuery:
            if cond.getQuery.call(doc): return doc
        else:
            let table = self.read_table
            let right = $cond.getId
            if table.contains(right):
                return table[right]
            return nil

proc update*(self: Table, fields: JsonNode, cond: IdOrQuery[seq[int]]) : seq[int] =
    var updated_ids: seq[int] = @[]
    if cond.isId:
        for i in cond.getId:
            updated_ids.add(i)
    self.update_table(
        proc(node: JsonNode) =
        if cond.isQuery:
            var keys : seq[string] = @[]
            for k, _ in node:
                keys.add(k)
            for doc_id in keys:
                if cond.getQuery.call(node[doc_id]):
                    updated_ids.add(parseInt(doc_id))
                    for k, v in fields:
                        node[$doc_id][k] = v
        else:
            echo node.kind
            for doc_id in updated_ids:
                for k, v in fields:
                    node[$doc_id][k] = v
    )
    return updated_ids

proc update*(self: Table, fields: proc(_: JsonNode), cond: IdOrQuery[seq[int]]) : seq[int] =
    var updated_ids: seq[int] = @[]
    if cond.isId:
        for i in cond.getId:
            updated_ids.add(i)
    self.update_table(
        proc(node: JsonNode) =
        if cond.isQuery:
            var keys : seq[string] = @[]
            for k, _ in node:
                keys.add(k)
            for doc_id in keys:
                if cond.getQuery.call(node[doc_id]):
                    updated_ids.add(parseInt(doc_id))
                    fields(node[doc_id])
        else:
            echo node.kind
            for doc_id in updated_ids:
                fields(node[$doc_id])
    )
    return updated_ids

proc remove*(self: Table, cond: IdOrQuery[seq[int]]) : seq[int] =
    var removed_ids: seq[int] = @[]
    if cond.isId:
        for i in cond.getId:
            removed_ids.add(i)
    self.update_table(
        proc(node: JsonNode) =
        if cond.isQuery:
            var keys : seq[string] = @[]
            for k, _ in node:
                keys.add(k)
            for doc_id in keys:
                if cond.getQuery.call(node[doc_id]):
                    removed_ids.add(parseInt(doc_id))
                    node.delete(doc_id)
        else:
            echo node.kind
            for doc_id in removed_ids:
                node.delete($doc_id)
    )
    return removed_ids

proc count*(self: Table, cond: QueryInstance) : int = len(self.search(cond))

proc truncate*(self: Table) =
    self.update_table(
        proc(table: JsonNode) = 
            var keys : seq[string] = @[]
            for k, v in table:
                keys.add(k)
            for k in keys:
                table.delete(k)
    )
    self.next_id = none(int)
