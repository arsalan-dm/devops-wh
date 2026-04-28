global with sharing class Dml {

    global List<DmlResult> results {get; private set;}
    
    global DmlResult current {get; private set;}

    global Dml() {
        results = new List<DmlResult>();
        reset();
    }

    public void reset(){
        if (current != null){
            results.add(current);
        }
        current = new DmlResult();
    }

    global Dml setAccessLevel(System.AccessLevel accessLevel){
        current.accessLevel = accessLevel;
        return this;
    }

    global Dml setOptions(Database.DMLOptions options){
        if (options?.optAllOrNone == null){
            options.optAllOrNone = true;
        }
        current.options = options;
        return this;
    }

    global Dml setAllOrNone(Boolean allOrNone){
        current.options.optAllOrNone = allOrNone;
        return this;
    }

    global Dml setAllowFieldTruncation(Boolean allowFieldTruncation){
        current.options.allowFieldTruncation = allowFieldTruncation;
        return this;
    }

    global Dml useDefultAssignmentRuleHeader(){
        current.options.assignmentRuleHeader.useDefaultRule = true;
        return this;
    }

    global Dml setAssignmentRuleHeader(Id assignmentRuleId){
        current.options.assignmentRuleHeader.assignmentRuleID = assignmentRuleId;
        current.options.AssignmentRuleHeader.useDefaultRule = false;
        return this;
    }

    global Dml setEmailHeader(Database.DmlOptions.EmailHeader emailHeader){
        current.options.emailHeader = emailHeader;
        return this;
    }

    global Dml setLocale(String localeOptions){
        current.options.localeOptions = localeOptions;
        return this;
    }

    global Dml setUpsertField(Schema.SObjectField fieldToUpsertAgainst){
        current.fieldToUpsertAgainst = fieldToUpsertAgainst;
        return this;
    }

    global Dml setTarget(List<SObject> records) {
        current.records = records;
        return this;
    }

    global Dml setTarget(SObject record) {
        current.records = new List<SObject>{record};
        return this;
    }

    global Dml setTarget(List<Id> ids) {
        if (ids != null) {
            if (!ids.isEmpty()) {
                current.ids = ids;
            }
        }
        return this;
    }

    global Dml setTarget(Id id) {
        current.ids = new List<Id>{id};
        return this;
    }

    global SObjectAccessDecision getDecision(AccessType accessType) {
        current.hasDmlTarget();
        current.decision = Security.stripInaccessible(accessType, current.records);
        current.accessType = accessType; 
        return current.decision;
    }

    // insert
    global List<SObject> doInsert() {
        if (current.accessType != AccessType.CREATABLE){
            current.decision = getDecision(AccessType.CREATABLE);
        }
        current.saveResults = Database.insert(
            current.decision.getRecords(), 
            current.options, 
            current.accessLevel
        );
        current.dmlType = DmlType.IS_INSERT;
        List<SObject> newRecords = current.decision.getRecords();
        reset();
        return newRecords;
    }
    
    // upsert
    global List<SObject> doUpsert() {
        if (current.accessType != AccessType.UPSERTABLE){
            current.decision = getDecision(AccessType.UPSERTABLE);
        }
        if (current.fieldToUpsertAgainst == null){
            // use the Id of the first record of records in case records is of type SObject rather than an actual SObject 
            current.fieldToUpsertAgainst = current.records[0].Id?.getSObjectType()
                .getDescribe().fields.getMap().get('Id');
        }
        current.upsertResults = Database.upsert(
            current.decision.getRecords(), 
            current.fieldToUpsertAgainst, 
            current.options.optAllOrNone, 
            current.accessLevel
        );
        current.dmlType = DmlType.IS_UPSERT;
        List<SObject> newRecords = current.decision.getRecords();
        reset();
        return newRecords;
    }

    // update
    global List<SObject> doUpdate(){
        if (current.accessType != AccessType.UPDATABLE){
            current.decision = getDecision(AccessType.UPDATABLE);
        }
        current.saveResults = Database.update(
            current.decision.getRecords(), 
            current.options, 
            current.accessLevel
        );
        current.dmlType = DmlType.IS_UPDATE;
        List<SObject> updatedRecords = current.decision.getRecords();
        reset();
        return updatedRecords;
    }

    // delete
    global List<Database.DeleteResult> doDelete(){
        current.hasDmlTarget();
        List<Database.DeleteResult> deleteResults = Database.delete(
            current.records,
            current.options.optAllOrNone,
            current.accessLevel
        );
        current.deleteResults = deleteResults;
        current.dmlType = DmlType.IS_DELETE;
        reset();
        return deleteResults;
    }

    // undelete from record 
    global List<Database.UndeleteResult> doUndelete(){
        current.hasDmlTarget();
        List<Database.UndeleteResult> undeleteResults = Database.undelete(
            current.records, 
            current.options.optAllOrNone, 
            current.accessLevel
        );
        current.undeleteResults = undeleteResults;
        current.dmlType = DmlType.IS_UNDELETE;
        reset();
        return undeleteResults;
    }

    // merge 

    // convert

    // async functions - will do these when we come to need them 

    //email handler
    global List<Messaging.SendEmailResult> sendEmail(List<Messaging.SingleEmailMessage> email, Boolean allOrNothing){
        //https://salesforce.stackexchange.com/questions/237458/messaging-sendemailresult-type-cannot-be-constructed
        return Messaging.sendEmail(email, allOrNothing);
    }

    global class DmlResult{
        global List<Id> ids {
            public set{
                ids = value;
                if (this.records == null){
                    this.records = new List<SObject>();
                }
                this.records.clear();
                for (Id id : ids){
                    records.add(id.getSobjectType().newSObject(id));
                }
            }
            get;
        }
        global List<SObject> records {get; public set;}
        global Dml.DmlType dmlType {get; public set;}
        global Database.DMLOptions options {get; public set;} // all or none is always in options regardless of dml type
        global List<Database.SaveResult> saveResults {get; public set;}
        global List<Database.UpsertResult> upsertResults {get; public set;}
        global List<Database.DeleteResult> deleteResults {get; public set;}
        global List<Database.UndeleteResult> undeleteResults {get; public set;}
        global SObjectAccessDecision decision {get; public set;}
        global System.AccessLevel accessLevel {get; public set;}
        global Schema.SObjectField fieldToUpsertAgainst {get; public set;}
        global System.AccessType accessType {get; public set;}

        DmlResult(){
            options = new Database.DMLOptions();
            options.OptAllOrNone = true; // this is the default dml behaviour when using the APEX keywords
            accessLevel = System.AccessLevel.USER_MODE;
        }

        public void hasDmlTarget(){
            Boolean errorIt = false;
            String message = 'No records to action';
            if (this.records == null) {
                errorIt = true;
            } else if (this.records.size() == 0) {
                errorIt = true;
            }
            if (errorIt) {
                throw new DmlException(message);
            }
        }
    }

    global DmlResult getLastResult(){
        return results[results.size() - 1];
    }

    global enum DmlType {
        IS_INSERT,
        IS_UPDATE,
        IS_UPSERT, 
        IS_DELETE,
        IS_UNDELETE,
        IS_DECISION
    }
}