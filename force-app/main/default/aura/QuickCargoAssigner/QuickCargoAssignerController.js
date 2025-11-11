({
    /**
     * Called when the component is first initialized.
     */

    doInit: function (component, event, helper) {
        // call the helper to load initial data.
        helper.loadInitialData(component);
    },

    /**
     * Called when the user clicks the "Assign Cargo" button.
     */
    handleAssign:  function (component, event, helper) {
        // call the helper to perform the assignment logic.
        helper.assignCargo(component);
    }
    
})