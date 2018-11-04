import UIKit
import UserNotifications

class PreferencesTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var iconBadgeSwitch: UISwitch!
    
    @IBOutlet weak var healthAppIntegrationSwitch: UISwitch!
    
    @IBOutlet weak var iconBadgeFooterView: UIView!
    
    // MARK: - Properties
    
    
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.default
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        
        updateBadgeSwitch()
        
    }
    
    // FIXME: Change status bar
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    // MARK: - My methods
    
    func requestBadgeReset() {
        
        let center = UNUserNotificationCenter.current()
        
        // Set time trigger
        var components = DateComponents()
        components.hour = 0
        components.minute = 0
        components.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        // Set content
        let content = UNMutableNotificationContent()
        content.badge = 0
        // Schedule
        let request = UNNotificationRequest(identifier: "badgeReset", content: content, trigger: trigger)
        center.add(request)
    }
    
    func presentSettingsLink() {
        if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) {
            
            let alertController = UIAlertController (title: "Notifications disabled", message: "To see icon badge you need to enable Notifications in Settings", preferredStyle: .alert)
            
            // Cancel button
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
                action in
                self.iconBadgeSwitch.setOn(false, animated: true)
            })
            
            // Settings button
            let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: {
                action in
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(settingsAction)
            alertController.preferredAction = settingsAction
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func willEnterForeground() {
        updateBadgeSwitch()
    }
    
    func updateBadgeSwitch() {
        
        UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
            if (notificationSettings.badgeSetting == .enabled) && (Helpers.isUserBadgePreferenceEnabled) {
                self.iconBadgeSwitch.setOn(true, animated: true)
                Helpers.updateBadge()
            } else {
                self.iconBadgeSwitch.setOn(false, animated: false)
                // TODO: Slow response
            }
        }
        
    }
    
    // MARK: - Actions
    
    @IBAction func iconBadgeSwitchChanged(_ sender: UISwitch) {
        let defaults = UserDefaults.standard
        
        if sender.isOn {
            defaults.set(true, forKey: "IconBadge")
            
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
                if granted {
                    Helpers.updateBadge()
                    self.requestBadgeReset()
                }
                else {
                    self.presentSettingsLink()
                }
            })
            
        } else {
            defaults.set(false, forKey: "IconBadge")
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    @IBAction func healthAppIntegrationSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            HealthKitMethods.authorizeHealthKit()
            print("• ", HealthKitMethods.checkAuthorizationSatus().rawValue)
        }
    }
    
    
    
    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
