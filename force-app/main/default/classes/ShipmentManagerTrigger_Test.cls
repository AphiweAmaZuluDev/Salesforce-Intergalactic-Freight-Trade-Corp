/**
 * @description Test class for the ShipmentManagerTrigger.
 * This class verifies that the trigger correctly prevents the deletion
 * of active shipments while allowing deletion of completed shipments.
 */
@isTest
private class ShipmentManagerTrigger_Test {

    // The error message from the trigger
    private static final String EXPECTED_ERROR = 'Cannot delete active shipment.';

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
     * @description Tests that the trigger PREVENTS deletion of a shipment
     * with a status of 'Pending'.
     */
    @isTest
    static void testDeleteProhibitedStatus() {
        // Arrange
        Account sender = [SELECT Id FROM Account LIMIT 1];
        Contact recipient = [SELECT Id FROM Contact LIMIT 1];

        Shipment__c activeShipment = new Shipment__c(
            Status__c = 'In Transit', // This is not 'Delivered' or 'Failed'
            Sender__c = sender.Id, 
            Recipient__c = recipient.Id, Departure_Date__c = Date.today(),
            Shipping_Method__c = 'Warp Drive'
        );
        insert activeShipment;

        // Act
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        Test.startTest();
        try {
            // This 'delete' fires the 'before delete' trigger
            delete activeShipment;
        } catch (DmlException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        // Assert
        // Verify that the trigger stopped the deletion
        System.assert(exceptionThrown, 'A DmlException should have been thrown.');
        System.assert(exceptionMessage.contains(EXPECTED_ERROR), 
            'The error message should match the trigger validation.');
        
        // Verify the record still exists in the database
        List<Shipment__c> shipments = [SELECT Id FROM Shipment__c WHERE Id = :activeShipment.Id];
        System.assertEquals(1, shipments.size(), 'The active shipment should not have been deleted.');
    }

    /**
     * @description Tests that the trigger ALLOWS deletion of a shipment
     * with a status of 'Delivered'.
     */
    @isTest
    static void testDeleteAllowedStatus_Delivered() {
        // Arrange
        Account sender = [SELECT Id FROM Account LIMIT 1];
        Contact recipient = [SELECT Id FROM Contact LIMIT 1];

        Shipment__c deliveredShipment = new Shipment__c(
            Status__c = 'Delivered', // This is an allowed status
            Sender__c = sender.Id, 
            Recipient__c = recipient.Id, Departure_Date__c = Date.today(),
            Shipping_Method__c = 'Warp Drive'
        );
        insert deliveredShipment;

        // Act
        Test.startTest();
        // This 'delete' fires the 'before delete' trigger
        delete deliveredShipment;
        Test.stopTest();

        // Assert
        // Verify the record was successfully deleted
        List<Shipment__c> shipments = [SELECT Id FROM Shipment__c WHERE Id = :deliveredShipment.Id];
        System.assertEquals(0, shipments.size(), 'The Delivered shipment should have been deleted.');
    }

    /**
     * @description Tests that the trigger ALLOWS deletion of a shipment
     * with a status of 'Failed'.
     */
    @isTest
    static void testDeleteAllowedStatus_Failed() {
        // Arrange
        Account sender = [SELECT Id FROM Account LIMIT 1];
        Contact recipient = [SELECT Id FROM Contact LIMIT 1];

        Shipment__c failedShipment = new Shipment__c(
            Status__c = 'Failed', // This is an allowed status
            Sender__c = sender.Id, 
            Recipient__c = recipient.Id, Departure_Date__c = Date.today(),
            Shipping_Method__c = 'Warp Drive'
        );
        insert failedShipment;

        // Act
        Test.startTest();
        // This 'delete' fires the 'before delete' trigger
        delete failedShipment;
        Test.stopTest();

        // Assert
        // Verify the record was successfully deleted
        List<Shipment__c> shipments = [SELECT Id FROM Shipment__c WHERE Id = :failedShipment.Id];
        System.assertEquals(0, shipments.size(), 'The Failed shipment should have been deleted.');
    }
}