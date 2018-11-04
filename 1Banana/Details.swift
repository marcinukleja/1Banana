//  Copyright © 2017 Marcin Ukleja. All rights reserved.

import UIKit
import CoreData

class MealDetailsTableViewController: UITableViewController, UITextFieldDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var mealSizePicker: UIStackView!
    @IBOutlet weak var mealDatePicker: UIDatePicker!
    @IBOutlet weak var mealNotesField: UITextField!
    
    // MARK: - Properties
    
    var mealData: Meal? = nil
    
    var dayIndex: Int? = nil
    
    var mealSize: Int = 6 {
        didSet {
            indicateMealSize()
        }
    }
    
    var isPresentingInAddMode: Bool {
        return presentingViewController is UINavigationController
    }
    
    var unitButtons = [UIButton]() // array for picker buttons
    
    // MARK: - Override functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.default
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        
        // Gesture recognizer for dismissing keyboard
//        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
//        view.addGestureRecognizer(tap)
        
        createButtons()
        
        setupControls()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isPresentingInAddMode {
            return 3 // hides Delete row
        }
        else {
            return 4
        }
    }
    
    // MARK: - My functions
    
    func createButtons() {
        for i in 1...10 {
            
            // Create button
            let unitButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            
            // Constraints
            let widthContraint = NSLayoutConstraint(item: unitButton, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 24)
            let heightContraint = NSLayoutConstraint(item: unitButton, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 24)
            unitButton.addConstraints([widthContraint, heightContraint])
            
            // Style button
            unitButton.backgroundColor = .none
            
            unitButton.setTitle(String(i), for: .normal)
            unitButton.setTitleColor(self.view.tintColor, for: .normal)
            unitButton.titleLabel!.font = UIFont.systemFont(ofSize: 12)
            
            unitButton.layer.cornerRadius = 12
            unitButton.layer.borderWidth = 1
            unitButton.layer.borderColor = self.view.tintColor.cgColor
            
            // Add Action
            unitButton.tag = i
            unitButton.addTarget(self, action: #selector(unitButtonTouched), for: .touchUpInside)
            
            // Add button to view and to array
            mealSizePicker.addArrangedSubview(unitButton)
            unitButtons += [unitButton]
        }
    }
    
    func setupControls() {
        
        if isPresentingInAddMode { // ADD MODE
            // UIApplication.shared.statusBarStyle = .default
            title = "Add Meal"
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(addMeal))
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(backOrCloseView))
            // Size
            mealSize = 6
            // Date (for adding on other that today days)
            if let dayIndex = dayIndex {
                if let viewDate = Helpers.dateFromIndex(index: dayIndex) {
                    if !Calendar.current.isDateInToday(viewDate) {
                        let startOfDay = Calendar.current.startOfDay(for: viewDate)
                        if let baseDate = Calendar.current.date(byAdding: .hour, value: 12, to: startOfDay) {
                            mealDatePicker.date = baseDate // noon
                        }
                    }
                }
            }
        }
        else { // DETAILS MODE
            if let meal = mealData {
                // Size
                mealSize = Helpers.mealSize(fromEnergy: meal.energy)
                // Date
                if let mealDate = meal.date { mealDatePicker.date = mealDate as Date }
                mealDatePicker.addTarget(self, action: #selector(enterEditMode), for: UIControlEvents.valueChanged)
                // Notes
                mealNotesField.text = meal.notes
                mealNotesField.addTarget(self, action: #selector(enterEditMode), for: UIControlEvents.editingChanged)
            }
        }
        
        // ALL MODES
        
        // Date
        mealDatePicker.maximumDate = Date()
        // Notes
        self.mealNotesField.delegate = self
    }
    
    @objc func unitButtonTouched(sender: UIButton) {
        if (sender.tag != mealSize) && (!isPresentingInAddMode) { // If meal size changed in details mode
            enterEditMode()
        }
        mealSize = sender.tag
    }
    
    func indicateMealSize() {
        for (i, button) in unitButtons.enumerated() {
            if i < mealSize {
                button.backgroundColor = self.view.tintColor
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = .none
                button.setTitleColor(self.view.tintColor, for: .normal)
            }
        }
    }
    
    @objc func backOrCloseView() {
        if isPresentingInAddMode { // ADD MODE
            dismiss(animated: true, completion: nil)
            dismissKeyboard()
        } else { // DETAILS MODE
            navigationController!.popViewController(animated: true)
            // No need to dismiss keyboard - it will go away with entire view
        }
    }
    
    @objc func addMeal() { // ADD MODE
        dismissKeyboard()
        dismiss(animated: true, completion: {
            let meal = Meal(context: context)
            meal.energy = Helpers.mealEnergy(fromSize: self.mealSize)
            meal.date = self.mealDatePicker.date as Date?
            meal.notes = self.mealNotesField.text
            ad.saveContext()
        })
    }
    
    @objc func saveMeal() { // DETAILS MODE
        if let meal = mealData {
            meal.energy = Helpers.mealEnergy(fromSize: mealSize)
            meal.date = mealDatePicker.date as Date?
            meal.notes = mealNotesField.text
            ad.saveContext()
            navigationController!.popViewController(animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func dismissKeyboard() {
        mealNotesField.resignFirstResponder()
    }
    
    @objc func enterEditMode(){
        self.navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(backOrCloseView))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveMeal))
    }
    
    // MARK: - Helpers


    
    
    // MARK: - Actions
    
    @IBAction func deleteTouched(_ sender: UIButton) {
        if let mealToBeDeleted = mealData {
            context.delete(mealToBeDeleted)
            ad.saveContext()
            backOrCloseView()
        }
    }
    
}
