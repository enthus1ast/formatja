formatja
========

A simple *runtime* string interpolation library, that leverages [nimjas](https://github.com/enthus1ast/nimja) lexer.

```nim
var formatSQLITE = "{{documentName}}__{{dateStr}}.sqlite"
let res = format(formatSQLITE, {"documentName": "FOO", "dateStr": "DATESTR"})
assert res == "FOO__DATESTR.sqlite"
```

```
{{ some }}  a variable
{# a comment #} a comment
{% ignored %} ignored for now
```