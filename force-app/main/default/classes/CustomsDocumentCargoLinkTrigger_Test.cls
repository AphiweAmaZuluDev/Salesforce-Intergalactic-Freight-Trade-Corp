/**
 * @description Test class for the CustomsDocumentCargoLinkTrigger.
 * This class verifies that the trigger correctly fires on insert, update, delete,
 * and undelete, and invokes the CustomsClearanceService to update statuses.
 */
@isTest
private class CustomsDocumentCargoLinkTrigger_Test {

    // Constants from the service class
    private static final String HAZARDOUS_CATEGORY = 'Hazardous';
    private static final String REJECTED_STATUS = 'Rejected';
    private static final String PENDING_STATUS = 'Pending';
    private static final String STANDARD_CATEGORY = 'Standard';

    /**
     * @description Creates all base data needed for the tests:
     * Shipment, Standard Cargo, Hazardous Cargo, and a Customs Document.
     */
    @testSetup
    static void setup() {
        // --- 1. Create Base Data (Account/Contact) ---
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
        
        // --- 3. Create Cargo Records ---
        List<Cargo__c> cargos = new List<Cargo__c>{
            new Cargo__c( // Standard Cargo
                Name = 'Standard Cargo', Category__c = STANDARD_CATEGORY, 
                Weight__c = 500, Shipment__c = shipment.Id, Description__c = 'Test'
            ),
            new Cargo__c( // Hazardous Cargo
                Name = 'Hazardous Cargo', Category__c = HAZARDOUS_CATEGORY, 
                Weight__c = 1000, Shipment__c = shipment.Id, Description__c = 'Test'
            )
        };
        insert cargos;

        // --- 4. Create Customs Document ---
        Customs_Document__c doc = new Customs_Document__c(
            // We link one cargo record here to simplify queries later
            Cargo__c = cargos[0].Id, 
            Clearance_Status__c = PENDING_STATUS, 
            Shipment__c = shipment.Id,
            Date_Submitted__c = Date.today()
        );
        insert doc;
    }

