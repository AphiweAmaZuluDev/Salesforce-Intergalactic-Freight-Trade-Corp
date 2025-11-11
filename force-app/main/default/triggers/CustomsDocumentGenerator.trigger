trigger CustomsDocumentGenerator on Shipment__c (after insert) {
    // List to hold all new Customs Document records we are creating
	List<Customs_Document__c> newDocuments = new List<Customs_Document__c>();
    
    for(Shipment__c newShipment: Trigger.new) {
        // Create new customs document.
        Customs_Document__c doc = new Customs_Document__c();
        
        doc.Shipment__c = newShipment.Id;
        
        newDocuments.add(doc);
    }
    
    // Bulk DML operation.
    if(!newDocuments.isEmpty()) {
        try{
            insert newDocuments;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Error inserting Customs Documents: ' + e.getMessage());
        }
    }
}