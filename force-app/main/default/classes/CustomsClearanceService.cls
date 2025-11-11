public with sharing class CustomsClearanceService {

    private static final String HAZARDOUS_CATEGORY = 'Hazardous';
    private static final String REJECTED_STATUS = 'Rejected';

    /**
     * Checks all related Cargo records for the provided Customs Document IDs.
     * If any linked Cargo is "Hazardous", the document's Clearance Status is set to "Rejected".
     *
     * @param customsDocumentIds A set of IDs of Customs Document records to validate.
     */
    public static void validateClearanceStatus(Set<Id> customsDocumentIds) {
        if (customsDocumentIds == null || customsDocumentIds.isEmpty()) {
            return;
        }

        // Query all relevant Customs Document Cargo Links and related Cargo Categories.
        List<Customs_Document_Cargo_Link__c> links = [
            SELECT Customs_Document__c, Cargo__r.Category__c
            FROM Customs_Document_Cargo_Link__c
            WHERE Customs_Document__c IN :customsDocumentIds
        ];

        // Determine which Customs Documents must be rejected.
        Map<Id, Customs_Document__c> documentsToReject = new Map<Id, Customs_Document__c>();
        
        for (Customs_Document_Cargo_Link__c link : links) {
            
            Id docId = link.Customs_Document__c;
            
            // Check if the linked Cargo is Hazardous.
            if (link.Cargo__r.Category__c == HAZARDOUS_CATEGORY) {
                
                // If the Cargo is Hazardous, prepare the parent Customs Document for rejection.
                if (!documentsToReject.containsKey(docId)) {
                    documentsToReject.put(docId, new Customs_Document__c(
                        Id = docId,
                        Clearance_Status__c = REJECTED_STATUS 
                    ));
                }
            }
        }

        // Bulk DML update.
        if (!documentsToReject.isEmpty()) {
            Database.update(documentsToReject.values(), false);
        }
    }
}