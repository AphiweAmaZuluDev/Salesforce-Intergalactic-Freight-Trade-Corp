trigger CustomsDocumentCargoLinkTrigger on Customs_Document_Cargo_Link__c (after insert, after update, after delete, after undelete) {
	Set<Id> docIds = new Set<Id>();
    
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Customs_Document_Cargo_Link__c link : Trigger.new) {
            docIds.add(link.Customs_Document__c);
        }
    }
    
    if (Trigger.isDelete) {
        for (Customs_Document_Cargo_Link__c link : Trigger.old) {
            docIds.add(link.Customs_Document__c);
        }
    }

    if (!docIds.isEmpty()) {
        CustomsClearanceService.validateClearanceStatus(docIds);
    }
}