import { LightningElement, api, wire, track } from 'lwc';
import userId from '@salesforce/user/Id';

import createMessage from '@salesforce/apex/ChatController.createMessage';
import editMessages from '@salesforce/apex/ChatController.editMessages';
import getMessagesDateRange from '@salesforce/apex/ChatController.getMessagesDateRange';
import setReadReceipt from '@salesforce/apex/ChatController.setReadReceipt';
import oldestMessage from '@salesforce/apex/ChatController.oldestMessage';

import hasInternalUserPermission from '@salesforce/customPermission/Chat_Internal_User';
import isChatReadOnlyUser from '@salesforce/customPermission/Chat_Read_Only';
import hasViewArchivedPermission from '@salesforce/customPermission/Chat_View_Archive';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ChatEscalationModal from 'c/dmChatEscalationModal';

import CHAT_TITLE_LABEL from "@salesforce/label/c.Chat_Window_Title";
import CHAT_NEW_MESSAGE_PLACEHOLDER_LABEL from "@salesforce/label/c.Chat_Window_New_Message_Placeholder";
import CHAT_MESSAGE_ESCALATION_BUTTON_LABEL from "@salesforce/label/c.Chat_Window_Formalise_Messages_Button";
import CHAT_MESSAGE_NEW_BUTTON_LABEL from "@salesforce/label/c.Chat_Window_New_Message_Button";
import CHAT_MESSAGE_ESCALATION_CANCEL_BUTTON_LABEL from "@salesforce/label/c.Chat_Window_Formalise_Messages_Cancel_Button";

/*
message = {
    id : "", // not currently implemented
    body : "",
    authorId : "",
    authorName : "",
    createdDateTime : "",
    escalationId : "",
    isSent : "", // not currently implemented
    replyId : "" // not currently implemented
    selected : false // whether the message has been selected for escalation 
}
*/

const mergeChatMessages = (a, b, predicate = (a, b) => a.key === b.key) => {
    const c = [...a]; // copy to avoid side effects
    // add all items from B to copy C if they're not already present
    b.forEach((bItem) => (c.some((cItem) => predicate(bItem, cItem)) ? null : c.push(bItem)))
    return c;
}

const compareDates = (a, b) => {
    if (a.messageDate < b.messageDate){
        return 1;
    }
    if (a.messageDate > b.messageDate){
        return -1;
    }
    return 0
}

const INTERNAL_LICENCE_NAMES = ['Salesforce']; // TODO get these dynamically 
const DEFAULT_MAX_HEIGHT = 500;
const MAXIMUM_DAY_SCROLL_BACK = 92;

export default class DmChatWindow extends LightningElement {
    @api contextParent = ''; 
    @api contextChild = '';
    @api allowsEscalation = false;
    @api flowApiName = '';
    @api flowMessageInputVariableName = '';
    @api flowEscalationRecordOutputApiName = ''; 
    @api flowContextParentInputApiName = '';
    @api maxHeight;
    @api anchorTarget = '_self';
    
    @track messages = [];
    
    isFollowing = false;
    escalationMode = false;

    _chats = [];
    _authorId = userId;
    _composedMessage = '';
    _messageCount = '';
    _userLicenceName = '';
    _dayChunkSize = 7;
    _rendered = false;
    isInternalUser = false;
    chatReadOnlyUser = false;
    _polling = false;
    doneInitialLoading = false;
    alreadyLoading = false;

    contextChildName = null;

    // dates for message chunking when scrolling   
    startDate;
    endDate;
    oldestDateFetched;
    maxScrollbackDate;

    // labels
    chatTitleLabel = CHAT_TITLE_LABEL;
    chatNewMessagePlaceholderLabel = CHAT_NEW_MESSAGE_PLACEHOLDER_LABEL;
    chatEscalationButtonLabel = CHAT_MESSAGE_ESCALATION_BUTTON_LABEL;
    chatEscalationCancelButtonLabel = CHAT_MESSAGE_ESCALATION_CANCEL_BUTTON_LABEL;
    chatNewButtonLabel = CHAT_MESSAGE_NEW_BUTTON_LABEL;

    hitScrollMax = false;

    // getters setters

    get sendDisabled(){
        if (this._composedMessage){
            return false;
        }
        return true;
    }

    get cardTitle(){
        if (this.contextChildName){
            return this.chatTitleLabel + ' - ' + this.contextChildName;
        }
        return this.chatTitleLabel;
    }

    get allowChatPost(){
        return this.chatReadOnlyUser !== true;
    }

