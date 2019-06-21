//
//  ViewController.swift
//  Awarding System for Xianyou
//
//  Created by Thomas Tu on 5/16/16.
//  Copyright © 2016 Thomas Tu. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var commentsNumber: NSTextField!
    @IBOutlet weak var percentageArray: NSTextField!
    @IBOutlet weak var stockIndex: NSTextField!
    @IBOutlet weak var totalComments: NSTextField!
    @IBOutlet weak var winner: NSTextFieldCell!
    @IBOutlet weak var dateStock: NSDatePickerCell!
    
    func getDate(_ date: Date) -> (Int, Int, Int) {
        let components = (Calendar.current as NSCalendar).components([.day , .month , .year], from: date)
        return (year: components.year!, month: components.month!, day: components.day!)
        }
    
    @IBAction func checkStock(_ sender: AnyObject) {
        let date = dateStock.dateValue
        GetHistorcalPrice(getDate(date))
    }
    
    @IBAction func calculatingWinner(_ sender: AnyObject) {
        winner.stringValue = String(Int((Double(stockIndex.stringValue)! * 100).truncatingRemainder(dividingBy: totalComments.doubleValue)))
    }
    
    @IBAction func calculatingCommentsNumber(_ sender: NSButton) {
        commentsNumber.stringValue = ""
        let aArray = percentageArray.stringValue.characters.split(separator: " ").map(String.init).map{Double($0)!*totalComments.doubleValue}.map{Int(round($0/100))}
        for item in aArray {
            commentsNumber.stringValue += String(item)+"\n"
        }
    }
    
    func GetHistorcalPrice(_ date: (year: Int, month: Int, day: Int)){
        let year = date.year
        let month = date.month
        let day = date.day
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: URL(string: "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20csv%20where%20url%3D%27http%3A%2F%2Freal-chart.finance.yahoo.com%2Ftable.csv%3Fs%3D000001.SS%26a%3D\(month-1)%26b%3D\(day)%26c%3D\(year)%26d%3D\(month-1)%26e%3D\(day)%26f%3D\(year)%26g%3Dd%26ignore%3D.csv%27&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=")!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            
            if let error = error {
                print(error)
            }
            if let data = data{
                do{
                    let resultJSON = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
                    let resultDict = resultJSON as? NSDictionary
                    let queryDict = resultDict!["query"]
                    let resultsDict = queryDict!["results"]
                    guard let rowDict = resultsDict!!["row"] as? NSArray else {
                        self.stockIndex.stringValue = "当日没有数据"
                        return
                    }
                    let value = rowDict[1]

                    guard let index = value["col6"] as! String? else {
                        let todayDate = Date()
                        let today: (Int, Int, Int) = self.getDate(todayDate)
                        if today == (year, month, day) {
                            self.GetTodayPrice()
                            return
                        } else {
                            self.stockIndex.stringValue = "当日没有数据"
                            return
                        }                        
                    }
                    self.stockIndex.stringValue = index
                }catch _{
                    print("Received not-well-formatted JSON")
                }
            }
            if let response = response {
                let httpResponse = response as! HTTPURLResponse
                print("response code = \(httpResponse.statusCode)")
            }
        })
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GetTodayPrice()
    }
    
    func GetTodayPrice() {
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: URL(string: "http://hq.sinajs.cn/list=s_sh000001")!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) -> Void in
            
            var usedEncoding = String.Encoding.utf8
            if let encodingName = response!.textEncodingName {
                let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(encodingName))
                if encoding != UInt(kCFStringEncodingInvalidId) {
                    usedEncoding = encoding
                }
            }
            if let resultString = NSString(data: data!, encoding: usedEncoding) as? String {
                let startIndex = resultString.characters.index(resultString.startIndex, offsetBy: 23)
                let endIndex = resultString.characters.index(resultString.endIndex, offsetBy: -2)
                let dataString = resultString.substring(with: startIndex..<endIndex)
                let dataArray = dataString.characters.split(separator: ",")
                let todayPrice = round(Double(String(dataArray[1]))!*100)/100
                self.stockIndex.stringValue = String(todayPrice)
            } else {
                print("failed to decode data")
            }
        })
        task.resume()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

