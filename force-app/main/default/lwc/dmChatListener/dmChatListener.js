import { LightningElement, api, wire } from 'lwc';
import {
    subscribe,
    unsubscribe,
    onError,
    setDebugFlag,
    isEmpEnabled,
} from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const chatObjectFields = ['Chat__c.Context_Parent__c', 'Chat__c.Context_Child__c', 'Id'];

//copy pasta from https://developer.salesforce.com/docs/component-library/bundle/lightning-emp-api/documentation
/* Usage considerations
The lightning/empApi module is supported in desktop browsers with web worker or shared worker support. It is not supported in the Salesforce mobile app. For more information about web workers and browser support, see the Web Workers W3C specification and Using Web Workers in the Mozilla Developer Network documentation.
You can use the lightning/empApi module only on the main window of a page. You can't use the lightning/empApi module on a child window. For example, in a screen flow, you can use the lightning/empApi module only on the main screen but not on a button in a screen flow. Similarly, you can’t use the lightning/empApi module in the utility bar pop-out window. Another example is a Visualforce page that contains a top-level window and child iframe windows. In this case, the lightning/empApi module must be on the top-level window.
*/
export default class DmChatListener extends LightningElement {
    @api contextParent;
    @api contextChild;
    //@api enabled = false; // set this true when in a context that supports it so that we can automatically get replys without refreshing - see usage considerations above

    channelName = '/data/Chat_Channel__chn';

    subscription = {};
    chatCache = []; // for cache checking
    // Initializes the component
    connectedCallback() {
        // Register error listener
        this.registerErrorListener();
        this.handleSubscribe();
    }

    // Handles subscribe button click
    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = (response) => {
            console.log('New message received: ', JSON.stringify(response));
            this.getMessageContext(response);
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            // Response contains the subscription information on subscribe call
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
            this.subscription = response;
        });
    }

    getMessageContext(response){
        if (!response.data){
            return;
        }
        if (!response.data.payload){
            return;
        }

        let responseContext = {parent:'', child: ''}
        if (response.data.payload.Context_Parent__c){
            responseContext.parent = response.data.payload.Context_Parent__c;
        }
        if (response.data.payload.Context_Child__c){
            responseContext.child = response.data.payload.Context_Child__c;
        }
        let inCurrentContext = this.checkResponseContext(responseContext);
        this.dispatchMessageReceived(inCurrentContext, response);
    }

    checkResponseContext(responseContext, response){ //returns boolean 
        if (!this.contextChild){
            if (this.contextParent === responseContext.parent){
                return true;
            }
        }else{
            if ((this.contextParent === responseContext.parent) && (this.contextChild === responseContext.child)){
                return true;
            }
        }
        return false;
    }

    dispatchMessageReceived(dispatch, response){
        // Response contains the payload of the new message received
        if (dispatch){
            this.dispatchEvent(new CustomEvent('messagereceived', { // pass the response to the chat so we use the data that has changed
                detail : response
            }));
        }
    }

    disconnectedCallback(){
        this.handleUnsubscribe();
    }

    // Handles unsubscribe button click
    handleUnsubscribe() {
        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, (response) => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }
}