import json

proc comparisionOperation*[T](
        op: proc(a: int, b: int) : T, 
        opF: proc(a: float, b: float) : T, 
        lhs: JsonNode, 
        rhs: JsonNode
    ): T =
    case lhs.kind:
        of JInt: 
            case rhs.kind:
                of JFloat: return opF(float(lhs.getInt), rhs.getFloat)
                of JInt: return op(lhs.getInt, rhs.getInt)
                else: raise newException(ValueError, "Cannot compare " & $lhs.kind & " with " & $rhs.kind)
        of JFloat:
            case rhs.kind:
                of JFloat: return opF(lhs.getFloat, rhs.getFloat)
                of JInt: return opF(lhs.getFloat, float(rhs.getInt))
                else: raise newException(ValueError, "Cannot compare " & $lhs.kind & " with " & $rhs.kind)
        else: raise newException(ValueError, "Cannot compare " & $lhs.kind & " with " & $rhs.kind)

proc `>`*(lhs: JsonNode, rhs: JsonNode): bool = comparisionOperation(
    proc(a: int, b: int) : bool = a > b, proc(a: float, b: float) : bool = a > b, 
    lhs, rhs
)

proc `>=`*(lhs: JsonNode, rhs: JsonNode): bool = comparisionOperation(
    proc(a: int, b: int) : bool = a >= b, proc(a: float, b: float) : bool = a >= b, 
    lhs, rhs
)

proc `<=`*(lhs: JsonNode, rhs: JsonNode): bool = comparisionOperation(
    proc(a: int, b: int) : bool = a <= b, proc(a: float, b: float) : bool = a <= b, 
    lhs, rhs
)

proc `<`*(lhs: JsonNode, rhs: JsonNode): bool = comparisionOperation(
    proc(a: int, b: int) : bool = a < b, proc(a: float, b: float) : bool = a < b, 
    lhs, rhs
)

proc `+`*(a: JsonNode, b: JsonNode): JsonNode = comparisionOperation(
    proc(a: int, b: int) : JsonNode = %* (a + b), proc(a: float, b: float) : JsonNode = %*(a + b), 
    a, b
)

proc `-`*(a: JsonNode, b: JsonNode): JsonNode = comparisionOperation(
    proc(a: int, b: int) : JsonNode = %* (a - b), proc(a: float, b: float) : JsonNode = %*(a - b), 
    a, b
)

proc `*`*(a: JsonNode, b: JsonNode): JsonNode = comparisionOperation(
    proc(a: int, b: int) : JsonNode = %* (a * b), proc(a: float, b: float) : JsonNode = %*(a * b), 
    a, b
)

proc `/`*(a: JsonNode, b: JsonNode): JsonNode = comparisionOperation(
    proc(a: int, b: int) : JsonNode = %* (a / b), proc(a: float, b: float) : JsonNode = %*(a / b), 
    a, b
)

proc `&`*(a: JsonNode, b: JsonNode): JsonNode = 
    if a.kind == JString and b.kind == JString: return %* (a.getStr & b.getStr)
    else: raise newException(ValueError, "Cannot compare " & $a.kind & " with " & $b.kind)
