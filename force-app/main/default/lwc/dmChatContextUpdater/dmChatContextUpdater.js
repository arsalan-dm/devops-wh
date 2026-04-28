import { LightningElement, api, track } from 'lwc';

import { publish, createMessageContext, releaseMessageContext } from 'lightning/messageService';
import CHAT_CHILD_CONTEXT from '@salesforce/messageChannel/chatChildContext__c';

const waitForNextLoop = async () => new Promise((resolve) => {
    setTimeout(() => {
        resolve();
    }, 0);
});

export default class DmChatContextUpdater extends LightningElement {
    @api 
    get contextChild(){
        return this._contextChild;
    }
    set contextChild(value){
        this._contextChild = value;
        if(this.subsiquentSends){
            this.sendMessageChannel();
        }
    }

    @api 
    get contextChildName(){
        return this._contextChildName;
    }
    set contextChildName(value){
        this._contextChildName = value;
        if(this.subsiquentSends){
            this.sendMessageChannel();
        }
    }

    messageContext;
    subsiquentSends = false;
    @track _contextChild;
    @track _contextChildName;

    connectedCallback(){
        this.messageContext = createMessageContext();
        waitForNextLoop().then(() => {
            this.sendMessageChannel();
        });
    }

    sendMessageChannel(){
        console.log('got here ' + this.contextChild);
        publish(this.messageContext, CHAT_CHILD_CONTEXT, {
            childContextId : this.contextChild,
            childContextName : this.contextChildName
        });
        this.subsiquentSends = true;
    }

    disconnectedCallback(){
        releaseMessageContext(this.messageContext);
    }
}