import { LightningElement, api, track } from 'lwc';

export default class DmBulkRecordLoader extends LightningElement {
    @api objectApiName = '';
    @api tabDelimitedText = '';
    @api fieldNames = []; // up to 12 field API names
    @api hasHeaderRow = false;

    @track fieldInputs = [];

    connectedCallback() {
        // Initialize 12 fields for admin input
        this.fieldInputs = [];
        for(let i = 0; i < 12; i++){
            this.fieldInputs.push({
                key: 'f' + i,
                index: i,
                value: this.fieldNames[i] || '',
                label: 'Field ' + (i+1) + ' API Name'
            });
        }
    }

    handleTextChange(event){
        this.tabDelimitedText = event.target.value;
    }

    handleFieldChange(event){
        const index = parseInt(event.target.dataset.index, 10);
        this.fieldInputs[index].value = event.target.value;
        this.fieldNames = this.fieldInputs.map(f => f.value);
    }

    handleObjectChange(event){
        this.objectApiName = event.target.value;
    }

    handleHeaderToggle(event){
        this.hasHeaderRow = event.target.checked;
    }
}