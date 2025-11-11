({
    /**
     * Loads both cargo and agent lists from the Apex Controller
     */

    loadInitialData: function (component) {
        // get actions from the Apex controller.
        const fetchCargoAction = component.get("c.getUnassignedCargo");
        const fetchAgentsAction = component.get("c.getAgents");

        // set up callback for cargo.
        fetchCargoAction.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS") {
                const cargoList = response.getReturnValue();
                // Format Data for lightning:dualListbox ({label: 'Name', value: 'Id'})
                const cargoOptions = cargoList.map( cargo => {
                    return {label: cargo.Name, value: cargo.Id}
                })
                component.set("v.cargoOptions", cargoOptions);
            } else {
                this.showToast("Error", "Failed to load cargo: " + response.getError()[0].message, "error");
            }
        });

        // Set up callback for Agents.
        fetchAgentsAction.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                const agentList = response.getReturnValue();
                // Format data for lightning:select ({label: 'Name', value: 'Id'})
                const agentOptions = agentList.map( agent => {
                    return {label: agent.Name, value: agent.Id}
                });
                component.set("v.agentOptions", agentOptions);
            } else {
                this.showToast("Error", "Failed to load agents: " + response.getError()[0].message, "error");
            }
        })

        // enqueue both actions.
                $A.enqueueAction(fetchCargoAction);
                $A.enqueueAction(fetchAgentsAction);
    },

    /**
     * Calls the Apex method to assign the selected agent to the selected cargo.
     */

    assignCargo: function(component) {
        const cargoIds = component.get("v.selectedCargoIds");
        const agentId = component.get("v.selectedAgentId");

        // Validation
        if(!cargoIds || cargoIds.length === 0 || !agentId) {
            this.showToast("Warning", "Please select at least one cargo item and an agent.", "warning");
            return;
        }

        // Get the Apex action.
        const assignAction = component.get("c.assignAgentToCargo");
        
        // Set the parameters.
        assignAction.setParams({
            "cargoIds": cargoIds,
            "agentId": agentId
        });

        // Set up the callback.
        assignAction.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS") {
                this.showToast("Success", response.getReturnValue(), "success");
                // Reload the data to show updated lists.
                this.loadInitialData(component);
                // Clear selected values.
                component.set("v.selectedCargoIds", []);
                component.set("v.selectedAgentId", "");
            } else {
                this.showToast("Error", "Assignment Failed: " + response.getError()[0].message, "error");
            }
        })

        // Enqueue the action.
        $A.enqueueAction(assignAction);
    },

    /**
     * Utility function to show a toast message.
     */

    showToast: function(title, message, type) {
        const toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})