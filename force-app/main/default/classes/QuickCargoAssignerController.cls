public with sharing class QuickCargoAssignerController {
    /**
    * @description Fetches a list of Cargo records that are not yet assigned an agent.
    * @return List<Cargo__c> - A list of unassigned Cargo records.
    */

    @AuraEnabled
    public static List<Cargo__c> getUnassignedCargo() {
        try {
            return [
                SELECT Id, Name
                FROM Cargo__c
                WHERE Agent__c = null
                ORDER BY CreatedDate DESC
                LIMIT 200
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Fetches a list of active users who are Agents.
     * @return List<User> - A list of Agent users.
     */

    @AuraEnabled
    public static List<User> getAgents() {
        try {
            return [
                SELECT Id, Name
                FROM User
                WHERE IsActive = true
                AND Profile.Name = 'Freight Agent Profile'
                ORDER BY Name
                LIMIT 200
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Updates a list of Cargo records with a new Agent.
     * @param cargoIds - The list of Cargo record IDs to update.
     * @param agentId - The ID of the User (Agent) to assign.
     * @return String - A success message.
     */

     @AuraEnabled
     public static String assignAgentToCargo(List<Id> cargoIds, Id agentId ) {
        if(cargoIds == null || cargoIds.isEmpty() || agentId == null) {
            throw new AuraHandledException('Please select at least one cargo Item and one Agent');
        }

        try {
            List<Cargo__c> cargoToUpdate = [
                SELECT Id, Name
                FROM Cargo__c
                WHERE Id IN :cargoIds
            ];

            for(Cargo__c cargo : cargoToUpdate) {
                cargo.Agent__c = AgentId;
            }

            update cargoToUpdate;

            return cargoToUpdate.size() + ' Cargo Items have been successfully assigned ';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
     }
}