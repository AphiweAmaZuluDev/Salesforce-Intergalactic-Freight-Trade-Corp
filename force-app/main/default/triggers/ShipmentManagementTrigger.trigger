trigger ShipmentManagementTrigger on Shipment__c (before delete) {
    for (Shipment__c s : Trigger.old) {
        if(s.Status__c != 'Delivered' && s.Status__c != 'Failed') {
            s.addError('Cannot delete active shipment. Change the status to "Delivered" or "Failed" first.');
        }
    }
}