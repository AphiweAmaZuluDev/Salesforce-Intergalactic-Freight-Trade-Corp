public without sharing class BulkShipmentProcessor {

    private static final String STANDARD_CATEGORY = 'Standard';
    private static final String PROCESSED_DESCRIPTION = 'Processed by Future';

    @future
    public static void processCargoManifest(List<Id> cargoIds) {
        
        // Validate the input list
        if (cargoIds == null || cargoIds.isEmpty()) {
            System.debug('BulkShipmentProcessor: No Cargo IDs provided for processing.');
            return;
        }

        // Query the necessary Cargo records
        List<Cargo__c> cargosToProcess = [
            SELECT Id, Name, Category__c, Weight__c, Description__c 
            FROM Cargo__c 
            WHERE Id IN :cargoIds
        ];

        if (cargosToProcess.isEmpty()) {
            System.debug('BulkShipmentProcessor: No matching Cargo records found for the provided IDs.');
            return;
        }
        
        // List to hold updates if we modify the Cargo records
        List<Cargo__c> cargosToUpdate = new List<Cargo__c>();
        
        // Implement the complex update logic or external callout
        
        System.debug('Processing ' + cargosToProcess.size() + ' Cargo records asynchronously.');
        
        for (Cargo__c cargo : cargosToProcess) {
            
            // Simple example of logic that might hit CPU limits if done synchronously.
            // This is just a placeholder for the actual logic.
            // Replace this with the actual logic.
            if (cargo.Category__c == STANDARD_CATEGORY && cargo.Description__c != PROCESSED_DESCRIPTION) {
                
                // Update the description
                cargo.Description__c = PROCESSED_DESCRIPTION;
                
                // Add the modified cargo to the list for DML
                cargosToUpdate.add(cargo);

                System.debug('Performing deep manifest check for Cargo ID: ' + cargo.Id);
            }
        }

        // Perform final DML operation
        if (!cargosToUpdate.isEmpty()) {
            try {
                update cargosToUpdate;
                System.debug('Successfully updated ' + cargosToUpdate.size() + ' Cargo records.');
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error during bulk update of Cargo records: ' + e.getMessage());
            }
        }
    }
}