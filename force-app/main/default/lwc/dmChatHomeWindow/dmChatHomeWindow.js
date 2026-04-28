import { LightningElement, api, wire, track } from 'lwc';
import { publish, subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import CHAT_UPDATE_EVENT from '@salesforce/messageChannel/chatUpdateEvent__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import userId from '@salesforce/user/Id';

import getUserFollowingChats from '@salesforce/apex/ChatHomeController.getUserFollowingChats';
import hasInternalUserPermission from '@salesforce/customPermission/Chat_Internal_User';

import CHAT_HOME_TITLE_LABEL from "@salesforce/label/c.Chat_Home_Title_Label";

export default class DmChatWindowFlow extends LightningElement {
    @api showUnreadCount;
    @api flowApiName;
    @api maxHeight;

    // message context for pubsub
    @wire(MessageContext) messageContext;
    subscription;

    @track chats = [];
    
    doneInitialLoading = false;
    alreadyLoading = false;
    isInternalUser = false;

    // labels
    chatHomeTitleLabel = CHAT_HOME_TITLE_LABEL;

    // Variabls for selected chat record
    selectedChatParentContext; // Id of a funding award
    
    // getters setters

    get chatIsSelected(){
        return this.selectedChatParentContext != null && this.selectedChatParentContext != '';
    }

    get hasChats() {
        // Return false if still loading — prevents placeholder flashing too early
        if (this.doneInitialLoading === false) {
            return false;
        }
        return Array.isArray(this.chats) && this.chats.length > 0;
    }
    
    // lifecycle callbacks
    connectedCallback(){       
        this.isInternalUser = hasInternalUserPermission; // assign here so that we can use it in the html 
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                CHAT_UPDATE_EVENT,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE } // receive from anywhere (even different pages/apps)
            );
        }

        this.fetchUserFollowingChats();
    }

    // Event handlers
    handleRefreshClick(){
        this.chats = [];
        this.fetchUserFollowingChats();
    }
    
    handleBackClick(){
        this.selectedChatParentContext = null;
    }

    handleMessage(message) {

        // guard to avoid reacting to your own publish
        if (message?.eventSource === 'dmChatHomeWindow') {
            return;
        }
        
        const id = message?.chatParentContextId;
        const type = message?.eventType;

        if (!id) return; // nothing to do without an id

        if (message?.eventType === 'CLOSE_CHAT') {
            this.selectedChatParentContext = null;
        }

        // Find the chat record in the current list
        const chat = this.chats?.find(c => c.contextParent === id);
        if (!chat) return;

        if (type === 'UNFOLLOW') {
            chat.isUnfollowed = true;
            return;
        }

        if (type === 'FOLLOW') {
            chat.isUnfollowed = false;
            return;
        }
    }

    handleChatSelect(evt) {
       
        const { chatId, contextParent, contextParentName, contextAwardeeName, isUnfollowed  } = evt.detail || {};
        // if (!chatId || !this.messageContext) return;

        this.selectedChatParentContext = contextParent;
        const payload = {
            eventType: 'SELECT',
            eventSource: 'dmChatHomeWindow', // helps avoid recursion
            chatParentContextName: contextParentName,
            chatParentContextId: contextParent,
            chatAwardeeName: contextAwardeeName,
            chatIsUnfollowed: isUnfollowed
        };

        publish(this.messageContext, CHAT_UPDATE_EVENT, payload);
    }

    // reuseable methods
    fetchUserFollowingChats(){
        getUserFollowingChats()
            .then((result) =>{
                console.log('(dmChatHomeWindow) fetched user following chats: ' + JSON.stringify(result));
                this.chats = result;
                this.doneInitialLoading = true;
            }).catch((error) =>{
                this.logImperativeApexError(error,'Error fetching user following chats');
            });
    }
    
    logImperativeApexError(error, subject){
        let toastEvent = new ShowToastEvent({
            title: subject,
            message: error.message,
            variant: 'error', 
            mode : 'sticky'
        }); 
        this.dispatchEvent(toastEvent);
        console.log(subject);
        console.log(JSON.stringify(error));
    }

}