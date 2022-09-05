//
//  ViewController.swift
//  Asteroid - Neo
//
//  Created by Meet's MAC on 05/09/22.
//

import UIKit
import Charts

class ViewController: UIViewController {

    //MARK: - referenecs
    @IBOutlet weak var txt_start_date: UITextField!
    @IBOutlet weak var txt_end_date: UITextField!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var lbl_fastest_asteroid_id: UILabel!
    @IBOutlet weak var lbl_fastest_asteroid_speed: UILabel!
    @IBOutlet weak var lbl_closest_astroid_id: UILabel!
    @IBOutlet weak var lbl_closest_astroid_distance: UILabel!
    @IBOutlet weak var lbl_average_size_of_astroid: UILabel!
    @IBOutlet weak var st_data_container: UIStackView!
    
    //MARK: - Variables
    var start_date_picker = UIDatePicker()
    var end_date_picker = UIDatePicker()
    let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        //Hide data desplay view at initial time
        st_data_container.isHidden = true

        //View setup
        DatePickerSetup()
        TextFieldSetup()
    }

    //MARK: - Actions
    @IBAction func BTNSubmitAction(_ sender: UIButton) {

        guard let start_date = txt_start_date.text, start_date != "" else{
            self.message_popup(message: STRINGS.start_date_empty)
            return
        }

        guard let end_date = txt_end_date.text, end_date != "" else{
            self.message_popup(message: STRINGS.end_date_empty)
            return
        }

        // Check date difference first
        if GetDateDifference(start_date: start_date, end_date: end_date) >= 0{
            self.GetData(start_date: start_date, end_date: end_date)
        }else{
            self.message_popup(message: STRINGS.end_should_be_greater_to_start)
        }
    }

    func customizeChart(dataPoints: [String], values: [Double]) {

        var dataEntries: [BarChartDataEntry] = []
        for i in 0..<dataPoints.count {
          let dataEntry = BarChartDataEntry(x: Double(i), y: Double(values[i]))
          dataEntries.append(dataEntry)
        }

        let chartDataSet = BarChartDataSet(entries: dataEntries, label: "Daily Asteroids")
        let chartData = BarChartData(dataSet: chartDataSet)
        barChartView.data = chartData
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:dataPoints)
        barChartView.xAxis.granularity = 1

    }
}

//MARK: - date picker setup
extension ViewController{

    func DatePickerSetup(){
        dateFormatter.dateFormat = "yyyy-MM-dd"

        start_date_picker.maximumDate = Date()
        start_date_picker.preferredDatePickerStyle = .inline
        start_date_picker.addTarget(self, action: #selector(StartDatePickerValueChanged), for: .valueChanged)

        end_date_picker.maximumDate = Date()
        end_date_picker.preferredDatePickerStyle = .inline
        end_date_picker.addTarget(self, action: #selector(EndDatePickerValueChanged), for: .valueChanged)
    }

    //MARK: - Actions
    @objc func StartDatePickerValueChanged(_ sender: UIDatePicker) {
        txt_start_date.text = dateFormatter.string(from: sender.date)
    }

    @objc func EndDatePickerValueChanged(_ sender: UIDatePicker) {
        txt_end_date.text = dateFormatter.string(from: sender.date)
    }

}

//MARK: - textfield setup
extension ViewController: UITextFieldDelegate{

    func TextFieldSetup(){

        txt_start_date.text = dateFormatter.string(from: Date())
        txt_end_date.text = dateFormatter.string(from: Date())

        txt_start_date.layer.cornerRadius = 8
        txt_end_date.layer.cornerRadius = 8

        txt_start_date.delegate = self
        txt_end_date.delegate = self

        txt_start_date.inputView = start_date_picker
        txt_end_date.inputView = end_date_picker
    }

    //MARK: - Delegate Methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.darkGray.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.borderWidth = 0
        textField.layer.borderColor = UIColor.clear.cgColor
    }
}

//MARK: - Get Data
extension ViewController{

