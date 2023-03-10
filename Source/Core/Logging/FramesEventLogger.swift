import Foundation
import CheckoutEventLoggerKit

protocol FramesEventLogging {
    
    /// Logs the specified event.
    /// - Parameter framesLogEvent: The event to log.
    func log(_ framesLogEvent: FramesLogEvent)
    
    /// Adds a metadata value for the associated key to all subsequent log events.
    func add(metadata: String, forKey key: CheckoutEventLogger.MetadataKey)
    
}

final class FramesEventLogger: FramesEventLogging {

    private let correlationID: String
    private let checkoutEventLogger: CheckoutEventLogging
    private let dateProvider: DateProviding
    
    // MARK: - Init
    
    init(correlationID: String,
         checkoutEventLogger: CheckoutEventLogging,
         dateProvider: DateProviding) {
      self.correlationID = correlationID
      self.checkoutEventLogger = checkoutEventLogger
      self.dateProvider = dateProvider
    }

    // MARK: - FramesEventLogging
    
    func log(_ framesLogEvent: FramesLogEvent) {
        
        let event = Event(
            typeIdentifier: framesLogEvent.typeIdentifier,
            time: dateProvider.currentDate,
            monitoringLevel: framesLogEvent.monitoringLevel,
            properties: framesLogEvent.rawProperties)

        checkoutEventLogger.log(event: event)
    }
    
    func add(metadata: String, forKey key: CheckoutEventLogger.MetadataKey) {
        
        checkoutEventLogger.add(metadata: key.rawValue, value: metadata)
    }
    
}
