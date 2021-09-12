import json
import os

proc touch(path: string, create_dirs: bool) =
    if create_dirs:
        let base_dir = splitPath(path).head
        if not existsDir(base_dir):
            createDir(base_dir)
    writeFile(path, "")

type
    JsonStorage* = ref object of RootObj
        path: string
        mode: FileMode

proc create*(path: string, create_dir: bool = false, access_mode: FileMode = fmWrite): JsonStorage =
    result = JsonStorage(mode: access_mode, path: path)
    if not os.existsFile(path):
        touch(path, create_dir)

proc write*(this: JsonStorage, data: JsonNode) = 
    let serialized = $(%* data)
    writeFile(this.path, serialized)

proc read*(this: JsonStorage): JsonNode =
    let content = readFile(this.path)
    if content == "":
        result = nil
    else:
        result = parseJson(content)
