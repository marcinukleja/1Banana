//  Copyright © 2017 Marcin Ukleja. All rights reserved.

import UIKit

class DaysPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var visibleListViewController: DayMealsListViewController? { // for easy access
        get {
            return self.viewControllers?[0] as? DayMealsListViewController
        }
    }
    
    var visibleDayIndex: Int? { // for even easier access
        get {
            return visibleListViewController?.dayIndex
        }
    }
    
    //var destinationDayIndex: Int = 0
    var direction: String = "none"
    
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Page View Controller
        self.dataSource = self
        self.delegate = self
        
        // Set starting View Controller
        if let startViewController = self.viewControllerAtIndex(index: 0) {
            let viewControllers = [startViewController]
            self.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)
        }
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        updateMasterView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        visibleListViewController?.deselectRows()
    }
    
    // MARK: - Custom Page View Controller methods
    
    func viewControllerAtIndex(index: Int) -> DayMealsListViewController? {
        if let dayMealsListViewController = storyboard?.instantiateViewController(withIdentifier: "DayMealsListViewController") as? DayMealsListViewController {
            dayMealsListViewController.dayIndex = index
            return dayMealsListViewController
        }
        else {
            return nil
        }
    }
    
    // MARK: - Page View Controller delegate methods
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let previousViewController = previousViewControllers[0] as? DayMealsListViewController, let destinationDayIndex = visibleDayIndex {
                let previousDayIndex = previousViewController.dayIndex
                if destinationDayIndex < previousDayIndex {
                    direction = "reverse"
                } else if destinationDayIndex > previousDayIndex{
                    direction = "forward"
                } else {
                    direction = "none"
                }
                updateMasterView()
            }
        }
    }
    
    // MARK: - Page View Controller data source
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! DayMealsListViewController
        let index = vc.dayIndex - 1
        return self.viewControllerAtIndex(index: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! DayMealsListViewController
        let index = vc.dayIndex + 1
        if index == 1 {
            // was 0 (Today) before increment
            return nil // no next page access from Today
        } else {
            return self.viewControllerAtIndex(index: index)
        }
    }
    
    // MARK: - My methods
    
    // MARK: Self
    
    func jumpToDate(date: Date) {
        let index = indexFromDate(date: date)
        if let index = index, let visibleDayIndex = visibleDayIndex {
            if let destinationViewController = self.viewControllerAtIndex(index: index) {
                let viewControllers = [destinationViewController]
                if index < visibleDayIndex { // destination is earlier than visible date
                    self.setViewControllers(viewControllers, direction: .reverse, animated: true, completion: nil)
                    direction = "reverse"
                } else if index > visibleDayIndex { // destination is later than visible date
                    self.setViewControllers(viewControllers, direction: .forward, animated: true, completion: nil)
                    direction = "forward"
                } else {
                    direction = "none"
                }
                updateMasterView()
            }
        }
    }
    
    // MARK: Master
    
    func updateMasterView() {
        // Toolbar and Add Meal Button appearance and animation
        updateButtons()
        // Navigation Bar Title
        updateTitle()
        // Sum of meal sizes
        updateSumOfMealSizes()
    }
    
    func updateButtons() {
        if let visibleDayIndex = visibleDayIndex , let masterViewController = self.parent as? MasterViewController {
            if visibleDayIndex == 0 {
                masterViewController.nextBarButtonItem.isEnabled = false
                
                // masterViewController.navigationController?.setToolbarHidden(true, animated: true)
                //                masterViewController.view.layoutIfNeeded() // layout all non-animating views before animation
                //                UIView.animate(withDuration: 0.25, animations: {
                //                    masterViewController.addMealButtonBottomConstraint.constant = 12
                //                    masterViewController.view.layoutIfNeeded()
                //                })
            }
            else {
                masterViewController.nextBarButtonItem.isEnabled = true
                
                // masterViewController.navigationController?.setToolbarHidden(false, animated: true)
                //                masterViewController.view.layoutIfNeeded() // layout all non-animating views before animation
                //                UIView.animate(withDuration: 0.25, animations: {
                //                    masterViewController.addMealButtonBottomConstraint.constant = -76
                //                    masterViewController.view.layoutIfNeeded()
                //                })
            }
        }
    }
    
    func updateTitle() {
        if let visibleDayIndex = visibleDayIndex , let masterViewController = self.parent as? MasterViewController {
            if let viewDate = Helpers.dateFromIndex(index: visibleDayIndex) {
                
                let titleString: String
                let subtitleString: String
                
                let screenWidth = UIScreen.main.bounds.width
                
                //let viewDate = dateByAddingDays(value: visibleDayIndex, date: Date())
                
                let isToday = Calendar.current.isDateInToday(viewDate as Date)
                
                // Relative (ex. Today)
                let relativeFormatter = DateFormatter()
                relativeFormatter.dateStyle = .short
                relativeFormatter.doesRelativeDateFormatting = true
                let relativeString = relativeFormatter.string(from: viewDate)
                
                // Short Date (ex. 21 Mar)
                let shortDateFormatter = DateFormatter()
                shortDateFormatter.dateFormat = "d MMM"
                let shortDateString = shortDateFormatter.string(from: viewDate)
                
                // Long Date (ex. 21 March)
                let longDateFormatter = DateFormatter()
                longDateFormatter.dateFormat = "d MMMM"
                let longDateString = longDateFormatter.string(from: viewDate)
                
                // Short Weekday (ex. Sun)
                // let shortWeekdayFormatter = DateFormatter()
                // shortWeekdayFormatter.dateFormat = "EEE"
                // let shortWeekdayString = shortWeekdayFormatter.string(from: viewDate)
                
                // Long Weekday (ex. Sunday)
                let longWeekdayFormatter = DateFormatter()
                longWeekdayFormatter.dateFormat = "EEEE"
                let longWeekdayString = longWeekdayFormatter.string(from: viewDate)
                
                if isToday {
                    // TODAY
                    switch screenWidth {
                    case 0...320: // iPhone SE
                        titleString = shortDateString
                    case 321...375: // iPhone 7
                        titleString = longDateString
                    default: // iPhone 7 Plus
                        titleString = longDateString
                    }
                    subtitleString = relativeString
                    
                } else {
                    // OTHER DAY
                    switch screenWidth {
                    case 0...320: // iPhone SE
                        titleString = shortDateString
                    case 321...375: // iPhone 7
                        titleString = longDateString
                    default: // iPhone 7 Plus
                        titleString = longDateString
                    }
                    subtitleString = longWeekdayString
                }
                
                let backString = shortDateString
                
                masterViewController.updateTitleAndSubtitle(titleString: titleString, subtitleString: subtitleString, backString: backString, direction: direction)
            }
        }
    }
    
    func updateSumOfMealSizes() {
        if let visibleListViewController = visibleListViewController , let masterViewController = self.parent as? MasterViewController {
            //let sumOfMealSizes = visibleListViewController.sumOfMealsEnergyAsSize
            let sumOfMealSizes = Helpers.sumOfMealUnitsInController(controller: visibleListViewController.controller)
            masterViewController.updateSumOfMealSizes(units: sumOfMealSizes, direction: direction)
        }
    }
    
    // MARK: Helpers
    

    
    func indexFromDate(date: Date) -> Int? {
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }
}
