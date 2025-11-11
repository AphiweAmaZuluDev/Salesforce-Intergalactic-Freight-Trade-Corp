/**
 * @description Test class for the CustomsDocumentGenerator trigger.
 * This class verifies that the trigger correctly creates a new
 * Customs_Document__c record for each new Shipment__c.
 */
@isTest
private class CustomsDocumentGenerator_Test {

    /**
     * @description Creates prerequisite data: Account and Contact
     * for the parent Shipment__c records.
     */
    @testSetup
    static void setup() {
        // --- 1. Create Base Data (Account/Contact) ---
        Account sender = new Account(Name = 'Test Sender');
        Contact recipient = new Contact(FirstName = 'Test', LastName = 'Recipient');
        insert new List<SObject>{ sender, recipient };
    }

    /**
     * @description Tests that the trigger fires on a single 'after insert'
     * and correctly creates one new Customs Document.
     */
    @isTest
    static void testTriggerOnSingleInsert() {
        // Arrange
        Account sender = [SELECT Id FROM Account LIMIT 1];
        Contact recipient = [SELECT Id FROM Contact LIMIT 1];

        // Create the shipment record
        Shipment__c shipment = new Shipment__c(
            // Add all required fields for Shipment__c
            Sender__c = sender.Id, 
            Recipient__c = recipient.Id,
            Departure_Date__c = Date.today(),
            Shipping_Method__c = 'Warp Drive'
        );

        // Act
        Test.startTest();
        // This DML fires the 'after insert' trigger
        insert shipment;
        Test.stopTest();

        // Assert
        // Query for the new Customs Document
        List<Customs_Document__c> newDocs = [
            SELECT Id, Shipment__c 
            FROM Customs_Document__c 
            WHERE Shipment__c = :shipment.Id
        ];

        // Verify one document was created
        System.assertEquals(1, newDocs.size(), 
            'A new customs document should have been created.');
        // Verify it's linked to the correct shipment
        System.assertEquals(shipment.Id, newDocs[0].Shipment__c, 
            'Document should be linked to the new shipment.');
    }

    /**
     * @description Tests that the trigger fires on a bulk 'after insert'
     * and correctly creates multiple new Customs Documents.
     */
    @isTest
    static void testTriggerOnBulkInsert() {
        // Arrange
        Account sender = [SELECT Id FROM Account LIMIT 1];
        Contact recipient = [SELECT Id FROM Contact LIMIT 1];
        
        List<Shipment__c> newShipments = new List<Shipment__c>();
        Integer shipmentCount = 50; // Test with a bulk number

        for(Integer i = 0; i < shipmentCount; i++) {
            newShipments.add(new Shipment__c(
                Sender__c = sender.Id, 
                Recipient__c = recipient.Id,
                Departure_Date__c = Date.today(),
                Shipping_Method__c = 'Warp Drive'
            ));
        }

        // Act
        Test.startTest();
        // This DML fires the 'after insert' trigger
        insert newShipments;
        Test.stopTest();

        // Assert
        // Query for all new Customs Documents
        List<Customs_Document__c> newDocs = [SELECT Id, Shipment__c FROM Customs_Document__c];

        // Verify the correct number of documents were created
        System.assertEquals(shipmentCount, newDocs.size(), 
            shipmentCount + ' new customs documents should have been created.');
    }
}