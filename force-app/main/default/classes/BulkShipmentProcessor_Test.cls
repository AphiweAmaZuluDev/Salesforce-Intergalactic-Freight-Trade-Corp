@isTest
private class BulkShipmentProcessor_Test {

    /**
     * @description Creates test Cargo records for test methods.
     */
    @testSetup
    static void setup() {
        
        // Create lookup records for Shipment object first.
        Account sender = new Account(Name = 'Test Sender');
        Contact recipient = new Contact(FirstName = 'Test', LastName = 'Recipient');
        
        insert sender;
        insert recipient;
        
        // Placeholder data for required fields
        Date testDate = Date.today();
        String method = 'Hyperspace';
        
        // Parent Shipment Record for the test cargo records 
        // because Cargo__c is detail for Shipment__c in 
        // Master-Detail relationship.
        
        Shipment__c shipment = new Shipment__c(
        	// Name is Autonumber so no need to set it.
            Sender__c = sender.Id,     
            Recipient__c = recipient.Id,
            Departure_Date__c = testDate,
            Shipping_Method__c = method
        );
        
        insert shipment;
        
        List<Cargo__c> cargos = new List<Cargo__c>();
        
        // Scenario 1: Standard Cargo
        cargos.add(new Cargo__c(
            Name = 'Standard Cargo',
            Category__c = 'Standard',
            Weight__c = 1000,
            Shipment__c = shipment.Id,
            Description__c = 'Test Cargo'
        ));
        
        // Scenario 2: Non-Standard Cargo
        cargos.add(new Cargo__c(
            Name = 'Non-Standard Cargo',
            Category__c = 'Hazardous', 
            Weight__c = 500,
            Shipment__c = shipment.Id,
            Description__c = 'Test Cargo'
        ));
        
        insert cargos;
    }

    /**
     * @description Tests the successful execution path of the future method
     * with both Standard and Non-Standard cargo.
     */
    @isTest
    static void testSuccessfulProcessing() {
        // Arrange
        List<Id> cargoIds = new List<Id>();
        for(Cargo__c c : [SELECT Id FROM Cargo__c]) {
            cargoIds.add(c.Id);
        }
        
        System.assertEquals(2, cargoIds.size(), 'Test setup should have created 2 cargo records.');

        Test.startTest();
            // Call the future method
            BulkShipmentProcessor.processCargoManifest(cargoIds);
        Test.stopTest();

        // Assert that method ran without any errors.
        List<Cargo__c> results = [SELECT Name, Category__c, Description__c, Shipment__c FROM Cargo__c];
        System.assertEquals(2, results.size(), 'No records should have been created or deleted.');
        // If the 'Perform deep manifest check' logic *did* update a field,
        // we would query and assert that change here.
    }

    /**
     * @description Tests the null and empty list input scenarios
     * to ensure the first validation check works.
     */
    @isTest
    static void testNullOrEmptyList() {
        Test.startTest();
            BulkShipmentProcessor.processCargoManifest(null);
            BulkShipmentProcessor.processCargoManifest(new List<Id>());
        Test.stopTest();

        // No errors should be thrown, and the 2 records from setup should be unaffected.
        System.assertEquals(2, [SELECT count() FROM Cargo__c], 
            'Test setup data should be unaffected.');
    }

    /**
     * @description Tests the scenario where no matching records are found
     * for the provided IDs.
     */
    @isTest
    static void testNoMatchingRecords() {
        // Create a dummy ID that doesn't exist in the database.
        // This simulates an ID from another system or a deleted record.
        Id dummyId = 'a00000000000001AAA'; // Dummy 15-char ID for Cargo__c
        List<Id> cargoIds = new List<Id>{ dummyId };
        
        Test.startTest();
            BulkShipmentProcessor.processCargoManifest(cargoIds);
        Test.stopTest();

        // No errors should be thrown, and the 2 records from setup should be unaffected.
        System.assertEquals(2, [SELECT count() FROM Cargo__c], 
            'Test setup data should be unaffected.');
    }
}