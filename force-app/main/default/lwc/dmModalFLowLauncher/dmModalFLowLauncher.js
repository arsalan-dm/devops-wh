import { LightningElement, api } from 'lwc';

export default class LaunchFlowModal extends LightningElement {
    @api recordId;          // recordId from the record page
    @api flowApiName;       // Flow to launch (set in App Builder)
    @api parentObject;    // Object API name (set in App Builder)
    @api buttonLabel = 'Launch Flow'; // Default, can be overridden in App Builder
    @api refreshOnFinish = false; // Setting to refresh the page once the modal closes. Default is false (so off), can be overridden in App Builder

    isModalOpen = false;

    get inputVariables() {
        let vars = [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];

        if (this.parentObject) {
            vars.push({
                name: 'recordObject',
                type: 'String',
                value: this.parentObject
            });
        }

        return vars;
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.closeModal();
            if (this.refreshOnFinish) {
                window.location.reload();
            }
        }
    }
}