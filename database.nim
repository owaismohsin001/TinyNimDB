import dataTable as db
import jsonStorage
import tables
import sets
import query
import idQuery
import json

type
    NimDB* = ref object of RootObj
        storage: JsonStorage
        opened: bool
        internal_tables: tables.TableRef[string, db.Table]
        tableCreator: proc(storage: JsonStorage, name: string, cache_size: int = 10) : db.Table
        default_table_name: string

proc tableToSet(self: TableRef[string, db.Table]): HashSet[string] =
    var hashSet = initHashSet[string]()
    for k, _ in self:
        hashSet.incl(k)

proc tables*(self: NimDB): HashSet[string] =
    let store = self.storage.read()
    if isNil(store): return initHashSet[string]()
    let hashSet = tableToSet(self.internal_tables)
    return hashSet

proc table*(self: NimDB, name: string, cache_size: int = 10): db.Table =
    if name in self.internal_tables:
        return self.internal_tables[name]
    let table = self.tableCreator(self.storage, name, cache_size)
    self.internal_tables[name] = table
    return table

proc createDB*(
    path: string, create_dir: bool = false, access_mode: FileMode = fmWrite,
    makeStorage: proc(path: string, create_dir: bool = false, access_mode: FileMode = fmWrite) : JsonStorage
    ): NimDb = 
    var db = NimDB(
        storage: makeStorage(path, create_dir, access_mode), 
        opened: true, 
        internal_tables: newTable[string, db.Table](), 
        tableCreator: db.create,
        default_table_name: "_default"
        )
    return db

proc drop_table*(self: var NimDB, name: string) =
    if name in self.tables:
        del(self.internal_tables, name)
    let data = self.storage.read()
    if isNil(data): return
    if not (name in data): return 
    del(self.internal_tables, name)
    self.storage.write(data)

proc drop_tables*(self: var NimDB) =
    self.storage.write(%*{})
    self.internal_tables.clear

proc len*(self: NimDB): int = len(self.table(self.default_table_name))