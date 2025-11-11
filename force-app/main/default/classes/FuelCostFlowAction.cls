public class FuelCostFlowAction {

    // 1. Define the custom input type for bulkification
    public class FuelCostRequest {
        @InvocableVariable(label='Shipment Record ID' description='The ID of the Shipment__c record to calculate the cost for.')
        public Id shipmentId;
    }
    
    // 2. Define the custom output type
    public class FuelCostResult {
        @InvocableVariable(label='Calculated Fuel Cost Value' description='The calculated currency value.')
        public Decimal calculatedCost;
    }

    // 3. The Invocable Method callable by the Flow
    @InvocableMethod(label='Calculate Fuel Cost for Shipment' description='Calculates the Fuel Cost based on Cargo Weight and Distance.')
    public static List<FuelCostResult> calculateFuelCost(List<FuelCostRequest> requests) {
        
        List<FuelCostResult> results = new List<FuelCostResult>();
        Set<Id> shipmentIds = new Set<Id>();
        
        // Collect all IDs passed in by the Flow
        for (FuelCostRequest req : requests) {
            shipmentIds.add(req.shipmentId);
        }

        // Query the necessary fields for the records passed by the Flow
        List<Shipment__c> shipments = [
            SELECT Id, Total_Weight__c, Estimated_Direct_Distance__c
            FROM Shipment__c
            WHERE Id IN :shipmentIds
        ];
        
        // Map results back to match the input order
        Map<Id, Shipment__c> shipmentMap = new Map<Id, Shipment__c>(shipments);
        
        for (FuelCostRequest req : requests) {
            FuelCostResult result = new FuelCostResult();
            Decimal cost = 0;
            Shipment__c sh = shipmentMap.get(req.shipmentId);

            if (sh != null && sh.Total_Weight__c != null && sh.Estimated_Direct_Distance__c != null) {
                // Calculate the cost using your existing formula
                Decimal rawCost = sh.Total_Weight__c * sh.Estimated_Direct_Distance__c * 0.5;
                cost = rawCost.setScale(2);
            }
            
            result.calculatedCost = cost;
            results.add(result);
        }
        
        return results;
    }
}