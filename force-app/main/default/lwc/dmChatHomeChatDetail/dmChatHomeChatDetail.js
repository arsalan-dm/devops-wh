import { LightningElement, api, wire } from 'lwc';
import { publish, subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import { NavigationMixin } from 'lightning/navigation';
import CHAT_UPDATE_EVENT from '@salesforce/messageChannel/chatUpdateEvent__c';

export default class DmChatHomeChatDetail extends NavigationMixin(LightningElement) {

    // message context for pubsub
    @wire(MessageContext) messageContext;
    subscription;

    @api isFollowing; 
    @api contextParent;
    @api contextParentName;
    @api chatAwardeeName;
    @api contextChild; // Not used in this instance
    @api allowEscalation;
    @api flowApiName;
    @api flowMessageInputVariableName;
    @api flowEscalationRecordOutputApiName;
    @api flowContextParentInputApiName;
    @api maxHeight;

    connectedCallback() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                CHAT_UPDATE_EVENT,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE } // receive from anywhere (even different pages/apps)
            );
        }
        // this.isFollowing = true;
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    // Event handlers
    handleCloseClick(){
        console.log('(dmChatHomeChatDetail) handleCloseClick - Chat Detail Screen this.contextParent = ', this.contextParent);
        const payload = {
            eventType: 'CLOSE_CHAT',
            eventSource: 'dmChatHomeChatDetail', // helps avoid recursion
            chatParentContextId: this.contextParent
        };
        publish(this.messageContext, CHAT_UPDATE_EVENT, payload);        
        console.log('(dmChatHomeChatDetail) handleCloseClick - Published:', payload);
        this.contextParent = null;
    }

    handleMessage(message) {
        
        console.log('(dmChatHomeChatDetail) Received ChatUpdateEvent__c:', message);
        console.log('(dmChatHomeChatDetail) handleMessage called in dmChatHomeChatDetail source = ', message?.eventSource);
        console.log('(dmChatHomeChatDetail) handleMessage called in dmChatHomeChatDetail chatParentContextId = ', message?.chatParentContextId);
        console.log('(dmChatHomeChatDetail) handleMessage called in dmChatHomeChatDetail eventType = ', message?.eventType);
        console.log('(dmChatHomeChatDetail) handleMessage called in dmChatHomeChatDetail chatIsUnfollowed = ', message?.chatIsUnfollowed);
        
        // guard to avoid reacting to your own publish
        if (message?.eventSource == 'dmChatHomeWindow') {
            this.contextParent = message?.chatParentContextId;
            this.contextParentName = message?.chatParentContextName;
            this.chatAwardeeName = message?.chatAwardeeName;
            this.isFollowing = !message?.chatIsUnfollowed;
        }
        
        if (message?.eventSource == 'followComponent') {
            console.log('(dmChatHomeChatDetail) handleMessage need to update follow status = ', message?.eventType);
            if(message?.eventType === 'FOLLOW'){
                this.isFollowing = true;
            }else if(message?.eventType === 'UNFOLLOW'){
                this.isFollowing = false;
            }
        }
        
    }

    handleOpenRecordClick(){
        console.log('(dmChatHomeChatDetail) handleOpenRecordClick called in dmChatHomeChatDetail recordId = ', this.contextParent);    
        if (!this.contextParent) {
            // eslint-disable-next-line no-console
            console.error('No contextParent provided.');
            return;
        }

        const pageRef = {
            type: 'standard__recordPage',
            attributes: {
                recordId: this.contextParent,
                objectApiName: 'FundingAward', 
                actionName: 'view'
            }
        };

        // Generate a URL and open in new tab
        this[NavigationMixin.GenerateUrl](pageRef)
            .then(url => {
                window.open(url, '_blank'); // open in new tab
            })
            .catch(error => {
                console.error('Error generating record URL:', error);
            });
    }

    handleFollowClick(){
        console.log('(dmChatHomeChatDetail) handleFollowClick called in dmChatHomeChatDetail recordId = ', this.contextParent);    
        console.log('(dmChatHomeChatDetail) handleFollowClick called in dmChatHomeChatDetail isFollowing = ', this.isFollowing);
        let followAction = this.isFollowing ? 'UNFOLLOW' : 'FOLLOW';
        console.log('(dmChatHomeChatDetail) handleFollowClick called in dmChatHomeChatDetail followAction = ', followAction);
        
        
        // Publish Chat Update event to notify other components of follow status change
        const payload = {
            eventType: followAction,
            eventSource: 'dmChatHomeChatDetail', // helps avoid recursion
            chatParentContextId: this.contextParent
        };
        publish(this.messageContext, CHAT_UPDATE_EVENT, payload);        
        console.log('(dmChatHomeChatDetail) handleFollowClick - Published:', payload);
        

        // Update local state
        this.isFollowing = !this.isFollowing;

        console.log('(dmChatHomeChatDetail) handleFollowClick - state updated: this.isFollowing  = ', this.isFollowing );

    }

    get chatIsSelected(){
        return this.contextParent != null && this.contextParent != '';
    }

    get chatDetailHeader(){
        return this.contextParentName + ' - ' + this.chatAwardeeName;
    }

    // Used by the single-item iterator
    get contextParentKey() {
        // Ensure it's always an array with one stable primitive key
        return [this.contextParent || 'none'];
    }

}