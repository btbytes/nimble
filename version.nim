## Module for handling versions and version ranges such as ``>= 1.0 & <= 1.5``
import strutils
type
  TVersion* = distinct string
  TVersionRangeEnum* = enum
    verLater,     # > V
    verEarlier,   # < V
    verEqLater,   # >= V -- Equal or laterparseInt(sVer[i])
    verEqEarlier, # <= V -- Equal or earlier
    verIntersect, # > V & < V
    verAny        # *

  PVersionRange* = ref TVersionRange
  TVersionRange* = object
    case kind*: TVersionRangeEnum
    of verLater, verEarlier, verEqLater, verEqEarlier:
      ver*: TVersion
    of verIntersect:
      verI*: tuple[left: PVersionRange, right: PVersionRange]
    of verAny:
      nil

  EParseVersion = object of EBase

proc newVersion*(ver: string): TVersion = return TVersion(ver)

proc `$`*(ver: TVersion): String {.borrow.}

proc `<`*(ver: TVersion, ver2: TVersion): Bool =
  var sVer = string(ver).split('.')
  var sVer2 = string(ver2).split('.')
  for i in 0..max(sVer.len, sVer2.len)-1:
    if i > sVer.len-1:
      return True
    elif i > sVer2.len-1:
      return False

    var sVerI = parseInt(sVer[i])
    var sVerI2 = parseInt(sVer2[i])
    if sVerI < sVerI2:
      return True
    elif sVerI == sVerI2:
      nil
    else:
      return False

proc `==`*(ver: TVersion, ver2: TVersion): Bool {.borrow.}

proc `<=`*(ver: TVersion, ver2: TVersion): Bool =
  return (ver == ver2) or (ver < ver2)

proc withinRange*(ver: TVersion, ran: PVersionRange): Bool =
  case ran.kind
  of verLater:
    return ver > ran.ver
  of verEarlier:
    return ver < ran.ver
  of verEqLater:
    return ver >= ran.ver
  of verEqEarlier:
    return ver <= ran.ver
  of verIntersect:
    return withinRange(ver, ran.verI.left) and withinRange(ver, ran.verI.right)
  of verAny:
    return True


proc makeRange*(version: string, op: string): PVersionRange =
  new(result)
  case op
  of ">":
    result.kind = verLater
  of "<":
    result.kind = verEarlier
  of ">=":
    result.kind = verEqLater
  of "<=":
    result.kind = verEqEarlier
  else:
    raise newException(EParseVersion, "Invalid operator: " & op)
  result.ver = TVersion(version)

proc parseVersionRange*(s: string): PVersionRange =
  # >= 1.5 & <= 1.8
  new(result)

  var i = 0
  var op = ""
  var version = ""
  while True:
    case s[i]
    of '>', '<', '=':
      op.add(s[i])
    of '&':
      var left = makeRange(version, op)      
      
      # Parse everything after &
      # Recursion <3
      var right = parseVersionRange(copy(s, i + 1))
      
      result.kind = verIntersect
      result.verI = (left, right)
      break

    of '0'..'9', '.':
      version.add(s[i])

    of '\0':
      result = makeRange(version, op)
      break
    
    of ' ':
      nil # Ignore whitespace

    else:
      raise newException(EParseVersion, "Unexpected char in version range: " & s[i])
    inc(i)

when isMainModule:
  assert(newVersion("1.0") < newVersion("1.4"))
  assert(newVersion("1.0.1") > newVersion("1.0"))
  assert(newVersion("1.0.6") <= newVersion("1.0.6"))

  var inter1 = parseVersionRange(">= 1.0 & <= 1.5")

  assert(not withinRange(newVersion("1.5.1"), inter1))
  assert(withinRange(newVersion("1.2.3.4.5.6.7.8.9.10.11.12"), inter1))

  assert(newVersion("1") == newVersion("1"))

  echo("Everything works! Assuming that you didn't compile without assertions...")