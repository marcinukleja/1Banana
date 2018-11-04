import HealthKit

class HealthKitMethods {
    
    // MARK: Authorization
    
    class func authorizeHealthKit() {
        
        if HKHealthStore.isHealthDataAvailable() { // check if availabe on device
            
            let healthStore = HKHealthStore()
            
            let dietaryEnergyConsumed = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
            
            // Authorization
            healthStore.requestAuthorization(toShare: [dietaryEnergyConsumed], read: [dietaryEnergyConsumed]) { (success, error) in
                if !success {
                    // Error
                }
            }
        }
    }
    
    class func checkAuthorizationSatus() -> HKAuthorizationStatus {
        let healthStore = HKHealthStore()
        let dietaryEnergyConsumed = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        return healthStore.authorizationStatus(for: dietaryEnergyConsumed)
    }
    
    // Save
    
    class func saveDietaryEnergyConsumedSample(dietaryEnergyConsumed: Double, date: Date) {
        
        guard let dietaryEnergyConsumedType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            fatalError("Dietary Energy Type is no longer available in HealthKit")
        }
        
        let dietaryEnergyConsumedQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: dietaryEnergyConsumed)
        let dietaryEnergyConsumedQuantitySample = HKQuantitySample(type: dietaryEnergyConsumedType, quantity: dietaryEnergyConsumedQuantity, start: date, end: date)
        
        HKHealthStore().save(dietaryEnergyConsumedQuantitySample) { (success, error) in
            if let error = error {
                print("• UUID", dietaryEnergyConsumedQuantitySample.uuid)
                print("• Error saving Dietary Energy Consumed sample: \(error.localizedDescription)")
            } else {
                print("• Successfully saved Dietary Energy Consumed sample")
            }
            
        }
        
    }
}
