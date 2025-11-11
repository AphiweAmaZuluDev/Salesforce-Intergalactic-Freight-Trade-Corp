public with sharing class ShipmentTrackerController {
    /**
     * @description Mock API method to get Shipment status data. 
     * In a real-world scenario, this might call out to an external API 
     * or query a real object, but here it returns hardcoded mock data.
     * @param shipmentId The ID of the Shipment record.
     * @return A map containing mock shipment data.
     */

     @AuraEnabled
     public static Map<String, Object> getMockShipmentData(String shipmentId){
        try {
            // Mock Dates: Convert to milliseconds for easy JS calculation
            // Assuming a duration of 10 days for tracking simulation
            DateTime dispatchDate = System.today().addDays(-3);
            DateTime EtaDate = System.today().addDays(7);

            // Mock current progress time somewhere between dispatch and ETC
            // Start current progress a little after the dispatch date
            Long dispatchTimeMs = dispatchDate.getTime();
            Long EtaTimeMs = EtaDate.getTime();

            // Simulate a "current time" that's 30% of the way through the total duration (10 days total)
            Long totalDurationMs = EtaTimeMs - dispatchTimeMs;
            Long simulatedCurrentTimeMs = dispatchTimeMs + (Long)(totalDurationMs * 0.3);

            // --- Mock Data Structure ---
            Map<String, Object> shipmentData = new Map<String, Object>();
            shipmentData.put('shipmentId', shipmentId);
            shipmentData.put('status', 'In Transit');
            shipmentData.put('dispatchDateMs', dispatchTimeMs);
            shipmentData.put('EtaDateMs', EtaTimeMs);
            shipmentData.put('simulatedCurrentTimeMs', simulatedCurrentTimeMs); // Starting point for mock progress.
            
            return shipmentData;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
     }
}