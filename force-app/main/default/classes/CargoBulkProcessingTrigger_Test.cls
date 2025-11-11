/**
 * @description Test class for the CargoBulkProcessingTrigger.
 * This class verifies that the trigger correctly fires on insert and update
 * and successfully invokes the BulkShipmentProcessor @future method.
 */
@isTest
private class CargoBulkProcessingTrigger_Test {

    private static final String STANDARD_CATEGORY = 'Standard';
    private static final String PROCESSED_DESCRIPTION = 'Processed by Future';

    /**
     * @description Creates prerequisite data: Account, Contact, and a parent Shipment.
     */
    @testSetup
    static void setup() {
        // --- 1. Create Base Data ---
        Account sender = new Account(Name = 'Test Sender');
        Contact recipient = new Contact(FirstName = 'Test', LastName = 'Recipient');
        insert new List<SObject>{ sender, recipient };

        // --- 2. Create Parent Shipment ---
        Shipment__c shipment = new Shipment__c(
            Sender__c = sender.Id, 
            Recipient__c = recipient.Id, Departure_Date__c = Date.today(),
            Shipping_Method__c = 'Warp Drive'
        );
        insert shipment;
    }

    /**
     * @description Tests that the trigger fires on 'after insert'
     * and the future method successfully processes the records.
     */
    @isTest
    static void testTriggerOnInsert() {
        // Arrange
        Shipment__c parentShipment = [SELECT Id FROM Shipment__c LIMIT 1];
        
        List<Cargo__c> newCargos = new List<Cargo__c>();
        newCargos.add(new Cargo__c(
            Name = 'Test Cargo 1', 
            Category__c = STANDARD_CATEGORY, 
            Weight__c = 100, 
            Shipment__c = parentShipment.Id,
            Description__c = 'Pending'
        ));
        newCargos.add(new Cargo__c(
            Name = 'Test Cargo 2', 
            Category__c = 'Hazardous', // This one should not be updated
            Weight__c = 200, 
            Shipment__c = parentShipment.Id,
            Description__c = 'Pending'
        ));

        // Act
        Test.startTest();
            // This DML fires the 'after insert' trigger
            insert newCargos;
        // This executes the @future method called by the trigger
        Test.stopTest(); 

        // Assert
        // Verify the future method ran and updated the 'Standard' cargo
        Cargo__c standardCargo = [SELECT Description__c FROM Cargo__c WHERE Name = 'Test Cargo 1'];
        System.assertEquals(PROCESSED_DESCRIPTION, standardCargo.Description__c, 
            'The "Standard" cargo description should have been updated by the future method.');
        
        Cargo__c hazardousCargo = [SELECT Description__c FROM Cargo__c WHERE Name = 'Test Cargo 2'];
        System.assertEquals('Pending', hazardousCargo.Description__c, 
            'The "Hazardous" cargo description should NOT have been updated.');
    }

    /**
     * @description Tests that the trigger fires on 'after update'
     * and the future method successfully processes the records.
     */
    @isTest
    static void testTriggerOnUpdate() {
        // Arrange
        Shipment__c parentShipment = [SELECT Id FROM Shipment__c LIMIT 1];
        
        Cargo__c cargoToUpdate = new Cargo__c(
            Name = 'Test Cargo 3', 
            Category__c = STANDARD_CATEGORY, 
            Weight__c = 300, 
            Shipment__c = parentShipment.Id,
            Description__c = 'Pending'
        );
        // Insert the record *before* starting the test
        insert cargoToUpdate;

        // Act
        Test.startTest();
            // Modify the record to fire the 'after update' trigger
            cargoToUpdate.Weight__c = 350;
            update cargoToUpdate;
        // This executes the @future method called by the trigger
        Test.stopTest();

        // Assert
        // Verify the future method ran and updated the description
        Cargo__c resultCargo = [SELECT Description__c FROM Cargo__c WHERE Id = :cargoToUpdate.Id];
        System.assertEquals(PROCESSED_DESCRIPTION, resultCargo.Description__c, 
            'The cargo description should have been updated by the future method after update.');
    }
}