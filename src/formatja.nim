import tables
import nimja/lexer
import macros

type
  Replacer* = Table[string, string]

proc format*(formatString: string, replacers: Replacer): string =
  for token in lex(formatString):
    # echo token
    case token.kind
    of NwtString:
      result.add token.value
    of NwtVariable:
      result.add replacers.getOrDefault(token.value, "")
    of NwtComment:
      continue
    else: discard

proc addObjImpl[T](replacers: var Replacer, name: string, obj: T) =
  for key, val in fieldPairs(obj):
    let keyStr = name & "." & key 
    replacers[keyStr] = $val

# TODO Fix ref obj
# proc addObjImpl[T](replacers: var Replacer, name: string, refobj: ref T) =
#   var obj = refobj[]
#   addObjImpl(replacers, name, obj)

macro addObj*(replacers: typed, tys: untyped): untyped =
  result = newStmtList()
  for ty in tys:
    let name: string = $ty
    result.add quote do:
      `replacers`.addObjImpl(`name`, `ty`)

proc format*(formatString: string, replacers: openarray[(string, string)]): string =
  var tmpReplacer: Replacer
  for replacer in replacers:
    tmpReplacer[replacer[0]] = replacer[1]
  return format(formatString, tmpReplacer)

macro formatObj*(formatString: string, replacerObjs: untyped): untyped =
  result = newStmtList()
  var rp = genSym(nskVar)
  result.add quote do:
    var `rp`: Replacer
  for ty in replacerObjs:
    let name: string = $ty
    result.add quote do:
      `rp`.addObjImpl(`name`, `ty`)
  result.add quote do:
    format(`formatString`, `rp`)

when isMainModule:
  import unittest
  var formatSQLITE = "{{documentName}}__{{dateStr}}.sqlite"
  var formatXLSX = "{{documentName}}__{{dateStr}}.xlsx"
  var formatCSV = "{{documentName}}-{{csvtable}}__{{dateStr}}.csv"
  var formatStr = "{{foo.ss}} {{foo.ii}} {{foo.ff}} {{baa.ss}} {{baa.ii}} {{baa.ff}}"
  suite "formatja":
    test "simple1":
      check format(formatSQLITE, {"documentName": "FOO", "dateStr": "DATESTR"}) == "FOO__DATESTR.sqlite"
      check format(formatXLSX, {"documentName": "FOO", "dateStr": "DATESTR"}) == "FOO__DATESTR.xlsx"
    test "missing1":
      check format(formatCSV, {"documentName": "FOO", "dateStr": "DATESTR"}) == "FOO-__DATESTR.csv"
    test "other disabled nimja features":
      check format("{# comment #}", {"documentName": "FOO", "dateStr": "DATESTR"}) == ""
      check format("{% unused for now %}", {"documentName": "FOO", "dateStr": "DATESTR"}) == ""
    test "format obj":
      type
        Foo = object
          ss: string
          ii: int
          ff: float
        Baa = object
          ss: string
          ii: int
          ff: float
      var foo = Foo(ss: "FOO SS", ii: 1337, ff: 18.15)
      var baa = Baa(ss: "BAA SS", ii: 1338, ff: 18.16)
      block:
        var replacers: Replacer 
        replacers.addObj([foo, baa])
        check format(formatStr, replacers) == "FOO SS 1337 18.15 BAA SS 1338 18.16"
      block:
        check formatObj(formatStr, [foo, baa]) == "FOO SS 1337 18.15 BAA SS 1338 18.16"


    # test "format ref obj":
    #   type
    #     Base = ref object of RootObj
    #       hoho: string
    #     Child = ref object of Base
    #       ss: string
    #       ii: int
    #       ff: float
    #   var fooRef = Child(ss: "FOO SS", ii: 1337, ff: 18.15)
    #   var baaRef = Child(ss: "BAA SS", ii: 1338, ff: 18.16)
    #   let foo = fooRef
    #   let baa = baaRef
    #   check formatObj(formatStr, [foo, baa]) == "FOO SS 1337 18.15 BAA SS 1338 18.16"
    #   # check formatObj(formatStr, [fooRef, baaRef]) == "FOO SS 1337 18.15 BAA SS 1338 18.16"
    #   # echo formatObj(formatStr, [foo, baa]) 
    #   # check format(formatStr, replacers) == "FOO SS 1337 18.15 BAA SS 1338 18.16"

