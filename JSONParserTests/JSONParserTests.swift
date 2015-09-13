//
//  JSONParserTests.swift
//  JSONParserTests
//
//  Created by Donnacha Oisín Kidney on 13/09/2015.
//  Copyright © 2015 Donnacha Oisín Kidney. All rights reserved.
//

import XCTest
@testable import JSONParser

class JSONParserTests: XCTestCase {
  
  // Taken from http://json.org/example.html
  
  func testFirst() {

//{
//  "glossary": {
//    "title": "example glossary",
//    "GlossDiv": {
//      "title": "S",
//      "GlossList": {
//        "GlossEntry": {
//          "ID": "SGML",
//          "SortAs": "SGML",
//          "GlossTerm": "Standard Generalized Markup Language",
//          "Acronym": "SGML",
//          "Abbrev": "ISO 8879:1986",
//          "GlossDef": {
//            "para": "A meta-markup language, used to create markup languages such as DocBook.",
//            "GlossSeeAlso": ["GML", "XML"]
//          },
//          "GlossSee": "markup"
//        }
//      }
//    }
//  }
//}

    let coded = "{\n    \"glossary\": {\n        \"title\": \"example glossary\",\n        \"GlossDiv\": {\n            \"title\": \"S\",\n            \"GlossList\": {\n                \"GlossEntry\": {\n                    \"ID\": \"SGML\",\n                    \"SortAs\": \"SGML\",\n                    \"GlossTerm\": \"Standard Generalized Markup Language\",\n                    \"Acronym\": \"SGML\",\n                    \"Abbrev\": \"ISO 8879:1986\",\n                    \"GlossDef\": {\n                        \"para\": \"A meta-markup language, used to create markup languages such as DocBook.\",\n                        \"GlossSeeAlso\": [\"GML\", \"XML\"]\n                    },\n                    \"GlossSee\": \"markup\"\n                }\n            }\n        }\n    }\n}\n"
    
//{
//    "glossary": {
//        "title": "example glossary",
//        "GlossDiv": {
//            "title": "S",
//            "GlossList": {
//                "GlossEntry": {
//                    "ID": "SGML",
//                    "Acronym": "SGML",
//                    "GlossDef": {
//                        "para": "A meta-markup language, used to create markup languages such as DocBook.",
//                        "GlossSeeAlso": [
//                            "GML",
//                            "XML"
//                        ]
//                    },
//                    "SortAs": "SGML",
//                    "GlossTerm": "Standard Generalized Markup Language",
//                    "GlossSee": "markup",
//                    "Abbrev": "ISO 8879:1986"
//                }
//            }
//        }
//    }
//}
    
    let expectation = "{\n    \"glossary\": {\n        \"title\": \"example glossary\",\n        \"GlossDiv\": {\n            \"title\": \"S\",\n            \"GlossList\": {\n                \"GlossEntry\": {\n                    \"ID\": \"SGML\",\n                    \"Acronym\": \"SGML\",\n                    \"GlossDef\": {\n                        \"para\": \"A meta-markup language, used to create markup languages such as DocBook.\",\n                        \"GlossSeeAlso\": [\n                            \"GML\",\n                            \"XML\"\n                        ]\n                    },\n                    \"SortAs\": \"SGML\",\n                    \"GlossTerm\": \"Standard Generalized Markup Language\",\n                    \"GlossSee\": \"markup\",\n                    \"Abbrev\": \"ISO 8879:1986\"\n                }\n            }\n        }\n    }\n}"
    
    
    switch coded.asJSONResult() {
    case let .Some(j):
      print(j.description)
      XCTAssertEqual(expectation, j.description)
    case let .Error(e): XCTAssert(false, String(reflecting: e))
    }
  }
    
}
