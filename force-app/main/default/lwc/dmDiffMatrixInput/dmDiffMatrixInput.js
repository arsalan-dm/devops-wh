import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent, FlowNavigationFinishEvent, FlowNavigationBackEvent, FlowAttributeChangeEvent} from 'lightning/flowSupport';

const NUMERIC_DATATYPES = ['Currency','Double']

export default class DmDiffMatrixInput extends LightningElement {
    // salesforce handled inputs
    @api availableActions = [];
    // variables
    @api title;
    @api records = []; // list of sobject records 
    @api initialRecords = [];
    @api fields = []; // list of string field names
    @api totalRecordId;
    @api recordNames = [];
    @api sobjectType;
    @api difference = false;
    @api useTotalForDifferences = false;
    @api updatedRecords;
    @api orientation = false;
    @api disableCutOffDate;
    @api disableCutOffField;

    _recordNames = [];
    _fields = [];
    @track _records = [];

    doneLoading = false;

    // lifecycle hooks - in running order

    connectedCallback(){
        let count = 0;
        if (this.fields.length){
            this._fields = [];
            
            for (let field of this.fields){
                this._fields.push({name : field, key : count});
                count += 1;
            }

        }else{
            let propList = []; 
            for (let record of this.records){
                for (let prop in record){
                    if (!propList.includes(prop)){
                        propList.push(prop);
                    }
                }
            }        
            for (let prop of propList){
                this._fields.push({name : prop, key : count});
                count += 1;
            }
        }

        for (let record of this.records){
            let _record = {difference : false, total : false};
            _record.key = record.Id;
            if (record.Id === this.totalRecordId){
                _record.total = true;
            }
            _record.new = JSON.parse(JSON.stringify(record));
            let initialRecord = this.initialRecords?.filter(item => item?.Id === record.Id);
            if (initialRecord?.length){
                _record.old = JSON.parse(JSON.stringify(initialRecord[0]));
            }else{
                _record.old = JSON.parse(JSON.stringify(record));
            }
            this.sortRecordDisabled(_record);
            this._records.push(_record);

        }
        // sort record labels
        this._recordNames = JSON.parse(JSON.stringify(this.recordNames));
        
        if (this._recordNames.length == 0){
            for (let _record of this._records){
                this._recordNames.push({name :_record.old.Name, key : _record.key});
                _record.label = _record.old.Name;
            }
        }else{
            let newRecordNames = [];
            for (let i = 0; i < this._recordNames.length; i += 1){
                newRecordNames.push({name :this._recordNames[i], key : i});
                if (this._records[i]){
                    this._records[i].label = this._recordNames[i];
                }
            }
            this._recordNames = newRecordNames;
        }
        // create the difference record for the fields 
        if (this.difference){
            this._recordNames.push({name :'Summed difference', key : "difference"});
            let totalRecord = this._records.filter(item => item.key === this.totalRecordId);
            if (this.useTotalForDifferences){
                totalRecord[0].disabled = true;
            }else{
                let differenceRecord = JSON.parse(JSON.stringify(totalRecord[0]));

                differenceRecord.difference = true;
                differenceRecord.total = false;
                differenceRecord.key = 'difference';
                differenceRecord.label = 'Summed difference';
                this._records.push(differenceRecord);
            }
        }
    }

    @wire(getObjectInfo, { objectApiName: "$sobjectType" })
    wiredObjectInfo({ error, data }){
        if (data) {
            for (let _field of this._fields){
                if (data.fields[_field.name]){
                    _field.label = data.fields[_field.name].label;
                    _field.dataType = data.fields[_field.name].dataType;
                }
            }
            this.updateDifferenceValues();
            this.doneLoading = true;
        } else if (error) {
            this.error = error;
            this.logError(error, 'Error getting Object Info for ' + this.sobjectType);
        }
    };

    // event handlers

    handleCellValueChange(event){
        let newRecord = event.detail.updatedRecord;
        let changedRecord = this._records.filter(item => item.key === newRecord.Id);
        changedRecord[0].new = JSON.parse(JSON.stringify(newRecord));
        
        this.updateDifferenceValues();
    }

    handleSave(event){
        let updatedRecords = JSON.parse(JSON.stringify(this._records));
        updatedRecords.forEach(getUpdatedRecords);
        if (this.difference && !this.useTotalForDifferences){
            updatedRecords.pop();
        }
        let flowUpdateEvent = new FlowAttributeChangeEvent('updatedRecords', updatedRecords);
        this.dispatchEvent(flowUpdateEvent);

        if (this.availableActions.includes('NEXT')){
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }else if (this.availableActions.includes('FINISH')){
            const navigateNextEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }

    handleReset(event){
        for (let _record of this._records){
            _record.new = JSON.parse(JSON.stringify(_record.old));
        }
        this.updateDifferenceValues();
    }

    handleBack(){
        if(this.availableActions.includes('BACK')){
            const navigateBackEvent = new FlowNavigationBackEvent();
            this.dispatchEvent(navigateBackEvent);
        }
    }

    // reusable methods

    logError(error, subject){
        let toastEvent = new ShowToastEvent({
            title: subject,
            message: error.message,
            variant: 'error', 
            mode : 'sticky'
        }); 
        this.dispatchEvent(toastEvent);
    }

    // this is the hard bit 
    updateDifferenceValues(){
        // old on difference record is the new on the total record 
        // new on the difference record is the summ of the new of all the other records that aren't the total 
        if (this.useTotalForDifferences){
            let breakdownRecords = this._records.filter(item => item.key != this.totalRecordId);
            let totalRecord = this._records.filter(item => item.key === this.totalRecordId);
            for (let field of this._fields){
                if (NUMERIC_DATATYPES.includes(field.dataType)){
                    let fieldValue = 0;
                    for (let breakdownRecord of breakdownRecords){
                        fieldValue += breakdownRecord.new[field.name]
                    }
                    totalRecord[0].new[field.name] = fieldValue;
                }else{
                    totalRecord[0].new[field.name] = 'Field cannot be summed';
                }
            }
        }else{
            let differenceRecord = this._records.filter(item => item.key === 'difference');
            if (!differenceRecord.length){
                return;
            }
            let breakdownRecords = this._records.filter(item => item.key != this.totalRecordId && item.key != 'difference');
            let totalRecord = this._records.filter(item => item.key === this.totalRecordId);
            
            differenceRecord[0].old = JSON.parse(JSON.stringify(totalRecord[0].new));
            for (let field of this._fields){
                if (NUMERIC_DATATYPES.includes(field.dataType)){
                    let fieldValue = 0;
                    for (let breakdownRecord of breakdownRecords){
                        fieldValue += breakdownRecord.new[field.name]
                    }
                    differenceRecord[0].new[field.name] = fieldValue;
                }else{
                    differenceRecord[0].new[field.name] = 'Field cannot be summed';
                }
            }
        }
    }

    sortRecordDisabled(record){
        if (this.disableCutOffDate && record.old[this.disableCutOffField] != null){
            if (this.disableCutOffDate > record.old[this.disableCutOffField]){
                record.disabled = true;
            }
        }
    }
}
// functions 
function convertRecordLabels(item, index, arr){
    arr[index] = {name : item, key : index};
}

function getUpdatedRecords(item, index, arr){
    arr[index] = item.new;
}