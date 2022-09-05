//
//  UIViewController+Extension.swift
//  Asteroid - Neo
//
//  Created by Meet's MAC on 05/09/22.
//

import UIKit

extension UIViewController{

    //MARK: - Message Alert
    func message_popup(message:String){
        let app_name = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Message"
        let alert = UIAlertController(title: app_name, message: message, preferredStyle: .alert)
        let ohk_action = UIAlertAction(title: "OK", style: .default) { _Arg in
            //
        }
        alert.addAction(ohk_action)
        self.present(alert, animated: true, completion: nil)
    }

    //MARK: - number of days in between two dates
    func GetDateDifference(start_date: String, end_date: String) -> Int{
        let start_df = DateFormatter()
        start_df.dateFormat = "yyyy-MM-dd"
        let start_dt = start_df.date(from: start_date)

        let end_df = DateFormatter()
        end_df.dateFormat = "yyyy-MM-dd"
        let end_dt = end_df.date(from: end_date)

        guard start_dt != nil, end_dt != nil else{
            return -1
        }

        let currentCalendar = Calendar.current
        guard let start = currentCalendar.ordinality(of: .day, in: .era, for: start_dt!) else {
            return 0
        }

        guard let end = currentCalendar.ordinality(of: .day, in: .era, for: end_dt!) else {
            return 0
        }

        return end - start
    }

    //MARK: - Random color array
    func colorsOfCharts(numbersOfColor: Int) -> [UIColor] {
        var colors: [UIColor] = []
        for _ in 0..<numbersOfColor {
            let red = Double(arc4random_uniform(256))
            let green = Double(arc4random_uniform(256))
            let blue = Double(arc4random_uniform(256))
            let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
            colors.append(color)
        }
        return colors
    }

}

