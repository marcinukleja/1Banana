//  Copyright © 2017 Marcin Ukleja. All rights reserved.

import UIKit
import CoreData
import UserNotifications

class MasterViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var addMealButton: UIButton!
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var previousBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var nextBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var preferencesBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var sumOfMealSizesLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var controller: NSFetchedResultsController<Meal>!
    
    var daysPageViewController: DaysPageViewController! // for easy access
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observer (for updating UI, renewing app)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        // Navigation Bar
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        // Left space for left icon
//        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
//        space.width = 52.0
//        self.navigationItem.leftBarButtonItems = [space, previousBarButtonItem]
        
        // Header View
        headerView.layer.shadowOffset = CGSize(width: 0, height: CGFloat(1) / UIScreen.main.scale)
        headerView.layer.shadowRadius = 0
        headerView.layer.shadowColor = UIColor(hue: 45/360, saturation: 75/100, brightness: 50/100, alpha: 1.0).cgColor
        headerView.layer.shadowOpacity = 0.5
        
        setupButtons()
        
        fetchTodayData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Status bar (when coming back to view)
        // UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Days Page View Controller
        if segue.identifier == "DaysEmbedSegue"{
            if let destination = segue.destination as? DaysPageViewController  {
                self.daysPageViewController = destination // set variable for easy access
            }
        }
        // Add Meal or Meal Details modal view
        if segue.identifier == "PresentMealDetailsSegue" {
            if let destination = segue.destination as? UINavigationController {
                if let destinationTopViewController = destination.topViewController as? MealDetailsTableViewController  {
                    if let index = daysPageViewController.visibleDayIndex {
                        destinationTopViewController.dayIndex = index
                    }
                }
            }
        }
    }
    
    // MARK: - My methods
    
    func fetchTodayData() {
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        
        // Setup sorting
        let dateSort = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [dateSort]
        
        // Get the current calendar with local time zone
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        
        let dateFrom = calendar.startOfDay(for: Date())
        var components = DateComponents()
        components.day = 1
        components.second = -1
        
        if let dateTo = calendar.date(byAdding: components, to: dateFrom) {
            // Set predicate as date being today's date
            let datePredicate = NSPredicate(format: "(%@ <= date) AND (date < %@)", argumentArray: [dateFrom, dateTo])
            request.predicate = datePredicate
        }
        
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        controller.delegate = self
        self.controller = controller // set global controller
        
        do {
            try controller.performFetch()
        }
        catch {
            let error = error as NSError
            print("\(error)")
        }
    }
    
    func sumOfMealUnits(controller: NSFetchedResultsController<Meal>!) -> Int {
        var sumOfMealEnergy = 0.0
        print("CONTROLLER", controller)
        if let fetchedMeals = controller.fetchedObjects {
            for meal in fetchedMeals {
                sumOfMealEnergy += meal.energy
            }
        }
        return Helpers.mealSize(fromEnergy: sumOfMealEnergy)
    }
    
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Helpers.sumOfTodayMealsUnits = sumOfMealUnits(controller: controller as? NSFetchedResultsController<Meal>)
        Helpers.updateBadge()
    }
    
    
    func presentPreferences() {
        Helpers.updateBadge()
        self.performSegue(withIdentifier: "PresentPreferencesSegue", sender: self)
    }
    
    func setupButtons() {
        
        // Add Meal Button
        addMealButton.layer.cornerRadius = addMealButton.frame.height / 2
        
        
    }
    
    func quickSave(energy: Double) {
        let date = Date()
        // Core Data
        let meal = Meal(context: context)
        meal.energy = energy
        meal.date = date
        ad.saveContext()
        // HealthKit
        HealthKitMethods.saveDietaryEnergyConsumedSample(dietaryEnergyConsumed: energy, date: date)
    }
    
    @objc func willEnterForeground() {
        let interval = 0 - lastActiveDate.timeIntervalSinceNow
        let isToday = Calendar.current.isDateInToday(lastActiveDate)
        if (interval > 300) || (!isToday) {
            renewApp()
        }
    }
    
    func renewApp(){
        UIApplication.shared.keyWindow?.rootViewController = storyboard!.instantiateViewController(withIdentifier: "RootView")
    }
    
    func updateSumOfMealSizes(units: Int, direction: String) {
        // Push direction
        if direction == "reverse" {
            sumOfMealSizesLabel.pushLeftTransition(duration: 0.25)
        } else if direction == "forward" {
            sumOfMealSizesLabel.pushRightTransition(duration: 0.25)
        }
        // String
        var labelString: String = ""
        if units > 0 {
            labelString = String(units) + "×●"
        } else {
            labelString = ""
        }
        // Actual update
        sumOfMealSizesLabel.text = labelString
    }
    
    func updateTitleAndSubtitle(titleString: String, subtitleString: String, backString: String, direction: String) {
        // Actual update
        titleLabel.text = titleString
        subtitleLabel.text = subtitleString
        navigationItem.title = backString
    }
    
    
    // MARK: - Actions
    
    @IBAction func addCustomMealBarButtonTapped(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "PresentMealDetailsSegue", sender: self)
    }
    
    @IBAction func todayBarButtonTapped(_ sender: UIBarButtonItem) {
        daysPageViewController.jumpToDate(date: Date())
    }
    
    @IBAction func nextBarButtonTapped(_ sender: UIBarButtonItem) {
        if let visibleDayIndex = daysPageViewController.visibleDayIndex {
            if let visibleDay = Helpers.dateFromIndex(index: visibleDayIndex) {
                let nextDay =  Calendar.current.date(byAdding: .day, value: 1, to: visibleDay)!
                daysPageViewController.jumpToDate(date: nextDay)
            }
        }
    }
    
    @IBAction func previousBarButtonTapped(_ sender: UIBarButtonItem) {
        if let visibleDayIndex = daysPageViewController.visibleDayIndex {
            if let visibleDay = Helpers.dateFromIndex(index: visibleDayIndex) {
                let previousDay =  Calendar.current.date(byAdding: .day, value: -1, to: visibleDay)!
                daysPageViewController.jumpToDate(date: previousDay)
            }
        }
    }
    
    @IBAction func addMealButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Add Meal", message: "● ≈ 100 kcal ≈ 🍌", preferredStyle: .actionSheet)
        // Define
        let add100 = UIAlertAction(title: "●", style: .default, handler: {
            action in
            self.quickSave(energy: 100)
        })
        let add200 = UIAlertAction(title: "● ●", style: .default, handler: {
            action in
            self.quickSave(energy: 200)
        })
        let add300 = UIAlertAction(title: "● ● ●", style: .default, handler: {
            action in
            self.quickSave(energy: 300)
        })
        let add400 = UIAlertAction(title: "● ● ● ●", style: .default, handler: {
            action in
            self.quickSave(energy: 400)
        })
        let add500 = UIAlertAction(title: "● ● ● ● ●", style: .default, handler: {
            action in
            self.quickSave(energy: 500)
        })
        let addCustom = UIAlertAction(title: "Custom...", style: .default, handler: {
            action in
            self.performSegue(withIdentifier: "PresentMealDetailsSegue", sender: self)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        // Add
        alertController.addAction(add100)
        alertController.addAction(add200)
        alertController.addAction(add300)
        alertController.addAction(add400)
        alertController.addAction(add500)
        alertController.addAction(addCustom)
        alertController.addAction(cancelAction)
        // Present
        self.present(alertController, animated: true, completion: nil)
    }
}
