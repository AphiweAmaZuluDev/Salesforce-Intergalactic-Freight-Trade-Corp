public class FuelCostCalculator {
    private static final Decimal FUEL_COST_PER_UNIT = 0.5;
    public List<ShipmentWrapper> shipmentList { get; set; }
    
    public FuelCostCalculator(ApexPages.StandardController stdController) {
        
        shipmentList = new List<ShipmentWrapper>();
        
        List<Shipment__c> shipments = [
            SELECT Name, Total_Weight__c, Shipping_Method__c,
            Total_Delivery_Time__c, Sender__r.Name, Recipient__r.Name, 
            Fuel_Cost__c, Estimated_Direct_Distance__c, Owner.Name FROM Shipment__c LIMIT 200
        ];
        
        for(Shipment__c sh: shipments) {
            ShipmentWrapper wrapper = new ShipmentWrapper();
            wrapper.shipment = sh;
            
            Decimal cost = 0;
            if (sh.Total_Weight__c != null && sh.Estimated_Direct_Distance__c != null) {
                cost = sh.Total_Weight__c * sh.Estimated_Direct_Distance__c * FUEL_COST_PER_UNIT;
             }
            
            wrapper.FuelCost = cost.setScale(2);
            
            shipmentList.add(wrapper);
        }
    }
    public class ShipmentWrapper {
            public Shipment__c shipment { get; set; }
            public Decimal FuelCost { get; set; }
        }
}