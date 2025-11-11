/**
 * @description Test class for the ShipmentTrackerController.
 * This class verifies the mock data generation logic.
 */
@isTest
private class ShipmentTrackerController_Test {

    /**
     * @description Tests the successful execution of getMockShipmentData.
     * It verifies all calculations and values in the returned map.
     */
    @isTest
    static void testGetMockShipmentData_HappyPath() {
        // Arrange
        String dummyShipmentId = 'a01000000000001AAA';
        
        // --- Replicate the exact calculations from the controller ---
        // We must do this inside the test method to ensure
        // System.today() is the same value.
        DateTime dispatchDate = System.today().addDays(-3);
        DateTime EtaDate = System.today().addDays(7);
        Long expectedDispatchTimeMs = dispatchDate.getTime();
        Long expectedEtaTimeMs = EtaDate.getTime();

        Long totalDurationMs = expectedEtaTimeMs - expectedDispatchTimeMs;
        Long expectedSimulatedTimeMs = expectedDispatchTimeMs + (Long)(totalDurationMs * 0.3);
        // --- End of replicated calculations ---

        // Act
        Test.startTest();
        Map<String, Object> result = ShipmentTrackerController.getMockShipmentData(dummyShipmentId);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The result map should not be null.');
        
        // Verify each value in the map
        System.assertEquals(dummyShipmentId, result.get('shipmentId'), 
            'The shipmentId in the map does not match the input.');
            
        System.assertEquals('In Transit', result.get('status'), 
            'The status should be "In Transit".');
            
        System.assertEquals(expectedDispatchTimeMs, result.get('dispatchDateMs'), 
            'The dispatchDateMs was not calculated correctly.');
            
        System.assertEquals(expectedEtaTimeMs, result.get('EtaDateMs'), 
            'The EtaDateMs was not calculated correctly.');
            
        System.assertEquals(expectedSimulatedTimeMs, result.get('simulatedCurrentTimeMs'), 
            'The simulatedCurrentTimeMs was not calculated correctly.');
    }

    /**
     * @description Tests the behavior when a null shipmentId is passed.
     * The method should still execute and simply put a null in the map.
     */
    @isTest
    static void testGetMockShipmentData_NullId() {
        // Act
        Test.startTest();
        Map<String, Object> result = ShipmentTrackerController.getMockShipmentData(null);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The result map should not be null.');
        System.assertEquals(null, result.get('shipmentId'), 
            'The shipmentId in the map should be null.');
        System.assertEquals('In Transit', result.get('status'), 
            'The status should still be "In Transit" even with a null ID.');
    }
}