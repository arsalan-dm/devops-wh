import { LightningElement, api, track } from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';

import { publish, createMessageContext, releaseMessageContext } from 'lightning/messageService';
import REPEATER_SUM from '@salesforce/messageChannel/repeaterSum__c';

const waitForNextLoop = async () => new Promise((resolve) => {
    setTimeout(() => {
        resolve();
    }, 0);
});

let repeaterId = 0;

export default class RepeaterSumInput extends LightningElement {
    @api defaultValue;
    @api sumId = 0;
    @api label;
    messageContext;
    value;
    _repeaterId;

    connectedCallback(){
        this.messageContext = createMessageContext();
        this._repeaterId = repeaterId;
        repeaterId += 1;
        if (this.defaultValue){
            this.value = this.defaultValue;
            waitForNextLoop().then(() => {
                console.log('next loop ');
                console.log(this.value);

                this.sendMessageChannel(false);
            });
        }
    }

    sendMessageChannel(removed){
        publish(this.messageContext, REPEATER_SUM, {
            repeaterId : this._repeaterId,
            sumId : this.sumId,
            value : this.value,
            removed : removed
        });
    }

    disconnectedCallback(){
        this.sendMessageChannel(true);
        releaseMessageContext(this.messageContext);
    }

    handleChange(event){
        this.value = event.detail.value;
        let flowUpdateEvent = new FlowAttributeChangeEvent('defaultValue', event.detail.value);
        this.dispatchEvent(flowUpdateEvent);
        this.sendMessageChannel(false);
    }

}