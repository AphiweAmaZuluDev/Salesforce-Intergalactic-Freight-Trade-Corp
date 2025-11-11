@isTest
private class FuelCostCalculator_Test {

    /**
     * @description Creates test data (Accounts and Shipments)
     * needed for the test methods.
     */
    @testSetup
    static void setup() {
        // Create lookup records first
        Account sender = new Account(Name = 'Test Sender');
        Contact recipient = new Contact(FirstName = 'Test', LastName = 'Recipient');
        
        insert sender;
        insert recipient;

        List<Shipment__c> shipments = new List<Shipment__c>();
        
        // Placeholder data for required fields
        Date testDate = Date.today();
        String method = 'Hyperspace';

        // Scenario 1: Positive case with all data
        // Expected Cost: 100 * 50 * 0.5 = 2500
        shipments.add(new Shipment__c(
            // Name is an Autonumber, so we don't set it.
            Sender__c = sender.Id,     
            Recipient__c = recipient.Id,
            Departure_Date__c = testDate,
            Shipping_Method__c = method
        ));

        // Scenario 2: Null cargo weight
        // Expected Cost: 0
        shipments.add(new Shipment__c(
            Sender__c = sender.Id,     
            Recipient__c = recipient.Id,
            Departure_Date__c = testDate,
            Shipping_Method__c = method
        ));

        insert shipments;
    }

    /**
     * @description Tests the logic within the FuelCostCalculator constructor.
     * Verifies that the shipmentList is populated and
     * FuelCost is calculated correctly.
     */
    @isTest
    static void testConstructorLogic() {
        // Get a test record to pass to the StandardController.
        Shipment__c testShipment = [
            SELECT Id 
            FROM Shipment__c 
            LIMIT 1
        ];
        ApexPages.StandardController stdController = new ApexPages.StandardController(testShipment);

        Test.startTest();
            // Instantiate the controller, which runs the query
            // and cost calculation logic in its constructor.
            FuelCostCalculator controller = new FuelCostCalculator(stdController);
        Test.stopTest();

        // Assert
        
        // 1. Check if all test shipments were processed
        System.assertEquals(2, controller.shipmentList.size(), 
            'Controller should have processed 2 shipment records.');

        Decimal positiveCost = null;
        Decimal nullWeightCost = null;
        Decimal nullDistanceCost = null;
		
        // Identify shipments based on shipments based on shipment data 
        // because we can't use Name field as it is type autonumber.
        for (FuelCostCalculator.ShipmentWrapper wrapper : controller.shipmentList) {
            Shipment__c s = wrapper.shipment;
            
            // Identify Scenario 1 (Positive)
            if (s.Total_Weight__c == 100) {
                positiveCost = wrapper.FuelCost;
            }
        }

        // Assert the calculated costs for each scenario
        
        // Check that the positive scenario was found and calculated
        System.assertNotEquals(null, positiveCost, 'Positive scenario shipment not found in wrapper list.');
        System.assertEquals(2500.00, positiveCost, 
            'Fuel cost for positive scenario is incorrect.');
        
        // Check that the null weight scenario was found and cost is 0
        System.assertNotEquals(null, nullWeightCost, 'Null weight scenario shipment not found in wrapper list.');
        System.assertEquals(0.00, nullWeightCost, 
            'Fuel cost for null weight should be 0.');
    }
}