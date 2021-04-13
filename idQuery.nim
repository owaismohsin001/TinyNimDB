import query

type
  EitherKind* = enum
    idKind, queryKind
  IdOrQuery*[A] = ref object
    ## Either ADT
    case kind*: EitherKind
    of idKind:
      lValue*: A
    else:
      rValue*: QueryInstance

proc isId*[A](self: IdOrQuery[A]) : bool = self.kind == idKind
proc isQuery*[A](self: IdOrQuery[A]) : bool = self.kind == queryKind

proc Create*[A](v: QueryInstance) : IdOrQuery[A] = IdOrQuery[A](kind: queryKind, rValue: v)
proc Create*[A](v: A) : IdOrQuery[A] = IdOrQuery[A](kind: idKind, lValue: v)

proc getId*[A](self: IdOrQuery[A]) : A = 
  if self.isId: return self.lValue else: raise newException(ValueError, "Cannot take left value from Right constructor")

proc getQuery*[A](self: IdOrQuery[A]) : QueryInstance = 
  if self.isQuery: return self.rValue else: raise newException(ValueError, "Cannot take right value from Left constructor")