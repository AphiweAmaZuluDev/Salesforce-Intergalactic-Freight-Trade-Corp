/**
 * Trigger to initiate asynchronous processing of newly inserted/updated Cargo records.
 * Purpose: When a large manifest of Cargo is created or updated, this trigger 
 * immediately passes the IDs to the BulkShipmentProcessor class for asynchronous 
 * work, offloading heavy processing from the immediate transaction.
 */
trigger CargoBulkProcessingTrigger on Cargo__c (after insert, after update) {
    
    // Check the guard. If it's true, we are in a recursive call, so exit.
    if (TriggerHandlerGuard.hasRun) {
        return;
    }

    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        // Set the guard to true *before* calling the future method
        TriggerHandlerGuard.hasRun = true;
        
        // Convert the Trigger.newMap.keySet() (a Set) to a List<Id>
        // to match the method signature in BulkShipmentProcessor.
        List<Id> cargoIds = new List<Id>(Trigger.newMap.keySet());
        
        // Pass the list of IDs to the @future method
        BulkShipmentProcessor.processCargoManifest(cargoIds);
    }
}