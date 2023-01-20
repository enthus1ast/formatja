import tables
import nimja/lexer

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

proc format*(formatString: string, replacers: openarray[(string, string)]): string =
  var tmpReplacer: Replacer
  for replacer in replacers:
    tmpReplacer[replacer[0]] = replacer[1]
  return format(formatString, tmpReplacer)

when isMainModule:
  import unittest
  var formatSQLITE = "{{documentName}}__{{dateStr}}.sqlite"
  var formatXLSX = "{{documentName}}__{{dateStr}}.xlsx"
  var formatCSV = "{{documentName}}-{{csvtable}}__{{dateStr}}.csv"
  suite "formatja":
    test "simple1":
      check format(formatSQLITE, {"documentName": "FOO", "dateStr": "DATESTR"}) == "FOO__DATESTR.sqlite"
      check format(formatXLSX, {"documentName": "FOO", "dateStr": "DATESTR"}) == "FOO__DATESTR.xlsx"
    test "missing1":
      check format(formatCSV, {"documentName": "FOO", "dateStr": "DATESTR"}) == "FOO-__DATESTR.csv"
    test "other disabled nimja features":
      check format("{# comment #}", {"documentName": "FOO", "dateStr": "DATESTR"}) == ""
      check format("{% unused for now %}", {"documentName": "FOO", "dateStr": "DATESTR"}) == ""
