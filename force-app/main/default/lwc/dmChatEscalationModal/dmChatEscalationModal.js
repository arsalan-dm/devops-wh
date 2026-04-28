import { api } from 'lwc';
import LightningModal from 'lightning/modal';

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 
                'Oct', 'Nov', 'Dec'];

function formatDateTime(messageDateString){
    let messageDate = new Date(messageDateString);
    let formattedDate = messageDate.getUTCDate() + ' '; 
    formattedDate += MONTHS[messageDate.getMonth()] + ' ';
    formattedDate += messageDate.getFullYear() + ' at ';
    formattedDate += messageDate.getHours().toString().padStart(2,'0') + ':';
    formattedDate += messageDate.getMinutes().toString().padStart(2,'0');
    return formattedDate; 
}

export default class DmChatEscalationModal extends LightningModal {
    @api flowApiName = '';
    @api flowMessageInputVariableName = '';
    @api flowEscalationRecordOutputApiName;
    @api contextParent;
    @api flowContextParentInputApiName;
    @api messages = [];
    
    // getters setters 
    get flowInputVariables(){
        let escalationDescription = '';
        for (let message of this.messages){
            escalationDescription += message.author + ' ' + formatDateTime(message.createdDatetime) + '\n';
            escalationDescription += message.body + '\n';
        }
        return [
            {
                name: this.flowMessageInputVariableName,
                type: 'String',
                value: escalationDescription
            },
            {
                name: this.flowContextParentInputApiName,
                type: 'String',
                value: this.contextParent
            }
        ];
    }

    // event handlers 
    handleFlowStatusChange(event){
        console.log(JSON.stringify(event.detail));
        console.log(this.flowEscalationRecordOutputApiName);
        let escalatedRecords = event.detail.outputVariables.filter(item => item.name === this.flowEscalationRecordOutputApiName);
        if (!escalatedRecords.length){
            return;
        }
        let escalatedRecord = escalatedRecords[0];
        if (!escalatedRecord.value){
            return;
        }
        if (!escalatedRecord.value.Id){
            return;
        }
        // dispatch event to parent with the record Id
        this.dispatchEvent(new CustomEvent('flowfinish', {
            detail : { escalationRecordId : escalatedRecord.value.Id, messagesEscalated : this.messages}
        }));
    }
}