import { LightningElement, api } from 'lwc';

export default class DmTextInput extends LightningElement {
    @api value;

    handleChange(event) {
        this.value = event.target.value;
    }
}