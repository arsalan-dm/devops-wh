import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class DmBulkRecordInput extends LightningElement {

    @api fieldNames;          // string[]
    @api sobjectType;         // string

    // Configurable button label (default "Generate Records")
    _buttonLabel;
    @api
    get buttonLabel() {
        return this._buttonLabel || 'Generate Records';
    }
    set buttonLabel(value) {
        this._buttonLabel = value;
    }

    @api updatedRecords;      // Flow output
    @api loadSuccessful = false;
    @api recordCount = '0';

    @track tabDelimitedText = '';

    // Flow-controlled reset trigger
    _resetTrigger;

    @api
    get resetTrigger() {
        return this._resetTrigger;
    }
    set resetTrigger(value) {
        if (value !== this._resetTrigger) {
            this._resetTrigger = value;
            this._resetState();
        }
    }

    // Handle textarea input
    handleTextChange(event) {
        this.tabDelimitedText = event.detail.value;
    }

    // Build records from pasted tab-delimited text
    @api
    build() {

        console.log('--- build() called ---');

        const textarea = this.template.querySelector('lightning-textarea');
        const text = textarea ? textarea.value.trim() : '';

        if (!text) {
            console.log('No text pasted.');
            this._resetState();
            return;
        }

        // Normalize rows
        let rows = text.split(/\r?\n/).filter(r => r?.trim()?.length > 0);

        if (rows.length <= 1) {
            console.log('No data rows found.');
            this._resetState();
            return;
        }

        // Extract header row
        const headers = rows[0].split('\t').map(h => h.trim());

        console.log('Headers detected:', headers);

        // Determine allowed fields
        const allowedFields = this.fieldNames && this.fieldNames.length > 0
            ? this.fieldNames
            : headers;

        // Build header → field mapping
        const columnMap = {};

        headers.forEach((header, index) => {
            if (allowedFields.includes(header)) {
                columnMap[index] = header;
            }
        });

        console.log('Column Map:', columnMap);

        const output = [];

        // Process rows (skip header)
        rows.slice(1).forEach((r, rowIndex) => {

            const cleanedRow = r.replace(/\r/g, '').trim();
            const cols = cleanedRow.split('\t');

            const rec = { attributes: { type: this.sobjectType } };

            Object.keys(columnMap).forEach(colIndex => {

                const fieldName = columnMap[colIndex];
                const value = cols[colIndex] || '';

                rec[fieldName] = this._coerceValue(value);

            });

            output.push(rec);

            console.log(`Row ${rowIndex} parsed:`, JSON.stringify(rec));
        });

        // Assign fresh array for Flow
        this.updatedRecords = output.map(r => ({ ...r }));
        this.loadSuccessful = this.updatedRecords.length > 0;
        this.recordCount = String(this.updatedRecords.length);

        console.log('Build complete:', JSON.stringify(this.updatedRecords, null, 2));

        setTimeout(() => {
            this._notifyFlow();
        }, 0);
    }

    _coerceValue(value) {

        if (!value || value.trim() === '') return null;

        const v = value.trim();
        const lc = v.toLowerCase();

        // Boolean coercion
        if (lc === 'true' || lc === 'yes' || lc === 'y') return true;
        if (lc === 'false' || lc === 'no' || lc === 'n') return false;

        // Date coercion (UK dd/mm/yyyy → yyyy-mm-dd)
        const dateMatch = v.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
        if (dateMatch) {

            const day = parseInt(dateMatch[1], 10);
            const month = parseInt(dateMatch[2], 10);
            const year = parseInt(dateMatch[3], 10);

            if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {

                const mm = month.toString().padStart(2, '0');
                const dd = day.toString().padStart(2, '0');

                return `${year}-${mm}-${dd}`;
            }
        }

        // Everything else returned as string
        return v;
    }

    // Notify Flow about outputs
    _notifyFlow() {

        this.dispatchEvent(new FlowAttributeChangeEvent('updatedRecords', this.updatedRecords));
        this.dispatchEvent(new FlowAttributeChangeEvent('loadSuccessful', this.loadSuccessful));
        this.dispatchEvent(new FlowAttributeChangeEvent('recordCount', this.recordCount));

        console.log('Flow notified of outputs');
    }

    // Reset component state
    _resetState() {

        this.tabDelimitedText = '';
        this.updatedRecords = [];
        this.loadSuccessful = false;
        this.recordCount = '0';

        const textarea = this.template.querySelector('lightning-textarea');
        if (textarea) textarea.value = '';

        setTimeout(() => this._notifyFlow(), 0);

        console.log('Component state reset');
    }
}