import { LightningElement, api } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class FlowNav extends LightningElement {
    @api availableActions = [];
    @api nextLabel;
    @api backLabel;
    @api finishLabel;
    @api nextUrl;
    @api backUrl;
    @api finishUrl;
    @api buttonAlignment = 'right';
    @api nextState;
    @api nextStateValue;
    @api variant = 'brand';
    @api isDisabled = false;

    _isButton = true;
    @api
    get isButton() {
        return this._isButton;
    }
    set isButton(val) {
        this._isButton =
            val === true ||
            val === 'true' ||
            val === 1 ||
            val === '1';
    }

    get showBackButton() {
        return (this.backUrl || this.availableActions.includes('BACK')) && this.backLabel;
    }

    get showNextButton() {
        return (this.nextUrl || this.availableActions.includes('NEXT')) && this.nextLabel;
    }

    get showFinishButton() {
        return (this.finishUrl || this.availableActions.includes('FINISH')) && this.finishLabel;
    }

    get buttonAlignmentClass() {
        switch (this.buttonAlignment) {
            case 'left':
                return 'button-align-left';
            case 'right':
                return 'button-align-right';
            case 'center':
            default:
                return 'button-align-center';
        }
    }

    connectedCallback(){
        this.isButton = this._isButton;

        let flowUpdateEvent = new FlowAttributeChangeEvent('nextState', '');
        this.dispatchEvent(flowUpdateEvent);
    }

    handleNext() {
        if (this.nextUrl) {
            window.location.href = this.nextUrl;
        } else if (this.availableActions.includes('NEXT')) {
            let flowUpdateEvent = new FlowAttributeChangeEvent('nextState', this.nextStateValue);
            this.dispatchEvent(flowUpdateEvent);
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }

    handleBack() {
        if (this.backUrl) {
            window.location.href = this.backUrl;
        } else if (this.availableActions.includes('BACK')) {
            const navigateBackEvent = new FlowNavigationBackEvent();
            this.dispatchEvent(navigateBackEvent);
        }
    }

    handleFinish() {
        if (this.finishUrl) {
            window.location.href = this.finishUrl;
        } else if (this.availableActions.includes('FINISH')) {
            const navigateFinishEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateFinishEvent);
        }
    }
}