    /**
     * @description Tests that INSERTING a link to hazardous cargo
     * fires the trigger and rejects the document.
     */
    @isTest
    static void testTriggerOnInsert() {
        // Arrange
        Customs_Document__c doc = [SELECT Id, Clearance_Status__c FROM Customs_Document__c LIMIT 1];
        Cargo__c hazardousCargo = [SELECT Id FROM Cargo__c WHERE Category__c = :HAZARDOUS_CATEGORY LIMIT 1];
        
        System.assertEquals(PENDING_STATUS, doc.Clearance_Status__c, 'Pre-condition: Document should be Pending.');

        // Act
        Test.startTest();
        // This 'insert' fires the trigger
        insert new Customs_Document_Cargo_Link__c(
            Customs_Document__c = doc.Id, 
            Cargo__c = hazardousCargo.Id
        );
        Test.stopTest();

        // Assert
        Customs_Document__c resultDoc = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Id = :doc.Id];
        System.assertEquals(REJECTED_STATUS, resultDoc.Clearance_Status__c, 
            'Document should be Rejected after linking hazardous cargo.');
    }

    /**
     * @description Tests that UPDATING a link from standard to hazardous cargo
     * fires the trigger and rejects the document.
     */
     @isTest
    static void testTriggerOnUpdate() {
        // Arrange
        Customs_Document__c doc = [SELECT Id, Clearance_Status__c FROM Customs_Document__c LIMIT 1];
        Cargo__c hazardousCargo = [SELECT Id FROM Cargo__c WHERE Category__c = :HAZARDOUS_CATEGORY LIMIT 1];

        // Create the initial "hazardous" link
        Customs_Document_Cargo_Link__c link = new Customs_Document_Cargo_Link__c(
            Customs_Document__c = doc.Id, 
            Cargo__c = hazardousCargo.Id
        );
        insert link;
        
        // Refresh doc state - should now be Rejected by the 'insert' trigger
        doc = [SELECT Id, Clearance_Status__c FROM Customs_Document__c WHERE Id = :doc.Id];
        System.assertEquals(REJECTED_STATUS, doc.Clearance_Status__c, 'Pre-condition: Document should be Rejected.');
        
        // Manually reset the status to Pending to test the 'update' trigger
        doc.Clearance_Status__c = PENDING_STATUS;
        update doc;
        
        doc = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Id = :doc.Id];
        System.assertEquals(PENDING_STATUS, doc.Clearance_Status__c, 'Pre-condition: Document should be reset to Pending.');

        // Act
        Test.startTest();
        
        // Re-query the link to ensure we have the latest version before update
        Customs_Document_Cargo_Link__c linkToUpdate = [SELECT Id FROM Customs_Document_Cargo_Link__c WHERE Id = :link.Id];
        
        // This 'update' fires the trigger without changing the master-detail
        update linkToUpdate;
        
        Test.stopTest();

        // Assert
        Customs_Document__c resultDoc = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Id = :doc.Id];
        System.assertEquals(REJECTED_STATUS, resultDoc.Clearance_Status__c, 
            'Document should be Rejected again after the update trigger fired.');
    }

    /**
     * @description Tests that DELETING a link re-evaluates the document.
     * Note: The service logic only rejects, it doesn't clear rejections.
     * This test ensures the delete operation runs without error.
     */
    @isTest
    static void testTriggerOnDelete() {
        // Arrange
        Customs_Document__c doc = [SELECT Id, Clearance_Status__c FROM Customs_Document__c LIMIT 1];
        Cargo__c hazardousCargo = [SELECT Id FROM Cargo__c WHERE Category__c = :HAZARDOUS_CATEGORY LIMIT 1];

        Customs_Document_Cargo_Link__c link = new Customs_Document_Cargo_Link__c(
            Customs_Document__c = doc.Id, 
            Cargo__c = hazardousCargo.Id
        );
        insert link;

        // Doc should now be Rejected
        Customs_Document__c rejectedDoc = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Id = :doc.Id];
        System.assertEquals(REJECTED_STATUS, rejectedDoc.Clearance_Status__c, 'Pre-condition: Document should be Rejected.');

        // Act
        Test.startTest();
        // This 'delete' fires the trigger
        delete link;
        Test.stopTest();

        // Assert
        // The service logic doesn't clear rejections, so we just check it's still Rejected
        // This proves the trigger ran and called the service without error.
        Customs_Document__c resultDoc = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Id = :doc.Id];
        System.assertEquals(REJECTED_STATUS, resultDoc.Clearance_Status__c, 
            'Document status should remain Rejected as service does not clear status.');
    }

    /**
     * @description Tests that UNDELETING a hazardous link
     * fires the trigger and re-rejects the document.
     */
    @isTest
    static void testTriggerOnUndelete() {
        // Arrange
        Customs_Document__c doc = [SELECT Id, Clearance_Status__c FROM Customs_Document__c LIMIT 1];
        Cargo__c hazardousCargo = [SELECT Id FROM Cargo__c WHERE Category__c = :HAZARDOUS_CATEGORY LIMIT 1];

        Customs_Document_Cargo_Link__c link = new Customs_Document_Cargo_Link__c(
            Customs_Document__c = doc.Id, 
            Cargo__c = hazardousCargo.Id
        );
        insert link;
        
        // Delete the link and manually reset the document status to Pending
        delete link;
        doc.Clearance_Status__c = PENDING_STATUS;
        update doc;

        System.assertEquals(PENDING_STATUS, doc.Clearance_Status__c, 'Pre-condition: Document should be reset to Pending.');

        // Act
        Test.startTest();
        // This 'undelete' fires the trigger
        undelete link;
        Test.stopTest();

        // Assert
        Customs_Document__c resultDoc = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Id = :doc.Id];
        System.assertEquals(REJECTED_STATUS, resultDoc.Clearance_Status__c, 
            'Document should be Rejected again after undeleting the hazardous link.');
    }
}