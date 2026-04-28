import { LightningElement, api } from 'lwc';

export default class DmChatWindowFlow extends LightningElement {
    @api contextParent;
    @api contextChild;
    @api allowEscalation;
    @api flowApiName;
    @api flowMessageInputVariableName;
    @api flowEscalationRecordOutputApiName;
    @api flowContextParentInputApiName;
    @api maxHeight;
    @api anchorTarget = '_self';
}