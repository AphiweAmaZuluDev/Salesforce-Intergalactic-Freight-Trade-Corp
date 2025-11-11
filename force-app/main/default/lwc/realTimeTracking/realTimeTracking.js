import { LightningElement, api } from 'lwc';
import getMockShipmentData from '@salesforce/apex/ShipmentTrackerController.getMockShipmentData';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

// Constants for simulation.

const INTERVAL_TIME_MS = 3000 // update every 3 seconds
const PROGRESS_INCREMENT_PER_TICK = 1; // increment progress by 1% every tick

export default class RealTimeTracking extends LightningElement {
    _recordId;
    _shipmentId;
    _processedShipmentId; // Track the Id we've already fetched to prevent reruns.

    progressValue = 0;
    statusText = 'Initialize Tracking';
    intervalId;
    error;

    // Dates for display.
    dispatchDateMs;
    EtaDateMs;
    simulatedCurrentTimeMs;

    // Setter for recordId. 
    @api
    set recordId(value) {
        if(value){
            this._recordId = value;
            this.handleIdChange(); // Call Handler when Id is set.
        }
    }
    get recordId() {
        return this._recordId;
    }

    // setter for shipmentId.
    @api
    set shipmentId(value) {
        if(value){
            this._shipmentId = value;
            this.handleIdChange(); // Call Handler when Id is set.
        }
    }
    get shipmentId() {
        return this._shipmentId;
    }

    // Getter for the HTML template to use.
    get shipmentIdentifier() {
        return this.recordId || this.shipmentId;
    }

    // Central Handler for when ID is changed.
    handleIdChange() {
        const newId = this.shipmentIdentifier;

        // Only fetch if we have a new ID that we haven't processed yet.
        if(newId && newId != this._processedShipmentId){
            this._processedShipmentId = newId;
            this.resetTracker(); // reset for the new ID.
            this.fetchShipmentData();
        }
    }
        
    // Helper to reset the component state. 
    resetTracker() {
        if(this.intervalId){
            clearInterval(this.intervalId);
        }

        this.progressValue = 0;
        this.statusText = 'Initialize Tracking...';
        this.dispatchDateMs = null;
        this.EtaDateMs = null;
        this.error = null;
    }

    async fetchShipmentData() {
        // Guard clause. Although handle Id change should prevent this. 
        if(!this._processedShipmentId) {
            this.statusText = 'A shipment Id is required.';
            return;
        }


        try {
            // Mock API call to Apex.
            const result = await getMockShipmentData({ shipmentId: this._processedShipmentId });

            this.dispatchDateMs = result.dispatchDateMs;
            this.EtaDateMs = result.EtaDateMs;
            this.simulatedCurrentTimeMs = result.simulatedCurrentTimeMs;
            this.statusText = result.status;

            // Start the progress simulation
            this.calculateInitialProgress();
            this.startTrackingSimulation();
        } catch (error) {
            this.error = 'Failed to retrieve shipment data';
            console.error('Apex error: ', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.error,
                    variant: 'error',
                })
            );
        }
    }

    // Date getters for display formatting.
    get dispatchDateDisplay() {
        return this.dispatchDateMs ? new Date(this.dispatchDateMs).toLocaleDateString() : 'N/A';    
    }

    get etaDateDisplay() {
        return this.EtaDateMs ? new Date(this.EtaDateMs).toLocaleDateString() : 'N/A';
    }
    
    calculateInitialProgress() {
        if (!this.dispatchDateMs || !this.EtaDateMs) return;

        const totalDuration = this.EtaDateMs - this.dispatchDateMs;
        // In a real scenario, this would be: Date.now() - this.dispatchDateMs
        const elapsedDuration = this.simulatedCurrentTimeMs - this.dispatchDateMs;

        if (totalDuration > 0) {
            this.progressValue = Math.min(100, Math.round((elapsedDuration / totalDuration) * 100));
        } else {
            this.progressValue = 100;
        }
    }
    
    startTrackingSimulation() {
        // Clear any existing interval to prevent multiple running loops.
        if(this.intervalId){
            clearInterval(this.intervalId);
        }

        // Set interval for Mock real-time updates.
        this.intervalId = setInterval(() => {
            if (this.progressValue < 100){
                // Increment progress and update status.
                this.progressValue = Math.min(100, this.progressValue + PROGRESS_INCREMENT_PER_TICK);

                // Mock status text update based on progress.
                if (this.progressValue < 20) {
                    this.statusText = 'Dispatched';
                } else if (this.progressValue < 80) {
                    this.statusText = 'In Transit';
                } else if(this.progressValue < 100){
                    this.statusText = 'Arrived at Destination Planetary System';
                } else {
                    this.statusText = 'Delivered';
                    clearInterval(this.intervalId); // stop incrementing
                }
            }
        }, INTERVAL_TIME_MS);
    }

    disconnectedCallback() {
        // Clear interval when component is disconnected to prevent memory leaks.
        if(this.intervalId){
            clearInterval(this.intervalId);
        }
    }
}