import { LightningElement, api} from 'lwc';
import DmDiffMatrixReadOnlyModal from 'c/dmDiffMatrixReadOnlyModal';

export default class DmDiffMatrixReadOnlyHighlight extends LightningElement {
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

    handleModalExpand(){
        // do the escalation call the escalation flow
        DmDiffMatrixReadOnlyModal.open({
            size : 'full',
            title :this.title,
            records : this.records,
            initialRecords : this.initialRecords,
            fields : this.fields,
            totalRecordId : this.totalRecordId,
            sobjectType : this.sobjectType,
            difference : this.difference,
            useTotalForDifferences : this.useTotalForDifferences,
            orientation : this.orientation,
            startExpanded : true
        }).then((result) => {
        });
    }
}