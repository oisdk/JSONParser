# JSON Parser #
Parsing JSON is easy! Just take a string:
```JSON
{
    "glossary": {
        "title": "example glossary",
        "GlossDiv": {
            "title": "S",
            "GlossList": {
                "GlossEntry": {
                    "ID": "SGML",
                    "SortAs": "SGML",
                    "GlossTerm": "Standard Generalized Markup Language",
                    "Acronym": "SGML",
                    "Abbrev": "ISO 8879:1986",
                    "GlossDef": {
                        "para": "A meta-markup language, used to create markup languages such as DocBook.",
                        "GlossSeeAlso": ["GML", "XML"]
                    },
                    "GlossSee": "markup"
                }
            }
        }
    }
}
```
And use one of the two available methods. Either parse with error handling:
```swift
do {
  let handledParse = try first.asJSONThrow()
} catch {
  print("Oh noes")
  print(error)
}
```
Or with a result type:
```swift
switch first.asJSONResult() {
case let j?: let _ = j
case let .Error(e):
  print("Also oh noes")
  print(e)
}
```
The JSON can be got back, in a formatted form, via the description property:
```swift
switch first.asJSONResult() {
case let j?: print(j)
case let .Error(e):
  print("Also oh noes")
  print(e)
}
```
```JSON
{
    "glossary": {
        "title": "example glossary",
        "GlossDiv": {
            "title": "S",
            "GlossList": {
                "GlossEntry": {
                    "ID": "SGML",
                    "Acronym": "SGML",
                    "GlossDef": {
                        "para": "A meta-markup language, used to create markup languages such as DocBook.",
                        "GlossSeeAlso": [
                            "GML",
                            "XML"
                        ]
                    },
                    "SortAs": "SGML",
                    "GlossTerm": "Standard Generalized Markup Language",
                    "GlossSee": "markup",
                    "Abbrev": "ISO 8879:1986"
                }
            }
        }
    }
}
```
