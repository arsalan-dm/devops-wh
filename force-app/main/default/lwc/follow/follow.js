import { LightningElement, api , wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';
import CHAT_UPDATE_EVENT from '@salesforce/messageChannel/chatUpdateEvent__c';
import createFollow from '@salesforce/apex/FollowController.createFollow';
import currentUserFollows from '@salesforce/apex/FollowController.currentUserFollows';
import deleteFollow from '@salesforce/apex/FollowController.deleteFollow';

import LABEL_WHEN_HOVERING from "@salesforce/label/c.Chat_Follow_When_Hovering";
import LABEL_WHEN_OFF from "@salesforce/label/c.Chat_Follow_When_Off";
import LABEL_WHEN_ON from "@salesforce/label/c.Chat_Follow_When_On";
import LABEL_UNFOLLOW_MESSAGE from "@salesforce/label/c.Chat_Unfollow_Notification_Message";
import LABEL_FOLLOW_MESSAGE from "@salesforce/label/c.Chat_Follow_Notification_Message";

export default class Follow extends LightningElement {
    @api contextParent = ''; 
    @api contextChild = '';

    @wire(MessageContext) messageContext;

    isFollowing = false;
    textWhenHovering = LABEL_WHEN_HOVERING;
    textWhenOff = LABEL_WHEN_OFF;
    textWhenOn = LABEL_WHEN_ON;
    textUnfollowMessage = LABEL_UNFOLLOW_MESSAGE;
    textFollowMessage = LABEL_FOLLOW_MESSAGE;

    // lifecycle hooks 
    connectedCallback(){
        //console.log(JSON.stringify(this.getContext()));
        currentUserFollows(this.getContext()).then((result)=>{
            this.isFollowing = result;
            console.log(this.isFollowing);
        })
        .catch((error)=>{
            this.logImperativeApexError(error, 'error fetching current users follow for this chat');
        });
    }

    // event handlers 
    handleFollowClick(){
        this.isFollowing = !this.isFollowing;
        if (this.isFollowing){
            this.createFollow();
        }else{
            deleteFollow(this.getContext()).then((result)=>{
                console.log(JSON.stringify(result))
                let toastEvent = new ShowToastEvent({
                    title: this.textUnfollowMessage,
                    variant: 'success'
                }); 
                this.dispatchEvent(toastEvent);
            })
            .catch((error) => {
                this.logImperativeApexError(error, 'Error unfollowing record')
            });
        }
        this.publishChatUpdateEvent();
    }

    // reuseable methods 

    @api createFollow(){
        createFollow(this.getContext()).then((result)=>{
            console.log(JSON.stringify(result));
            let toastEvent = new ShowToastEvent({
                title: this.textFollowMessage,
                variant: 'success'
            }); 
            this.dispatchEvent(toastEvent);
        })
        .catch((error)=>{
            this.isFollowing = !this.isFollowing;
            this.logImperativeApexError(error, 'Error following record');
        });
    }

    logImperativeApexError(error, subject){ //could put this in an error handling component
        let toastEvent = new ShowToastEvent({
            title: subject,
            message: error,
            variant: 'error', 
            mode : 'sticky'
        }); 
        this.dispatchEvent(toastEvent);
        console.log(JSON.stringify(error));
    }

    getContext(){
        let context = this.contextParent;
        /*if (this.contextChild){ // we've said that we'll define follow only on the funding award
            context = this.contextChild;
        }*/
        return {contextId : context};
    }

    publishChatUpdateEvent(){
        console.log('(follow) publishChatUpdateEvent');
        const payload = {
            eventType: this.isFollowing ? 'FOLLOW' : 'UNFOLLOW',
            eventSource: 'followComponent', // helps avoid recursion
            chatParentContextId: this.contextParent
        };
        console.log('(follow) publishChatUpdateEvent - about to publish payload = :', payload);
        publish(this.messageContext, CHAT_UPDATE_EVENT, payload);        
        console.log('(follow) publishChatUpdateEvent - Published:', payload);
    }

}