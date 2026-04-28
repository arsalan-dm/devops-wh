import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class DmFlowStageNav extends LightningElement {
    @api stages;
    @api currentStage;
    @api clickedStage;
    @api displayType = 'base';
    @api interactable = 'none';
    @api orientation = 'horizontal';
    @api labelDisplay = 'tooltip';

    _stages = [];
    _currentIndex = -1;

    connectedCallback() {
        const stageNames = this.stages.split(',').map(s => s.trim());
        this._currentIndex = stageNames.indexOf(this.currentStage);

        this._stages = stageNames.map((stage, index) => {
            const isComplete = index < this._currentIndex;
            const isCurrent = index === this._currentIndex;
            return {
                key: index,
                stageName: stage,
                label: this.labelDisplay === 'always' ? stage : undefined,
                title: this.labelDisplay === 'tooltip' ? stage : undefined,
                isComplete,
                isCurrent,
                className: this.getStageClass(isComplete, isCurrent)
            };
        });
    }

    get isHorizontal() {
        return this.orientation === 'horizontal';
    }

    getStageClass(isComplete, isCurrent) {
        if (isCurrent) {
            return 'slds-progress__item slds-is-active';
        } else if (isComplete) {
            return 'slds-progress__item slds-is-completed';
        }
        return 'slds-progress__item';
    }

    handleNext(event) {
        const selectedStage = event.target.dataset.value || event.target.value;
        if (this.interactable === 'all') {
            this.navigate(selectedStage);
        } else if (this.interactable === 'previousOnly') {
            if (this.stages.indexOf(selectedStage) < this.stages.indexOf(this.currentStage)) {
                this.navigate(selectedStage);
            }
        }
    }

    navigate(stageName) {
        this.dispatchEvent(new FlowAttributeChangeEvent('clickedStage', stageName));
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}