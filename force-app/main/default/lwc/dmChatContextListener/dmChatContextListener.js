import { LightningElement, wire } from 'lwc';

import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import CHAT_CHILD_CONTEXT from '@salesforce/messageChannel/chatChildContext__c';

function log(message){
    console.log(JSON.stringify(message));
}

export default class DmChatContextListener extends LightningElement {

    @wire(MessageContext) messageContext;

    chatContextChannelSub;

    connectedCallback(){
        this.chatContextChannelSub = subscribe(
            this.messageContext,
            CHAT_CHILD_CONTEXT,
            (message) => this.handleContextUpdate(message)
        );
    }

    handleContextUpdate(message){
        log(message);
        this.dispatchEvent(new CustomEvent('messagereceived', { // pass the response to the chat so we use the data that has changed
            detail : {childContextId : message.childContextId, childContextName : message.childContextName} 
        }));
    }

    disconnectedCallback(){
        unsubscribe(this.spendTotalChannelSub);
    }
}