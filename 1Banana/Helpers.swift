import Foundation
import CoreData
import UIKit

class Helpers {
    
    static var isUserBadgePreferenceEnabled: Bool {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "IconBadge") {
            return true
        } else {
            return false
        }
    }
    
    static var sumOfTodayMealsUnits = 0
    
    class func mealSize(fromEnergy: Double) -> Int {
        return Int(round(fromEnergy / 100))
    }
    
    class func mealEnergy(fromSize: Int) -> Double { // currently not in use, probably will be useful for HealtKit integration
        return Double(fromSize * 100)
    }
    
    class func updateBadge() {
        print("• BADGE UPDATED")
            if isUserBadgePreferenceEnabled {
                UIApplication.shared.applicationIconBadgeNumber = Helpers.sumOfTodayMealsUnits
            }
    }
    
    class func sumOfMealUnitsInController(controller: NSFetchedResultsController<Meal>!) -> Int {
        var sumOfMealEnergy = 0.0
        print("CONTROLLER", controller)
        if let fetchedMeals = controller.fetchedObjects {
            for meal in fetchedMeals {
                sumOfMealEnergy += meal.energy
            }
        }
        return mealSize(fromEnergy: sumOfMealEnergy)
    }
    
    class func dateFromIndex(index: Int) -> Date? {
        return Calendar.current.date(byAdding: .day, value: index, to: Date())
    }
    
}
