import Foundation
import CoreData

/// Trip
public class Trip: NSManagedObject {

    @NSManaged public var medicine: String
    @NSManaged public var departure: NSDate
    @NSManaged public var arrival: NSDate
    @NSManaged public var location: String
    @NSManaged public var items: NSSet
    @NSManaged public var reminderTime: NSDate

}