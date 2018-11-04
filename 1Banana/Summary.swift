//  Copyright © 2017 Marcin Ukleja. All rights reserved.

import UIKit
import CoreData

class SummaryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var averageSizesLabel: UILabel!
    @IBOutlet weak var averageMealsLabel: UILabel!
    
    var controller: NSFetchedResultsController<Meal>!
    
    var loggedDays = [Date : Dictionary<String, Any>]() // stores date and data for each logged day
    
    var allDays = [Date]() // stores all days from first log till today
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchData()
        
        // UIApplication.shared.statusBarStyle = .default
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.default
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        scrollToBottom(animated: false)
    }
    
    // MARK: Table methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allDays.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayTableViewCell", for: indexPath) as! DayTableViewCell
        let index = indexPath.row
        let date = allDays[index]
        let energy = (loggedDays[date]?["energy"] as? Double) ?? 0.0
        let meals = (loggedDays[date]?["meals"] as? Int) ?? 0
        cell.setupCell(date: date, energy: energy, meals: meals)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let date = allDays[index]
        if let presentingVC = self.presentingViewController as? UINavigationController {
            if let masterView = presentingVC.topViewController as? MasterViewController {
                dismiss(animated: true, completion: {
                    masterView.daysPageViewController.jumpToDate(date: date)
                })
            }
        }
    }
    
    // MARK: - My methods
    
    func fetchData() {
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        
        // Setup sorting
        let dateSort = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [dateSort]
        
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        controller.delegate = self
        self.controller = controller // set global controller
        
        do {
            try controller.performFetch()
            createAllDaysArray()
            translateData()
            updateFooter()
            checkEmptyState()
        }
        catch {
            let error = error as NSError
            print("\(error)")
        }
    }
    
    func updateFooter() {
        
        var sumOfEnergy = 0.0
        var sumOfMeals = 0.0
        var mealsCount = 0.0
        
        var i : Int = 1 // to track number of for loops
        
        for date in allDays.reversed().dropFirst() {
            if  i <= 7 {
                i += 1
                if let dayEnergy = loggedDays[date]?["energy"] as? Double, let dayMeals = loggedDays[date]?["meals"] as? Int {
                    sumOfEnergy += dayEnergy
                    sumOfMeals += Double(dayMeals)
                    mealsCount += 1
                }
            } else {
                break // break at 8th loop
            }
        }
        
        if mealsCount > 0 {
            let averageSizes = (sumOfEnergy / 100) / mealsCount
            let averageMeals = sumOfMeals / mealsCount
            averageSizesLabel.text = String(format: "%.1f", averageSizes) + "×●"
            averageMealsLabel.text = String(format: "%.1f", averageMeals) + " meals"
        } else {
            updateFooterMessage(string: "Tomorrow you will find\nsome stats here")
        }
    }
    
    func updateFooterMessage(string: String) {
        summaryLabel.text = string
        averageSizesLabel.text = ""
        averageMealsLabel.text = ""
    }
    
    func createAllDaysArray() {
        if let fetchedObjects = controller.fetchedObjects {
            if fetchedObjects.count > 0 {
                let firstMeal = controller.object(at: IndexPath(row: 0, section: 0))
                let firstMealDate = firstMeal.date! as Date
                var day = Calendar.current.startOfDay(for: firstMealDate)
                let today = Date()
                while day < today {
                    allDays.append(day)
                    day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
                }
            }
        }
    }
    
    func translateData() {
        if let fetchedObjects = controller.fetchedObjects {
            for i in 0..<fetchedObjects.count {
                let meal = controller.object(at: IndexPath(row: i, section: 0))
                var dayData: Dictionary<String, Any> = ["energy": 0, "meals": 0]
                if let date = meal.date as Date? {
                    let startOfDay = Calendar.current.startOfDay(for: date)
                    if let dataForDay = loggedDays[startOfDay] { // day already exists
                        let dayEnergy = dataForDay["energy"] as! Double
                        let dayMeals = dataForDay["meals"] as! Int
                        dayData = ["energy": dayEnergy + meal.energy, "meals": dayMeals + 1] as [String : Any]
                    } else { // First meal on date
                        dayData = ["energy": meal.energy, "meals": 1]
                    }
                    loggedDays[startOfDay] = dayData
                }
            }
        }
    }
    
    func checkEmptyState() {
        if controller.fetchedObjects?.count == 0 {
            if let emptyView = Bundle.main.loadNibNamed("EmptySummary", owner: self, options: nil)?.first as? EmptySummary {
                tableView.backgroundView = emptyView
                updateFooterMessage(string: "")
            }
            footerView.isHidden = true
        } else {
            tableView.backgroundView = nil
            footerView.isHidden = false
        }
    }
    
    func scrollToBottom(animated: Bool) {
        tableView.layoutIfNeeded()
        let yOffset = tableView.contentSize.height - tableView.bounds.size.height
        if yOffset > 0 {
            tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: animated)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
