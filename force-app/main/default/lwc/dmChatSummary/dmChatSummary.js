import { LightningElement , api} from 'lwc';
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export default class DmChatSummary extends LightningElement {

    @api chat = {};
    @api selectedChatParentContext;

    

    handleClick() {
        console.log('(dmChatSummary) Chat Summary clicked for chat Id = ', this.chat?.chatId);
        console.log('(dmChatSummary) Chat Summary clicked for contextParent Id = ', this.chat?.contextParent);
        this.dispatchEvent(new CustomEvent('chatselect', {
            detail: {
                chatId: this.chat?.chatId,
                contextParent: this.chat?.contextParent,
                contextParentName: this.chat?.contextParentName,
                contextAwardeeName: this.chat?.awardeeName,
                contextAwardeeId: this.chat?.awardeeId,
                isUnfollowed: this.chat?.isUnfollowed
            },
            bubbles: true,
            composed: true
        }));
        console.log('(dmChatSummary) Event fired from summary  = ', this.chat?.chatId);
    }

    // getters setters

    get showChatSummary(){
        return this.chat?.contextChild == null;
    }

    get formattedDateTime(){
        if (!this.chat.lastMessage){
            return 'No message Date time found';
        }
        let messageDate = new Date(this.chat.lastMessage);
        let messageString = messageDate.getUTCDate() + ' '; 
        messageString += MONTHS[messageDate.getMonth()] + ' ';
        messageString += messageDate.getFullYear() + ' at ';
        messageString += messageDate.getHours().toString().padStart(2,'0') + ':';
        messageString += messageDate.getMinutes().toString().padStart(2,'0');
        return messageString; 
    }

    get chatSummaryStyle() {
        // base SLDS styles
        let style = 'slds-box slds-box_x-small slds-theme_default slds-m-bottom_small';

        // highlight the currently selected chat
        if (this.chat?.contextParent === this.selectedChatParentContext) {
            style += ' theme_selected';
        }

        // visually mark unfollowed chats - Deprecated as using a tect message
        // if (this.chat?.isUnfollowed) {
        //     style += ' slds-theme_alert-texture';
        // }

        return style;
    }

    get chatIsUnfollowed() {
        return this.chat?.isUnfollowed;
    }

    get hasMessages() {
        return this.chat?.lastMessage != null;
    }

    get hasItemsToRead(){ 
        if(this.chat.unreadMessageCount){
            return true;
        }
        return false;
    }
}