@isTest
private class QuickCargoAssignerController_Test {

    private static String AGENT_PROFILE_NAME = 'Freight Agent Profile';

    @testSetup
    static void setup() {
        // --- 1. Create Base Data (Shipment/Cargo) ---
        Account sender = new Account(Name = 'Test Sender');
        Contact recipient = new Contact(FirstName = 'Test', LastName = 'Recipient');
        insert new List<SObject>{ sender, recipient };

        Shipment__c shipment = new Shipment__c(
            Sender__c = sender.Id, 
            Recipient__c = recipient.Id, Departure_Date__c = Date.today(), 
            Shipping_Method__c = 'Warp Drive'
        );
        insert shipment;

        // --- 2. Create Profiles and Users ---
        // We need an "Agent" user and a "Standard" user for filtering
        
        // Get the Agent Profile
        Profile agentProfile = [SELECT Id FROM Profile WHERE Name = :AGENT_PROFILE_NAME LIMIT 1];
        
        // Get a profile for a non-agent user
        Profile nonAgentProfile = [SELECT Id FROM Profile WHERE Name != :AGENT_PROFILE_NAME LIMIT 1];

        List<User> usersToInsert = new List<User>();
        
        // User 1: The Active Agent
        User agentUser = new User(
            Alias = 'tstagent', Email = 'testagent@example.com', 
            EmailEncodingKey = 'UTF-8', LastName = 'TestAgent', 
            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', 
            ProfileId = agentProfile.Id, TimeZoneSidKey = 'America/Los_Angeles', 
            Username = 'testagent@example.com.test'
        );
        usersToInsert.add(agentUser);
        
        // User 2: The Non-Agent User (for assigning to a cargo)
        User nonAgentUser = new User(
            Alias = 'tststd', Email = 'teststandard@example.com', 
            EmailEncodingKey = 'UTF-8', LastName = 'TestStandard', 
            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', 
            ProfileId = nonAgentProfile.Id, TimeZoneSidKey = 'America/Los_Angeles', 
            Username = 'teststandard@example.com.test'
        );
        usersToInsert.add(nonAgentUser);
        
        // User 3: The Inactive Agent
        User inactiveAgent = new User(
            Alias = 'tinact', Email = 'testinactive@example.com', 
            EmailEncodingKey = 'UTF-8', LastName = 'TestInactive', 
            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', 
            ProfileId = agentProfile.Id, TimeZoneSidKey = 'America/Los_Angeles', 
            Username = 'testinactive@example.com.test', IsActive = false
        );
        usersToInsert.add(inactiveAgent);
        
        insert usersToInsert;

        // --- 3. Create Cargo Records ---
        List<Cargo__c> cargos = new List<Cargo__c>{
            // Scenario 1: Unassigned Cargo (Agent__c is null)
            new Cargo__c(
                Name = 'Unassigned Cargo', Category__c = 'Standard', 
                Weight__c = 1000, Shipment__c = shipment.Id, 
                Description__c = 'Test cargo'
            ),
            // Scenario 2: Assigned Cargo (Agent__c is not null)
            new Cargo__c(
                Name = 'Assigned Cargo', Category__c = 'Hazardous', 
                Weight__c = 500, Shipment__c = shipment.Id, 
                Description__c = 'Test cargo', Agent__c = nonAgentUser.Id
            )
        };
        insert cargos;
    }

    @isTest
    static void testGetUnassignedCargo() {
        // Act
        Test.startTest();
        List<Cargo__c> results = QuickCargoAssignerController.getUnassignedCargo();
        Test.stopTest();

        // Assert
        System.assertEquals(1, results.size(), 'Should only find one unassigned cargo.');
        System.assertEquals('Unassigned Cargo', results[0].Name, 'Incorrect cargo record returned.');
    }

    @isTest
    static void testGetAgents() {
        // Act
        Test.startTest();
        List<User> results = QuickCargoAssignerController.getAgents();
        Test.stopTest();

        // Assert
        // The query may return the test agent AND the running user.
        // We must assert that our test agent is *in* the list.
        System.assert(results.size() >= 1, 'Should find at least one agent user.');

        Boolean foundTestAgent = false;
        for(User u : results) {
            if(u.Name == 'TestAgent') {
                foundTestAgent = true;
                break;
            }
        }
        System.assert(foundTestAgent, 'Did not find the created test agent in the results.');
    }

    @isTest
    static void testAssignAgentToCargo_Success() {
        // Arrange
        Cargo__c unassignedCargo = [SELECT Id FROM Cargo__c WHERE Name = 'Unassigned Cargo' LIMIT 1];
        User agent = [SELECT Id FROM User WHERE LastName = 'TestAgent' LIMIT 1];
        List<Id> cargoIds = new List<Id>{ unassignedCargo.Id };

        // Act
        Test.startTest();
        String result = QuickCargoAssignerController.assignAgentToCargo(cargoIds, agent.Id);
        Test.stopTest();

        // Assert
        System.assertEquals('1 Cargo Items have been successfully assigned ', result, 'Success message is incorrect.');

        // Verify the database was updated
        Cargo__c updatedCargo = [SELECT Agent__c FROM Cargo__c WHERE Id = :unassignedCargo.Id];
        System.assertEquals(agent.Id, updatedCargo.Agent__c, 'Agent__c field was not updated.');
    }

    @isTest
    static void testAssignAgentToCargo_ValidationErrors() {
        // Arrange
        Cargo__c cargo = [SELECT Id FROM Cargo__c WHERE Name = 'Unassigned Cargo' LIMIT 1];
        User agent = [SELECT Id FROM User WHERE LastName = 'TestAgent' LIMIT 1];
        List<Id> cargoIds = new List<Id>{ cargo.Id };
        
        String expectedMessage = 'Script-thrown exception';
        String exceptionMessage = '';

        // Act
        Test.startTest();

        // Test 1: Null cargoIds
        try {
            QuickCargoAssignerController.assignAgentToCargo(null, agent.Id);
            System.assert(false, 'Exception was not thrown for null cargo list.'); // Failsafe
        } catch (AuraHandledException e) {
            exceptionMessage = e.getMessage();
        }
        System.assertEquals(expectedMessage, exceptionMessage, 'Did not throw correct error for null cargo list.');

        // Test 2: Empty cargoIds
        exceptionMessage = ''; // Reset for next test
        try {
            QuickCargoAssignerController.assignAgentToCargo(new List<Id>(), agent.Id);
            System.assert(false, 'Exception was not thrown for empty cargo list.'); // Failsafe
        } catch (AuraHandledException e) {
            exceptionMessage = e.getMessage();
        }
        System.assertEquals(expectedMessage, exceptionMessage, 'Did not throw correct error for empty cargo list.');

        // Test 3: Null agentId
        exceptionMessage = ''; // Reset for next test
        try {
            QuickCargoAssignerController.assignAgentToCargo(cargoIds, null);
            System.assert(false, 'Exception was not thrown for null agent ID.'); // Failsafe
        } catch (AuraHandledException e) {
            exceptionMessage = e.getMessage();
        }
        System.assertEquals(expectedMessage, exceptionMessage, 'Did not throw correct error for null agent ID.');
        
        Test.stopTest();
    }
}