    func GetData(start_date: String, end_date: String){

        guard let url = URL(string: "\(feed_base_url)?start_date=\(start_date)&end_date=\(end_date)&api_key=\(api_key)") else {
            self.message_popup(message: "Invalid url request")
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else{
                self.message_popup(message: error?.localizedDescription ?? STRINGS.error_message)
                return
            }

            guard let res_data = data else{
                self.message_popup(message: STRINGS.error_message)
                return
            }

            do{
                let json = try JSONSerialization.jsonObject(with: res_data, options: .mutableContainers) as? NSDictionary
                print(json as Any)

                DispatchQueue.main.async {

                    if let near_earth_objects = json?.value(forKey: "near_earth_objects") as? NSDictionary{
                        let column_data = near_earth_objects.allKeys as? [String] ?? []
                        var row_data = [Double]()
                        var asteroids_list = [NSDictionary]()
                        for key in column_data{
                            let asteroids = near_earth_objects.value(forKey: key) as? [NSDictionary] ?? []
                            row_data.append(Double(asteroids.count))
                            asteroids_list.append(contentsOf: asteroids)
                        }

                        self.customizeChart(dataPoints: column_data, values: row_data)

                        self.st_data_container.isHidden = false

                        //Fastest data setup
                        let fastest_sorted = asteroids_list.sorted (by:{first,second in
                            let first_close_approach_data = first.value(forKey: "close_approach_data") as? [NSDictionary]
                            let second_close_approach_data = second.value(forKey: "close_approach_data") as? [NSDictionary]

                            let first_relative_velocity = first_close_approach_data?.first?.value(forKey: "relative_velocity") as? NSDictionary
                            let second_relative_velocity = second_close_approach_data?.first?.value(forKey: "relative_velocity") as? NSDictionary

                            let first_kilometers_per_hour = Double(first_relative_velocity?.value(forKey: "kilometers_per_hour") as? String ?? "0") ?? 0.0
                            let second_kilometers_per_hour = Double(second_relative_velocity?.value(forKey: "kilometers_per_hour") as? String ?? "0") ?? 0.0

                            return first_kilometers_per_hour > second_kilometers_per_hour
                        })
                        self.lbl_fastest_asteroid_id.text = fastest_sorted.first?.value(forKey: "id") as? String ?? ""
                        let fastest_sorted_close_approach_data = fastest_sorted.first?.value(forKey: "close_approach_data") as? [NSDictionary]
                        let relative_velocity = fastest_sorted_close_approach_data?.first?.value(forKey: "relative_velocity") as? NSDictionary
                        let kilometers_per_hour = Double(relative_velocity?.value(forKey: "kilometers_per_hour") as? String ?? "0") ?? 0.0
                        self.lbl_fastest_asteroid_speed.text = String(format: "%.2f", kilometers_per_hour)

                        //Closest data setup
                        let closest_sorted = asteroids_list.sorted (by:{first,second in
                            let first_close_approach_data = first.value(forKey: "close_approach_data") as? [NSDictionary]
                            let second_close_approach_data = second.value(forKey: "close_approach_data") as? [NSDictionary]

                            let first_miss_distance = first_close_approach_data?.first?.value(forKey: "miss_distance") as? NSDictionary
                            let second_miss_distance = second_close_approach_data?.first?.value(forKey: "miss_distance") as? NSDictionary

                            let first_kilometers = Double(first_miss_distance?.value(forKey: "kilometers") as? String ?? "0") ?? 0.0
                            let second_kilometers = Double(second_miss_distance?.value(forKey: "kilometers") as? String ?? "0") ?? 0.0

                            return first_kilometers > second_kilometers
                        })
                        self.lbl_closest_astroid_id.text = closest_sorted.first?.value(forKey: "id") as? String ?? ""
                        let close_approach_data = closest_sorted.first?.value(forKey: "close_approach_data") as? [NSDictionary]
                        let miss_distance = close_approach_data?.first?.value(forKey: "miss_distance") as? NSDictionary
                        let kilometers = Double(miss_distance?.value(forKey: "kilometers") as? String ?? "0") ?? 0.0
                        self.lbl_closest_astroid_distance.text = "\(String(format: "%.2f", kilometers)) km"

                        //Average size data setup
                        var asteroids_size = Double()
                        asteroids_list.forEach { asteroid in
                            let estimated_diameter = asteroid.value(forKey: "estimated_diameter") as? NSDictionary
                            let kilometers = estimated_diameter?.value(forKey: "kilometers") as? NSDictionary
                            let estimated_diameter_max = kilometers?.value(forKey: "estimated_diameter_max") as? Double ?? 0
                            let estimated_diameter_min = kilometers?.value(forKey: "estimated_diameter_min") as? Double ?? 0
                            let size = estimated_diameter_max - estimated_diameter_min
                            asteroids_size += size
                        }
                        self.lbl_average_size_of_astroid.text = "\(asteroids_size / Double(asteroids_list.count)) km"

                    }else{
                        self.message_popup(message: STRINGS.error_message)
                        self.barChartView.data = nil
                        self.st_data_container.isHidden = true
                    }

                }


            }catch{
                self.message_popup(message: STRINGS.error_message)
            }
        }.resume()
    }
}
