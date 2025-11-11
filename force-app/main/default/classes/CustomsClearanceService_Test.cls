@isTest
private class CustomsClearanceService_Test {

    // Constants from the class to avoid "magic strings"
    private static final String HAZARDOUS_CATEGORY = 'Hazardous';
    private static final String REJECTED_STATUS = 'Rejected';
    private static final String PENDING_STATUS = 'Pending';
    private static final String STANDARD_CATEGORY = 'Standard';

    @testSetup
    static void setup() {
        // --- 1. Create Base Data (from previous context) ---
        Account sender = new Account(Name = 'Test Sender');
        Contact recipient = new Contact(FirstName = 'Test', LastName = 'Recipient');
        insert new List<SObject>{ sender, recipient };

        // Placeholder data for required fields
        Date testDate = Date.today();
        String method = 'Warp Drive';

        // --- 2. Create Parent Shipments ---
        List<Shipment__c> shipments = new List<Shipment__c>{
            new Shipment__c( // Shipment for Hazardous Cargo
                Sender__c = sender.Id, 
                Recipient__c = recipient.Id, Departure_Date__c = testDate, 
                Shipping_Method__c = method
            ),
            new Shipment__c( // Shipment for Standard Cargo
                Sender__c = sender.Id, 
                Recipient__c = recipient.Id, Departure_Date__c = testDate,
                Shipping_Method__c = method
            ),
            new Shipment__c( // Shipment for Mixed Cargo
                Sender__c = sender.Id, 
                Recipient__c = recipient.Id, Departure_Date__c = testDate,
                Shipping_Method__c = method
            )
        };
        insert shipments;

        // Required fields for Cargo__c
         
       	String description = 'Test cargo Description.';
        
        // --- 3. Create Cargo (Detail Records) ---
        List<Cargo__c> cargos = new List<Cargo__c>{
            // Scenario 1: Hazardous Cargo
            new Cargo__c(
                Name = 'Hazardous Cargo', Category__c = HAZARDOUS_CATEGORY, 
                Weight__c = 1000, Shipment__c = shipments[0].Id, Description__c = description
            ),
            // Scenario 2: Standard Cargo
            new Cargo__c(
                Name = 'Standard Cargo', Category__c = STANDARD_CATEGORY, 
                Weight__c = 500, Shipment__c = shipments[1].Id, Description__c = description
            ),
            // Scenario 3: Mixed Cargo (Standard)
            new Cargo__c(
                Name = 'Mixed Standard', Category__c = STANDARD_CATEGORY, 
                Weight__c = 200, Shipment__c = shipments[2].Id, Description__c = description
            ),
            // Scenario 4: Mixed Cargo (Hazardous)
            new Cargo__c(
                Name = 'Mixed Hazardous', Category__c = HAZARDOUS_CATEGORY, 
                Weight__c = 300, Shipment__c = shipments[2].Id, Description__c = description
            )
        };
        insert cargos;

        // --- 4. Create Customs Documents ---
        List<Customs_Document__c> docs = new List<Customs_Document__c>{
            new Customs_Document__c( // Doc for Hazardous Cargo
                Cargo__c = cargos[0].Id, Clearance_Status__c = PENDING_STATUS, Shipment__c = shipments[0].Id,
                Date_Submitted__c = testDate
            ),
            new Customs_Document__c( // Doc for Standard Cargo
                Cargo__c = cargos[1].Id, Clearance_Status__c = PENDING_STATUS, Shipment__c = shipments[1].Id,
                Date_Submitted__c = testDate
            ),
            new Customs_Document__c( // Doc for Mixed Cargo
                Cargo__c = cargos[2].Id, Clearance_Status__c = PENDING_STATUS, Shipment__c = shipments[2].Id,
                Date_Submitted__c = testDate
            )
        };
        insert docs;

        // --- 5. Create Link Records ---
        List<Customs_Document_Cargo_Link__c> links = new List<Customs_Document_Cargo_Link__c>{
            // Link for Scenario 1
            new Customs_Document_Cargo_Link__c(
                Customs_Document__c = docs[0].Id, Cargo__c = cargos[0].Id
            ),
            // Link for Scenario 2
            new Customs_Document_Cargo_Link__c(
                Customs_Document__c = docs[1].Id, Cargo__c = cargos[1].Id
            ),
            // Links for Scenario 3
            new Customs_Document_Cargo_Link__c( // Standard part
                Customs_Document__c = docs[2].Id, Cargo__c = cargos[2].Id
            ),
            new Customs_Document_Cargo_Link__c( // Hazardous part
                Customs_Document__c = docs[2].Id, Cargo__c = cargos[3].Id
            )
        };
        insert links;
    }

