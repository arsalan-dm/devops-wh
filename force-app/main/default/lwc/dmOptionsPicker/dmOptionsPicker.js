import { LightningElement, api, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { subscribe, unsubscribe, publish, createMessageContext, releaseMessageContext } from 'lightning/messageService';
import dmOptionsPicker from '@salesforce/messageChannel/dmOptionsPicker__c';

let instanceId = 0;

export default class DmOptionsPicker extends LightningElement {

    @api label;
    @api choiceLabels; // comma-separated string
    @api choiceValues; // comma-separated string
    @api isPicklist; // Whether to render a picklist or radio buttons
    @api delimiter; // Delimiter for choiceLabels/choiceValues
    @api defaultValue; // Default value in the flow
    @api isRequired; // Whether input is required by the user
    @api pickerId;
    @api crossContextPicking = false;

    messageContext;
    channelSubscription;

    // Backing state for controlled value
    _value;
    _instanceId = 0;
    @api
    get value() {
        return this._value;
    }
    set value(v) {
        // Normalize undefined/null to empty string
        const next = v == null ? '' : v;
        if (this._value !== next) {
            this._value = next;
        }
    }

    // Having to generate a unique name by instance for the radio options
    // otherwise, multiple instances will have the same name and only the last one will be rendered
    _name = 'radioOptions';

    get name() {
        return this._name + this._instanceId;
    }

    options = []; // Mapped as label (choiceLabels), value (choiceValues) pairs

    connectedCallback() {
        if(this.crossContextPicking){
            this.messageContext = createMessageContext();
            this.channelSubscription = subscribe(
                this.messageContext,
                dmOptionsPicker,
                (message) => this.handleMessage(message)
            );
        }

        instanceId += 1;
        this._instanceId = instanceId;
        this.prepareOptions();
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this._value));

        // Apply default once if no inbound value was provided by Flow and default is valid
        if ((this._value === undefined || this._value === null || this._value === '') && this.defaultValue) {
            const exists = Array.isArray(this.options) && this.options.some(opt => opt.value === this.defaultValue);
            if (exists) {
                this._value = this.defaultValue;
                // Notify Flow so it persists per repeater row
                this.dispatchEvent(new FlowAttributeChangeEvent('value', this._value));
            }
        }
    }

    handleMessage(message) {
        if(this.pickerId === message.pickerId && this._instanceId !== message.repeaterId) {
            this._value = null;
            this.dispatchEvent(new FlowAttributeChangeEvent('value', this._value));
        }

    }

    sendMessageChannel(){
        publish(this.messageContext, dmOptionsPicker, {
            repeaterId : this._instanceId,
            pickerId : this.pickerId
        });
    }

    disconnectedCallback(){
        if(this.crossContextPicking) {
            unsubscribe(this.spendTotalChannelSub);
            releaseMessageContext(this.messageContext);
        }
    }

    // Delimiter (defaults to comma)
    get actualDelimiter() {
        const d = this.delimiter;
        return (typeof d === 'string' && d.length > 0) ? d : ',';
    }

    // Prepares choiceLabels/choiceValues options
    prepareOptions() {
        const labels = this.prepareArray(this.choiceLabels);
        const values = this.prepareArray(this.choiceValues);

        const len = Math.min(labels.length, values.length);
        this.options = Array.from({ length: len }, (_, i) => ({
            label: labels[i],
            value: values[i]
        }));
        // If options changed and current value is no longer valid, clear and notify Flow
        if (this._value && !this.options.some(o => o.value === this._value)) {
            this._value = '';
            this.dispatchEvent(new FlowAttributeChangeEvent('value', this._value));
        }
    }

    // Accepts a delimited string and returns a string collection
    prepareArray(input) {
        if (Array.isArray(input)) 
        {
            return input.map(v => (v == null ? '' : String(v)));
        }
        if (typeof input === 'string') 
        {
            const trimmed = input.trim();
            if (!trimmed) 
            {
                return [];
            }
            return trimmed
                .split(this.actualDelimiter)
                .map(s => s.trim())
                .filter(s => s.length > 0);
        }
        return [];
    }

    // Handles the user selection
    handleChange(event) {
        console.log('i\'ve been pressed instance Id ' + this._instanceId);
        event.stopPropagation();
        const newVal = event.detail?.value ?? event.target?.value ?? '';
        if (this._value !== newVal) {
            this._value = newVal;
            // Dispatch an event so the screen can bind the output value (per repeater row)
            this.dispatchEvent(new FlowAttributeChangeEvent('value', this._value));
        }
        if(this.crossContextPicking) {
            this.sendMessageChannel();
        } 
    }

    // Explicit Flow state persistence hooks for edge rerenders/remounts
    // Flow calls getState() to serialize component state and may call applyState(state) to restore it.
    @api
    getState() {
        return {
            value: this._value ?? '',
            options: this.options?.map(o => ({ label: o.label, value: o.value })) || [],
            defaultValue: this.defaultValue ?? '',
            isPicklist: !!this.isPicklist
        };
    }

    @api
    applyState(state) {
        try {
            if (state) {
                // Restore value first so UI reflects correctly
                const restored = state.value == null ? '' : state.value;
                if (this._value !== restored) {
                    this._value = restored;
                    // Also notify Flow to keep the row variable synchronized
                    this.dispatchEvent(new FlowAttributeChangeEvent('value', this._value));
                }
                // Optionally restore options if Flow serialized them
                if (Array.isArray(state.options) && state.options.length > 0) {
                    this.options = state.options.map(o => ({ label: o.label, value: o.value }));
                    // If restored value no longer valid for restored options, clear and notify
                    if (this._value && !this.options.some(o => o.value === this._value)) {
                        this._value = '';
                        this.dispatchEvent(new FlowAttributeChangeEvent('value', this._value));
                    }
                }
            }
        } catch (e) {
            // On any error, do not throw — keep Flow running
        }
    }
}