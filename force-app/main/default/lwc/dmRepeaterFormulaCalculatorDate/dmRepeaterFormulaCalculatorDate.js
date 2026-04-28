import { LightningElement, api } from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';

export default class DmRepeaterFormulaCalculatorDate extends LightningElement {
    @api 
    get value1(){
        return this._value1;
    }
    set value1(value){
        this._value1 = new Date(value);
        this.calculateAndDispatch();
    }

    @api 
    get value2(){
        return this._value2;
    }
    set value2(value){
        this._value2 = new Date(value);
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
        let diffTime = this._value2 - this.value1;
        let diffdays = Math.floor(diffTime/(1000 * 60 * 60 * 24));

        let output = diffdays;
        this._output = diffdays;
        
        console.log(this._output);

        let flowUpdateEvent = new FlowAttributeChangeEvent('output', output);
        this.dispatchEvent(flowUpdateEvent);
    }
}