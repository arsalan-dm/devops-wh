import {  api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class DmDiffMatrixReadOnlyModal extends LightningModal {
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
    @api orientation = false;
    @api startExpanded = false;
    
}