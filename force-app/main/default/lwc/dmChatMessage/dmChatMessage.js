import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 
                'Oct', 'Nov', 'Dec'];

export default class DmChatMessage extends NavigationMixin(LightningElement) {
    @api message = {};
    @api escalationMode = false;
    @api isInternalUser = false;
    @api currentChildContext = null;
    @api allowEscalation = false;
    @api anchorTarget = '_self';

    escalationLink = '';
    escalationPageReference;

    childContextLink ='';
    childContextPageReference;

    // getters setters
    get formattedDateTime(){
        if (!this.message.createdDatetime){
            return 'No message Date time found';
        }
        let messageDate = new Date(this.message.createdDatetime);
        let messageString = messageDate.getUTCDate() + ' '; 
        messageString += MONTHS[messageDate.getMonth()] + ' ';
        messageString += messageDate.getFullYear() + ' at ';
        messageString += messageDate.getHours().toString().padStart(2,'0') + ':';
        messageString += messageDate.getMinutes().toString().padStart(2,'0');
        return messageString; 
    }

    get displayEscalation(){
        if (!this.isInternalUser){
            return false; 
        }
        if (!this.message.escalationId){
            return false;
        }
        return true;
    }

    get displayChildContext(){
        if (!this.isInternalUser){
            return false; 
        }
        if (!this.message.contextChild){
            return false;
        }
        if (this.currentChildContext){
            return false;
        }
        return true;
    }

    get notAlreadyEscalated(){
        if (this.message.escalationId){
            return false;
        }
        return true;
    }

    get escalationExternalDisplay(){
        if (this.isInternalUser){
            return false;
        }
        if (!this.message.escalationId){
            return false;
        }
        return true;
    }

    // lifecycle hooks
    connectedCallback(){
        this[NavigationMixin.GenerateUrl](this.getChildContextPageReference())
            .then(url => {
                this.childContextLink = url;
            })
            .catch(error => {
                console.error('Error generating URL:', error);
            });

        if (!this.message.escalationId){
            return;
        }
        
        this[NavigationMixin.GenerateUrl](this.getEscatedPageReference())
            .then(url => {
                this.escalationLink = url;
            })
            .catch(error => {
                console.error('Error generating URL:', error);
            });
    }

    // event handlers
    handleChecked(){
        let isChecked = false;
        if (!this.message.selected){
            isChecked = true;
        }
        // dispatch event to parent to say the message was clicked 
        this.dispatchEvent(new CustomEvent('messageselect', { // pass the response to the chat so we use the data that has changed
            detail : {message: this.message, isChecked : isChecked}
        }));
    }

    navigateToEscalatedRecord(event){ // doing it this way doesn't do a full page reload, but just instead redirects salesforce ot the page 
        if (this.anchorTarget === '_self'){
            event.preventDefault();
            event.stopPropagation();
            this[NavigationMixin.Navigate](this.getEscatedPageReference());
        }
    }

    navigateToContextChildRecord(event){
        if (this.anchorTarget === '_self'){
            event.preventDefault();
            event.stopPropagation();
            this[NavigationMixin.Navigate](this.getChildContextPageReference());
        }
    }

    // reusable methods ß
    getEscatedPageReference(){
        return {
            type: 'standard__recordPage',
            attributes: {
                recordId: this.message.escalationId,
                actionName: "view",
            }
        };
    }

    getChildContextPageReference(){
        return {
            type: 'standard__recordPage',
            attributes: {
                recordId: this.message.contextChild,
                actionName: "view",
            }
        };
    }
}