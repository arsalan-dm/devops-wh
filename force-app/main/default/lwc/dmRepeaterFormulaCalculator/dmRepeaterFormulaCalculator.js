import { LightningElement, api } from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';

export default class DmRepeaterFormulaCalculator extends LightningElement {

    @api 
    get value1(){
        return this._value1;
    }
    set value1(value){
        this._value1 = value;
        this.calculateAndDispatch();
    }

    @api 
    get value2(){
        return this._value2;
    }
    set value2(value){
        this._value2 = value;
        this.calculateAndDispatch();
    }

    @api output;
    @api label; 
    _output;
    _value1;
    _value2;

    connectedCallback(){
       this.calculateAndDispatch();
    }

    calculateAndDispatch(){
        let output = 0;
        this._output = 0;
        if (this._value2){
            output += this._value2;
        }
        if (this._value1){
            output -= this._value1;
        }
        this._output = output;
        console.log(this._output);

        let flowUpdateEvent = new FlowAttributeChangeEvent('output', output);
        this.dispatchEvent(flowUpdateEvent);
    }
}