    @isTest
    static void testHazardousRejection() {
        // Arrange: Get the document linked to only hazardous cargo
        Customs_Document__c doc = [SELECT Id, Clearance_Status__c FROM Customs_Document__c WHERE Cargo__r.Name = 'Hazardous Cargo' LIMIT 1];
        Set<Id> docIds = new Set<Id>{ doc.Id };

        // Act
        Test.startTest();
        CustomsClearanceService.validateClearanceStatus(docIds);
        Test.stopTest();

        // Assert: The document status should be updated to Rejected
        Customs_Document__c result = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Id IN :docIds];
        System.assertEquals(REJECTED_STATUS, result.Clearance_Status__c, 
            'Document linked to hazardous cargo should be rejected.');
    }

    @isTest
    static void testStandardNoChange() {
        // Arrange: Get the document linked to only standard cargo
        Customs_Document__c doc = [SELECT Id, Clearance_Status__c FROM Customs_Document__c WHERE Cargo__r.Name = 'Standard Cargo' LIMIT 1];
        Set<Id> docIds = new Set<Id>{ doc.Id };

        // Act
        Test.startTest();
        CustomsClearanceService.validateClearanceStatus(docIds);
        Test.stopTest();

        // Assert: The document status should remain Pending
        Customs_Document__c result = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Id IN :docIds];
        System.assertEquals(PENDING_STATUS, result.Clearance_Status__c, 
            'Document linked to standard cargo should not be rejected.');
    }

    @isTest
    static void testMixedCargoRejection() {
        // Arrange: Get the document linked to both standard and hazardous cargo
        Customs_Document__c doc = [SELECT Id, Clearance_Status__c FROM Customs_Document__c WHERE Cargo__r.Name = 'Mixed Standard' LIMIT 1];
        Set<Id> docIds = new Set<Id>{ doc.Id };

        // Act
        Test.startTest();
        CustomsClearanceService.validateClearanceStatus(docIds);
        Test.stopTest();

        // Assert: The document status should be updated to Rejected
        Customs_Document__c result = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Id IN :docIds];
        System.assertEquals(REJECTED_STATUS, result.Clearance_Status__c, 
            'Document linked to mixed cargo (one hazardous) should be rejected.');
    }

    @isTest
    static void testNullAndEmptyInputs() {
        // Arrange: Get the original counts and statuses
        List<Customs_Document__c> docsBefore = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Clearance_Status__c = :REJECTED_STATUS];
        System.assertEquals(2, docsBefore.size(), 'Setup should have 2 rejected docs.');

        // Act
        Test.startTest();
        CustomsClearanceService.validateClearanceStatus(null);
        CustomsClearanceService.validateClearanceStatus(new Set<Id>());
        Test.stopTest();

        // Assert: No records should have been updated
        List<Customs_Document__c> docsAfter = [SELECT Clearance_Status__c FROM Customs_Document__c WHERE Clearance_Status__c = :REJECTED_STATUS];
        System.assertEquals(2, docsAfter.size(), 'Null or empty inputs should not change the count of rejected docs.');
    }
}