    // lifecycle callbacks
    connectedCallback(){ 
        this.isInternalUser = hasInternalUserPermission; // assign here so that we can use it in the html 
        this.chatReadOnlyUser = isChatReadOnlyUser;

        if (hasViewArchivedPermission){
            this._dayChunkSize = 35;
            this.getOldestMessageDate();
        }

        if (!this.maxHeight){
            this.maxHeight = DEFAULT_MAX_HEIGHT;
        }
        this.oldestDateFetched = new Date();
        this.endDate = new Date();
        this.startDate = new Date();
        this.startDate.setDate(this.startDate.getDate() - this._dayChunkSize);
        this.maxScrollbackDate = new Date();
        this.maxScrollbackDate.setDate(this.startDate.getDate() - MAXIMUM_DAY_SCROLL_BACK);
        
        //console.log('context parent: ' + this.contextParent);
        
        
        this.fetchMessagesDateRange(this.startDate, this.endDate, true);

        if (!this.isInternalUser){
            if (!this._polling){
                this.newMessagePolling();
                this._polling = true;
            }
        }
    }

    renderedCallback(){
        if (!this._rendered){
            if (!this.maxHeight){
                this.maxHeight = DEFAULT_MAX_HEIGHT;
            }
            this._rendered = true;
            this.refs.chatWindow.style.setProperty( '--max-height', this.maxHeight + 'px');
        }
    }

    // event handlers 

    handleMessageChange(event){
        this._composedMessage = event.target.value;
    }

    handleMessageReceived(event){
        // replace this with a function that just updates what has changed, rather than fetching the new chats every time
        this.newMessageFetch();
    }

    handleSendClick(event){
        const messageToSend = this._composedMessage;
        this._composedMessage = '';
        let nowIsoString = (new Date()).toJSON();
        let message = {
            'body' : messageToSend,
            'authorId' : this._authorId,
            'createdDatetime' : nowIsoString,
            'contextChild' : this.contextChild,
            'contextParent' : this.contextParent
        }

        if (this.messages.length){
            let lastMessage;
            

            if (this.contextChild){
                lastMessage = this.messages[this.messages.length - 1];
            }else{
                // find the latest message without a child context
                let childContextlessMessages = this.messages.filter(item => !item.contextChild);
                lastMessage = childContextlessMessages[childContextlessMessages.length - 1];
            }
            if (lastMessage){
                //let newMessageCount = lastMessage.chatRecordMessageCount + 1;  
                message['chatId'] = lastMessage.chatId;
                //message['key'] = lastMessage.chatId + newMessageCount;
            }
        }
        createMessage({message : message})
            .then((result) => {
                let newMessage = JSON.parse(JSON.stringify(result));
                newMessage.key = this.calcualteNewMessageKey(newMessage);
                this.messages = mergeChatMessages(Array(1).fill(newMessage), this.messages);
            })
            .catch((error => {
                this.logImperativeApexError(error,'Error creating chat message');
                this._composedMessage = messageToSend;
            }));
    }

    calcualteNewMessageKey(newMessage){
        for(let message of this.messages){
            if (message.chatId === newMessage.chatId){
                let lastKey = message.key.slice(18);
                let count = Number(lastKey);
                if (count != NaN){
                    count += 1;
                }else{
                    count = 0;
                }
                return newMessage.chatId + count.toString();
            }
        }
        return newMessage.chatId + 0;
    }

    handleCancelClicked(){
        this.escalationMode = false;
        this.unselectMessages();
    }

    handleMessageSelect(event){
        const message = event.detail.message;
        const checkedValue = event.detail.isChecked;
        let currentMessage = this.messages.filter(item => message.key === item.key);
        if (currentMessage.length){
            currentMessage[0].selected = checkedValue;
        }
        this.escalationMode = true;
        if (this.allUnselected()){
            this.escalationMode = false;
        }
    }

    handleEscalationConfirmClicked(event){
        this.escalationMode = false;
        const messagesToEscalate = this.messages.filter(item => item.selected === true);
        // do the escalation call the escalation flow
        ChatEscalationModal.open({
            flowApiName : this.flowApiName,
            flowMessageInputVariableName : this.flowMessageInputVariableName,
            flowEscalationRecordOutputApiName : this.flowEscalationRecordOutputApiName,
            flowContextParentInputApiName : this.flowContextParentInputApiName,
            contextParent : this.contextParent,
            messages : messagesToEscalate,
            onflowfinish :(event) =>{
                event.stopPropagation();
                this.handleFlowFinished(event);
            }
        }).then((result) => {
            this.unselectMessages();
        });
    }

    handleFlowFinished(event){
        // update the messages list with the returned escalation Id for each message in the list provided
        let messagesEscalated = this.messages.filter((record) => event.detail.messagesEscalated.some((item) => record.key === item.key));
        for (let message of messagesEscalated){
            message.escalationId = event.detail.escalationRecordId;
        }
        editMessages({messages : messagesEscalated})
            .then((result) => {
                console.log(JSON.stringify(result));
            }).catch((error) => {
                this.logImperativeApexError(error, 'Error updating messages');
            });
    }

    handleMessagesScroll(event){
        let messageEl = this.refs.chatWindow;
        
        if (!this.hitScrollMax){
            if ((messageEl.scrollTop + messageEl.clientHeight) > (0.9 * messageEl.scrollHeight)){
                this.fetchNextMessages();
            }
        }
    }

