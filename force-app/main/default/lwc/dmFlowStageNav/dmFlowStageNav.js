import { LightningElement, api, track } from 'lwc';
import { FlowNavigationNextEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class DmFlowStageNav extends LightningElement {
    @api stages;
    @api currentStage;
    @api clickedStage;
    @api displayType = 'base';
    @api interactable = false;

    _stages = [];

    connectedCallback(){
        let stageNames = this.stages.split(',');
        let count = 0;
        for (let stage of stageNames){
            this._stages.push({key:count, stageName:stage});
            count += 1;
        }
    }

    handleNext(event) {
        if (this.interactable === "all"){
            this.navigate(event);
        }else if (this.interactable === "previousOnly"){
            let selectedStage = event.target.value;
            if (this.stages.indexOf(selectedStage) < this.stages.indexOf(this.currentStage)){
                this.navigate(event);
            }
        }
    }

    navigate(event){
        let selectedStage = event.target.value;
        console.log(selectedStage);
        let flowUpdateEvent = new FlowAttributeChangeEvent('clickedStage', selectedStage);
        this.dispatchEvent(flowUpdateEvent);
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
}