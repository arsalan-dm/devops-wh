import { LightningElement, api, track } from 'lwc';

export default class DmDiffMatrixReadOnlyFieldPaginator extends LightningElement {

    @api title;
    @api records = []; // list of sobject records 
    @api initialRecords = [];
    @api fields = ''; // list of string field names
    @api totalRecordId;
    @api recordNames = [];
    @api sobjectType;
    @api difference = false;
    @api useTotalForDifferences = false;
    @api orientation = false;
    @api startExpanded = false;

    @track fieldToDisplay;
    _pages = {};
    _titleArray = [];
    _current = 0;
    _doneloading = false;

    get _title(){
        return this._titleArray[this._current];
    }

    connectedCallback(){
        let fields = JSON.parse(this.fields);
        for(let page of fields){
            this._pages[page.title] = page.fields;
            this._titleArray.push(page.title);
        }
        this._doneloading = true;
        this.fieldToDisplay = this._pages[this._titleArray[this._current]];
    }

    handlePrevious(){
        this._current -= 1;
        if (this._current < 0){
            this._current = this._titleArray.length - 1;
        }
        this.setFieldToDisplay();
    }

    handleNext(){
        this._current += 1;
        if (this._current === this._titleArray.length){
            this._current = 0;
        }
        this.setFieldToDisplay();
    }

    setFieldToDisplay(){
        this.fieldToDisplay = this._pages[this._titleArray[this._current]];
        this.refs.matrix.changeFields(this.fieldToDisplay);
    }
}