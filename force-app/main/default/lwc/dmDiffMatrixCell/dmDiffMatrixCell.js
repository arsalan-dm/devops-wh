import { LightningElement, api } from 'lwc';

export default class DmDiffMatrixCell extends LightningElement {
    @api oldRecord;
    @api field;
    @api newRecord;
    @api differenceColumn = false;
    @api totalColumn = false;
    @api disabled = false;
    @api readOnly = false;
    @api readOnlySetting = 'existing';

    connectedCallback(){
        console.log(this.field);
    }

    get cellClasses(){
        let neededClasses = 'cell-whole-class whole-cell';
        if (this.totalColumn){
            return neededClasses + ' total-column';
        }
        if(this.differenceColumn){
            neededClasses + ' difference-column';
        }
        return neededClasses;
    }

    get initialValue(){
        if (!this.oldRecord[this.field.name])
            return this.addCurrencySymbol(0);
        return this.addCurrencySymbol(this.addCommasToNumber(this.round(this.oldRecord[this.field.name])));
    }

    get inputValue(){
        if (!this.newRecord[this.field.name])
            return 0;
        return this.newRecord[this.field.name];
    }

    get updatedValue(){
        if (!this.newRecord[this.field.name])
            return this.addCurrencySymbol(0);
        return this.addCurrencySymbol(this.addCommasToNumber(this.round(this.newRecord[this.field.name])));
    }

    get difference(){
        let difference = (this.newRecord[this.field.name] ?? 0) - (this.oldRecord[this.field.name] ?? 0);
        if (this.field.dataType === 'Currency'){
            difference = Math.round(difference, 2);
        }else{
            difference = Math.round(difference);
        }
        return this.addCurrencySymbol(this.addCommasToNumber(difference));
    }

    get differencePercentage(){
        if (!this.newRecord[this.field.name])
            return 0;
        let difference = (this.newRecord[this.field.name] ?? 0) - (this.oldRecord[this.field.name] ?? 0);
        let percentage = (difference/this.oldRecord[this.field.name]);

        return Math.round((percentage)*10000)/100;
    }

    get readOnlyValue(){
        if (this.readOnly){
            if (this.readOnlySetting === 'existing'){
                return this.initialValue;
            }else if (this.readOnlySetting === 'proposed'){
                return this.updatedValue;
            }else if (this.readOnlySetting === 'variance (number)'){
                return this.difference;
            }else if (this.readOnlySetting === 'variance (percentage)'){
                return this.differencePercentage + '%';
            }
        }
        return null;
    }

    handleChange(event){
        let updatedRecord = JSON.parse(JSON.stringify(this.newRecord));
        updatedRecord[this.field.name] = parseFloat(event.target.value);
        this.dispatchEvent(new CustomEvent('valuechanged', { // pass the response to the chat so we use the data that has changed
            detail : {updatedRecord : updatedRecord }
        }));
    }

    addCommasToNumber(number){
        if (isNaN(number)){
            return number;
        }
        return number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","); //https://stackoverflow.com/questions/2901102/how-to-format-a-number-with-commas-as-thousands-separators
    }

    addCurrencySymbol(number){
        if (this.field.dataType === 'Currency'){
            number = '£' + number; 
        }
        return number;
    }

    round(number){
        return Math.round(number*100)/100
    }
}