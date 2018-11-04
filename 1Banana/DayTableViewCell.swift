//  Copyright © 2017 Marcin Ukleja. All rights reserved.

import UIKit

class DayTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var sumOfMealSizesLabel: UILabel!
    @IBOutlet weak var numberOfMealsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dayOfWeekLabel: UILabel!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var chartWidthLayoutConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setupCell(date: Date, energy: Double, meals: Int) {
        
        if let dateIndex = indexFromDate(date: date) {
            if (dateIndex <= -1) && (dateIndex >= -7) {
                self.backgroundColor = UIColor.white
            } else {
                self.backgroundColor = UIColor.groupTableViewBackground
            }
        }
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM"
        dateLabel.text = dateFormatter.string(from: date)
        
        // Day of week
        if Calendar.current.isDateInToday(date as Date) {
            // TODAY
            let relativeFormatter = DateFormatter()
            relativeFormatter.dateStyle = .short
            relativeFormatter.doesRelativeDateFormatting = true
            let relativeString = relativeFormatter.string(from: date)
            dayOfWeekLabel.text = relativeString
        }
        else {
            // NOT TODAY
            let dayOfWeekFormatter = DateFormatter()
            dayOfWeekFormatter.dateFormat = "EEEE"
            dayOfWeekLabel.text = dayOfWeekFormatter.string(from: date)
        }
        
        // Sum of meal sizes
        if energy > 0 {
            sumOfMealSizesLabel.text = String(Helpers.mealSize(fromEnergy: energy)) + "×●"
        } else {
            sumOfMealSizesLabel.text = ""
        }
        
        // Number of meals
        switch meals {
        case 0:
            numberOfMealsLabel.text = ""
        case 1:
            numberOfMealsLabel.text = "1 meal"
        default:
            numberOfMealsLabel.text = String(meals) + " meals"
        }
        
        // Chart
        let chartWidth = (CGFloat(energy) / 100) * 12
        if let maxWidth = chartView.superview?.frame.size.width {
            if chartWidth <= maxWidth {
                // Width
                chartWidthLayoutConstraint.constant = chartWidth
                layoutIfNeeded()
                // Style
                chartView.layer.cornerRadius = chartView.frame.height / 2
            } else {
                // Width
                chartWidthLayoutConstraint.constant = maxWidth
                layoutIfNeeded()
                // Style
                let path = UIBezierPath(roundedRect: chartView.bounds,
                                        byRoundingCorners:[.topLeft, .bottomLeft],
                                        cornerRadii: CGSize(width: 6, height:  6))
                let maskLayer = CAShapeLayer()
                maskLayer.path = path.cgPath
                chartView.layer.cornerRadius = 0
                chartView.layer.mask = maskLayer
            }
        }
    }
    
    // MARK: Helpers
    
    func indexFromDate(date: Date) -> Int? {
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }
}
