//  Copyright © 2017 Marcin Ukleja. All rights reserved.

import UIKit
import CoreData

class DayMealsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var footerTitleLabel: UILabel!
    @IBOutlet weak var footerSubtitleLabel: UILabel!
    
    @IBOutlet weak var footer: UIView!
    
    // MARK: - Properties
    
    var controller: NSFetchedResultsController<Meal>!
    
    var isInsertedAtTheEnd: Bool = false // for scrolling to bottom condition
    
    var parentView: DaysPageViewController? {
        return self.parent as? DaysPageViewController
    }
    
    var dayIndex: Int = 0 {
        didSet {
            fetchData(forDayIndex: dayIndex)
        }
    }
    
    var didLayoutSubviews = false // to prevent multiple fires
    
    var sumOfMealsEnergyAsSize: Int {
        var sumOfMealEnergy = 0.0
        if let fetchedMeals = controller.fetchedObjects {
            for meal in fetchedMeals {
                sumOfMealEnergy += meal.energy
            }
        }
        return Helpers.mealSize(fromEnergy: sumOfMealEnergy)
    }
    
    var timeSinceLastMeal: Double? {
        if let fetchedMeals = controller.fetchedObjects {
            if let lastMealDate = fetchedMeals.last?.date {
                let interval = 0 - (lastMealDate.timeIntervalSinceNow)
                return interval
            }
        }
        return nil
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observer for updating UI
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        // Table setup
        tableView.dataSource = self
        tableView.delegate = self
        
        // Footer setup
        if dayIndex == 0 {
            footer.frame.size.height = 192
            footer.isHidden = false
        }
        else {
            footer.frame.size.height = 68
            footer.isHidden = true // it still takes space
        }
        
        checkEmptyState()
        updateTimeSinceLastMeal()
    }
    
    override func viewDidLayoutSubviews() {
        // Scroll to bottom for Today's view
        if (dayIndex == 0) && (!didLayoutSubviews) {
            scrollToBottom(animated: false)
            didLayoutSubviews = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMealDetailsSegue" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                if let destination = segue.destination as? MealDetailsTableViewController {
                    destination.mealData = controller.object(at: indexPath)
                }
            }
        }
    }
    
    // MARK: - Table functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = controller.sections {
            return sections.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = controller.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MealTableViewCell", for: indexPath) as! MealTableViewCell
        let meal = controller.object(at: indexPath)
        let timeInterval = timeSinceEarlierMeal(referenceIndexPath: indexPath)
        cell.setupCell(meal: meal, timeSinceEarlierMeal: timeInterval)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // MARK: - Fetched Results Controller functions
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Setup completion block to be executed after end of updates
        CATransaction.begin()
        CATransaction.setCompletionBlock( {
            self.tableView.reloadData()
            if (self.isInsertedAtTheEnd) && (self.dayIndex == 0) {
                self.scrollToBottom(animated: true)
                self.isInsertedAtTheEnd = false // reset
            }
        })
        // Start of making changes to Table View
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // End of making changes to Table View
        tableView.endUpdates()
        // Until this moment Table has "old" number of sections (and index paths of course)
        if (tableView) != nil {
            // Trigger completion block defined above
            CATransaction.commit()
        }
        if let parentView = parentView {
            parentView.direction = "none"
            parentView.updateSumOfMealSizes()
        }
        // For all cases update header with time since last meal and check empty state
        updateTimeSinceLastMeal()
        checkEmptyState()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return sectionName
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch (type) {
        case.insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
            break
        case.delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
            break
        case.update:
            // no way to update section
            break
        case.move:
            // no way to move section
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        // Index Paths reffer to controller only. At this point table itself has "old" index paths so it is not possibly to easily refer to table data.
        switch(type) {
        case.insert:
            // MARK: Insert
            if let newIndexPath = newIndexPath {
                insertRowBlock(indexPath: newIndexPath)
                
                // TODO: Rethink concept of detecting insertion at the end
                if let lastMeal = controller.fetchedObjects?.last {
                    if (anObject as AnyObject).isEqual(lastMeal)  {
                        isInsertedAtTheEnd = true
                    }
                } else {
                    isInsertedAtTheEnd = false
                }
            }
            
            // HealthKit sync
            
            break
        case.delete:
            // MARK: Delete
            if let indexPath = indexPath {
                deleteRowBlock(indexPath: indexPath)
            }
            break
        case.update:
            // MARK: Update
            // Update is not triggered while Index Path remain the same which might be a case when new section is inserted/deleted
            if let indexPath = indexPath {
                deleteRowBlock(indexPath: indexPath)
            }
            if let newIndexPath = newIndexPath {
                insertRowBlock(indexPath: newIndexPath)
            }
            break
        case.move:
            // MARK: Move
            if let indexPath = indexPath {
                deleteRowBlock(indexPath: indexPath)
            }
            if let newIndexPath = newIndexPath {
                insertRowBlock(indexPath: newIndexPath)
            }
            break
        }
    }
    
    // MARK: - My functions
    
    // MARK: Fetched Objects
    
    func fetchData(forDayIndex: Int) {
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        
        // Setup sorting
        let dateSort = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [dateSort]
        
        // Get the current calendar with local time zone
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        
        if let viewDate = Helpers.dateFromIndex(index: forDayIndex) {
            
            let dateFrom = calendar.startOfDay(for: viewDate)
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
    }
    
    // MARK: Empty state
    
    func checkEmptyState() {
        if let fetchedObjects = controller.fetchedObjects {
            if fetchedObjects.count == 0 {
                if let emptyView = Bundle.main.loadNibNamed("EmptyList", owner: self, options: nil)?.first as? EmptyAllMealsView {
                    tableView.backgroundView = emptyView
                }
                footer.isHidden = true
            }
            else {
                tableView.backgroundView = nil
                footer.isHidden = false
            }
        }
    }

    
    // MARK: Header
    
    func updateTimeSinceLastMeal() {
        
        if dayIndex == 0 {
            if let interval = timeSinceLastMeal {
                if interval < 60 { // Less than minute
                    updateFooterLabels(string: "Enjoy your meal!")
                }
                else { // For all other typical cases
                    
                    let attributedIntervalString = NSMutableAttributedString()
                    
                    let minutesInterval = (interval.truncatingRemainder(dividingBy: 3600)) / 60 // minutes remaining from stripped hours
                    
                    // Format hours
                    if interval > 3600 {
                        let hourFormatter = DateComponentsFormatter()
                        hourFormatter.unitsStyle = .abbreviated
                        hourFormatter.allowedUnits = [.hour]
                        let hourAttributes = [ NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 32) ]
                        if let hourStringFromInterval = hourFormatter.string(from: interval) {
                            let hourString = NSAttributedString(string: hourStringFromInterval + " ", attributes: hourAttributes)
                            attributedIntervalString.append(hourString)
                        }
                    }
                    // Format minutes
                    if minutesInterval != 0 {
                        let minuteFormatter = DateComponentsFormatter()
                        minuteFormatter.unitsStyle = .abbreviated
                        minuteFormatter.allowedUnits = [.minute]
                        let minuteAttributes = [ NSAttributedStringKey.font: UIFont.systemFont(ofSize: 32, weight: UIFont.Weight.regular) ]
                        if let minuteStringFromInterval = minuteFormatter.string(from: minutesInterval * 60) {
                            let minuteString = NSAttributedString(string: minuteStringFromInterval, attributes: minuteAttributes)
                            attributedIntervalString.append(minuteString)
                        }
                    }
                    
                    footerTitleLabel.attributedText = attributedIntervalString
                    footerSubtitleLabel.text = "since last meal"
                }
            }
        } else {
            // If there are no meals
            updateFooterLabels(string: "")
        }
    }
    
    func updateFooterLabels(string: String) {
        let attributes = [ NSAttributedStringKey.font: UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.regular) ]
        footerTitleLabel.fadeTransition(duration: 0.25)
        footerTitleLabel.attributedText = NSAttributedString(string: string, attributes: attributes)
        footerSubtitleLabel.text = ""
    }
    
    // MARK: Cells
    
    
    func insertRowBlock(indexPath: IndexPath) {
        // Formerly had more actions
        tableView.insertRows(at: [indexPath], with: .fade) // actual insertion happens on tableView.endUpdates()
    }
    
    func deleteRowBlock(indexPath: IndexPath) {
        // Formerly had more actions
        tableView.deleteRows(at: [indexPath], with: .fade) // actual deletion happens on tableView.endUpdates()
    }
    
    func timeSinceEarlierMeal(referenceIndexPath: IndexPath) -> TimeInterval? {
        
        let referenceRow = referenceIndexPath.row
        let referenceSection = referenceIndexPath.section
        
        //var earlierRow: Int
        
        if referenceRow > 0 {
            // If not first row in section
            let earlierRow = referenceRow - 1
            
            let earlierIndexPath = IndexPath(row: earlierRow, section: referenceSection)
            
            let referenceMeal = controller.object(at: referenceIndexPath)
            let earlierMeal = controller.object(at: earlierIndexPath)
            
            if let referenceDate = referenceMeal.date,
                let earlierDate = earlierMeal.date {
                // If both Meal objects have date
                let interval = referenceDate.timeIntervalSince(earlierDate as Date)
                return interval
            }
        }
        return nil
    }
    
    // MARK: Other
    
    // Used by parent controller
    func deselectRows() {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    @objc func willEnterForeground() {
        updateTimeSinceLastMeal()
    }
    
    func scrollToBottom(animated: Bool) {
        tableView.layoutIfNeeded()
        let yOffset = tableView.contentSize.height - tableView.bounds.size.height
        if yOffset > 0 {
            tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: animated)
        }
    }
    
}
