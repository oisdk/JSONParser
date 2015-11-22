import Foundation
import XCPlayground
import JSONParser
func httpGet(request: NSURLRequest!, callback: (String, String?) -> Void) {
  let session = NSURLSession.sharedSession()
  let task = session.dataTaskWithRequest(request){
    (data, response, error) -> Void in
    if error != nil {
      callback("", error!.localizedDescription)
    } else {
      let result = NSString(data: data!, encoding:
        NSASCIIStringEncoding)!
      callback(result as String, nil)
    }
  }
  task.resume()
}


var request = NSMutableURLRequest(URL: NSURL(string: "http://www.reddit.com/r/pics.json")!)

httpGet(request){
  (data, error) -> Void in
  if let error = error {
    print(error)
  } else if let jo = data.asJSON() {
    print(jo)
  }
}

XCPSetExecutionShouldContinueIndefinitely(true)
