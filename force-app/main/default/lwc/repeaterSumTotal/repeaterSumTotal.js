import { LightningElement, track, wire, api } from 'lwc';

// Lightning message service 
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import REPEATER_SUM from '@salesforce/messageChannel/repeaterSum__c';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';

export default class RepeaterSumTotal extends LightningElement {
    @track displayTotal = 0;
    @api total = 0;
    @api sumId = 0;
    @api prefix = '';
    @api suffix = '';
    repeaterValues = [];

    /** Load context for Lightning Messaging Service */
    @wire(MessageContext) messageContext;

    // subscription for the spend total channel
    spendTotalChannelSub;

    connectedCallback(){
        this.spendTotalChannelSub = subscribe(
            this.messageContext,
            REPEATER_SUM,
            (message) => this.handleSpendUpdate(message)
        );
    }

    handleSpendUpdate(message){
        console.log(JSON.stringify(message));
        if (message.sumId === this.sumId){
            let workingTotal = 0;
            this.repeaterValues = this.repeaterValues.filter(item => item.repeaterId !== message.repeaterId);
            if (!message.removed){
                this.repeaterValues.push(message);   
            }
    
            for (let item of this.repeaterValues){
                workingTotal += parseFloat(item.value);
            }
            this.displayTotal = workingTotal.toFixed(2);
            let flowUpdateEvent = new FlowAttributeChangeEvent('total', workingTotal.toFixed(2));
            this.dispatchEvent(flowUpdateEvent);
        }
    }

    disconnectedCallback(){
        unsubscribe(this.spendTotalChannelSub);
    }
}