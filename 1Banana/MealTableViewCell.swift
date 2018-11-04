//  Copyright © 2017 Marcin Ukleja. All rights reserved.

import UIKit

class MealTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var timeSinceEarlierMealLabel: UILabel!
    @IBOutlet weak var mealSizeLabel: UILabel!
    @IBOutlet weak var mealTimeLabel: UILabel!
    @IBOutlet weak var mealNotesLabel: UILabel!
    
    // MARK: - Methods
    
    // MARK: Overrides
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    // MARK: Cell setup
    
    func setupCell(meal: Meal, timeSinceEarlierMeal: TimeInterval?) {
        
        // Meal size
        mealSizeLabel.text = String(repeating: "● ", count: Helpers.mealSize(fromEnergy: meal.energy))
        
        // Meal time
        if let date = meal.date {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            mealTimeLabel.text = formatter.string(from: date as Date)
        }
        
        // Meal notes
        mealNotesLabel.text = meal.notes
        
        // Time since earlier meal
        if let timeInterval = timeSinceEarlierMeal {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.hour, .minute]
            // Convert to string
            let intervalString = formatter.string(from: timeInterval)!
            timeSinceEarlierMealLabel.text = intervalString
        }
        else {
            timeSinceEarlierMealLabel.text = ""
        }
    }
    
}
