import JSONParser
//: Parsing JSON is easy! Just take a string:
// {
//     "glossary": {
//         "title": "example glossary",
//         "GlossDiv": {
//             "title": "S",
//             "GlossList": {
//                 "GlossEntry": {
//                     "ID": "SGML",
//                     "SortAs": "SGML",
//                     "GlossTerm": "Standard Generalized Markup Language",
//                     "Acronym": "SGML",
//                     "Abbrev": "ISO 8879:1986",
//                     "GlossDef": {
//                         "para": "A meta-markup language, used to create markup languages such as DocBook.",
//                         "GlossSeeAlso": ["GML", "XML"]
//                     },
//                     "GlossSee": "markup"
//                 }
//             }
//         }
//     }
// }
//: And use one of the two available methods. Either parse with error handling:
do {
  let handledParse = try first.asJSONThrow()
} catch {
  print("Oh noes")
  print(error)
}
//: Or with a result type:
switch first.asJSONResult() {
case let j?: let _ = j
case let .Error(e):
  print("Also oh noes")
  print(e)
}
//: The JSON can be got back, in a formatted form, via the description property:
switch first.asJSONResult() {
case let j?: print(j)
case let .Error(e):
  print("Also oh noes")
  print(e)
}
// {
//     "glossary": {
//         "title": "example glossary",
//         "GlossDiv": {
//             "title": "S",
//             "GlossList": {
//                 "GlossEntry": {
//                     "ID": "SGML",
//                     "Acronym": "SGML",
//                     "GlossDef": {
//                         "para": "A meta-markup language, used to create markup languages such as DocBook.",
//                         "GlossSeeAlso": [
//                             "GML",
//                             "XML"
//                         ]
//                     },
//                     "SortAs": "SGML",
//                     "GlossTerm": "Standard Generalized Markup Language",
//                     "GlossSee": "markup",
//                     "Abbrev": "ISO 8879:1986"
//                 }
//             }
//         }
//     }
// }
//: You'll get helpful errors if there's a problem with your JSON
"[1, 2, nll, 3]".asJSONResult()
"[1, 2, 3, {\"a\":4, \"b\":5]".asJSONResult()
//: Building a JSON object is easy
let jason: JSON = [
  "first" : [1, 2, 3],
  "second": nil,
  "third" : true,
  "fourth": [nil, 1, 4.5, false]
]
print(String(jason).asJSONResult())


Double("3E4")
