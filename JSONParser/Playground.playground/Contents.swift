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

//: Or with a result type:
first.asJSON()
//: The JSON can be got back, in a formatted form, via the description property:
print(first.asJSON())
print("\n")
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
print("[1, 2, nll, 3]".asJSON())
print("\n")
print("[1, 2, 3, {\"a\":4, \"b\":5]".asJSON())
//: Building a JSON object is easy
let jason: JSON = [
  "first" : [1, 2, 3],
  "second": nil,
  "third" : true,
  "fourth": [nil, 1, 4.5, false]
]
print("\n")
print(String(jason).asJSON())