    handleChildContextChange(event){
        //console.log(JSON.stringify(event.detail));
        if (this.contextChild != event.detail.childContextId){
            this.messages = [];
            this.doneInitialLoading = false;
            this.contextChild = event.detail.childContextId;
            this.oldestDateFetched = new Date();
            this.endDate = new Date();
            this.startDate = new Date();
            this.startDate.setDate(this.startDate.getDate() - this._dayChunkSize);
            this.fetchMessagesDateRange(this.startDate, this.endDate, true);
        }   
        if (event.detail.childContextName != this.contextChildName){
            this.contextChildName = event.detail.childContextName;
        }
    }

    // reuseable methods
    fetchMessagesDateRange(startDate, endDate, cascade){
        let params = {
            contextParent: this.contextParent, 
            contextChild: this.contextChild, 
            startDate: startDate.toJSON(), 
            endDate: endDate.toJSON()
        };
        getMessagesDateRange(params)
            .then((result) =>{
                // handle state variables
                if (startDate < this.oldestDateFetched){
                    this.oldestDateFetched = startDate;
                    console.log('oldest date looked for: ' + this.oldestDateFetched.toJSON());
                }
                
                // sort out messages
                let newMessages = JSON.parse(JSON.stringify(result)); //results are immutable, clone it 
                if (newMessages.length === 0){
                    // in here look for older messages
                    this.alreadyLoading = false;
                    if (cascade){
                        this.fetchNextMessages();
                    }
                    return;
                }

                this.doneInitialLoading = true;

                if (this.messages.length === 0){
                    this.messages = JSON.parse(JSON.stringify(result));
                    this.messages.forEach((item)=> item.messageDate = new Date(item.createdDatetime));
                    this.checkForMoreMessagesIfScrollbarNotPresent(cascade);
                    //callout to server to set the first message from messages as the read reciept for the current user
                    // this if statement only runs once because newMessages is not zero whilst messages is zero only once in the lifecycle of the LWC
                    this.setReadReceiptForMessage(this.getNewestMessageKeyMatchingContext());
                    return;
                }
                
                newMessages.forEach((item)=> item.messageDate = new Date(item.createdDatetime));
                // join with the messages that we already have 
                this.messages = mergeChatMessages(newMessages, this.messages);

                // sort them 
                this.messages.sort(compareDates);
                this.alreadyLoading = false;
                this.checkForMoreMessagesIfScrollbarNotPresent(cascade);
            }).catch((error) =>{
                this.logImperativeApexError(error,'Error fetching chat messages');
                this.alreadyLoading = false;
            });
    }

    checkForMoreMessagesIfScrollbarNotPresent(cascade){
        setTimeout(() => {
            if (this.refs.chatWindow.offsetHeight < this.maxHeight){
                if (cascade){
                    this.fetchNextMessages();
                }
            }
        }, 0);
    }

    getOldestMessageDate(){
        let params = {
            contextParent: this.contextParent, 
            contextChild: this.contextChild
        };
        oldestMessage(params)
            .then((result)=>{
                this.maxScrollbackDate = new Date(result);
                this.maxScrollbackDate.setDate(this.maxScrollbackDate.getDate() - this._dayChunkSize - 2);
                console.log('Oldest Message for context: ' + this.maxScrollbackDate);
            }).catch((error)=>{
                this.logImperativeApexError(error,'Error setting read receipt for most recent chat');
            });
    }

    fetchNextMessages(){
        let newEndDate = new Date(this.oldestDateFetched.getTime());
        let newStartDate = new Date(this.oldestDateFetched.getTime());
        newStartDate.setDate(newStartDate.getDate() - this._dayChunkSize);
        if (newStartDate < this.maxScrollbackDate){
            this.hitScrollMax = true;
            this.doneInitialLoading = true;
            return;
        }
        if (!this.alreadyLoading){
            this.alreadyLoading = true;
            this.fetchMessagesDateRange(newStartDate, newEndDate, true);
        }
    }

    setReadReceiptForMessage(messageKey){
        if (messageKey){
            setReadReceipt({messageKey: messageKey})
                .catch((error)=> {
                    this.logImperativeApexError(error,'Error setting read receipt for most recent chat');
                });
        }
        
    }

    unselectMessages(){
        for (let message of this.messages){
            if (message.selected){
                message.selected = false;
            }
        }
    }

    allUnselected(){
        for (let message of this.messages){
            if (message.selected){
                return false;
            }
        }
        return true;
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

    newMessagePolling(){
        setTimeout(() => {
            if (!this.isInternalUser){
                console.log('portal poll for new messages');
                this.newMessageFetch();
                this.newMessagePolling();
            }else{
                this._polling = false;
            }
        }, 30000);
    }

    newMessageFetch(){
        let end = new Date();
        let start = new Date();
        start.setDate(start.getDate() - 3);
        this.fetchMessagesDateRange(start, end, false);
    }

    getNewestMessageKeyMatchingContext(){
        let checkContextChild = this.contextChild;
        if (!checkContextChild){
            checkContextChild = null;
        } 
        for(let message of this.messages){
            if (message.contextChild == checkContextChild){
                return message.key;
            } 
        }
        return null;
    }
}