public without sharing class MessageEventTriggerHandler {

    public static final String INTERNAL_LICENSE_KEY = 'SFDC';
    @TestVisible
    private static Map<Id, UserLicense> userLicences;
    private static Date snapshotPeriod;
    private static List<Message_Event__e> newMessages;
    @TestVisible
    private static Map<Id, User> users;
    @TestVisible
    private static Id businessHoursId; 

    public static List<Message_Event__e> onAfterInsert(List<Message_Event__e> newMessages){
        MessageEventTriggerHandler.newMessages = newMessages;
        userLicences = new Map<Id, UserLicense>([SELECT Id, LicenseDefinitionKey FROM UserLicense WHERE LicenseDefinitionKey = :INTERNAL_LICENSE_KEY]);
        businessHoursId = [SELECT Id, Name, IsActive, IsDefault FROM BusinessHours WHERE Name = 'Default' LIMIT 1].Id;
        snapshotPeriod = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        
        // get id sets for selects 
        Set<Id> userIds = new Set<Id>();
        Set<Id> fundingAwardIds = new Set<Id>();
        Map<Id, Message_Event__e> childContextIds = new Map<Id, Message_Event__e>();
        Map<Id, List<Message_Event__e>> readChildContexts = new Map<Id, List<Message_Event__e>>();

        for (Message_Event__e message : newMessages){
            userIds.add(message.Author__c);
            if (message.Is_Read__c){
                List<Message_Event__e> events = readChildContexts?.get(message?.Context_Child__c) ?? new List<Message_Event__e>();
                events.add(message);
                readChildContexts.put(message.Context_Child__c, events);
            }else{
                fundingAwardIds.add(message.Context_Parent__c);
                childContextIds.put(message.Context_Child__c, message);
            }
        }
        if (userIds.size() > 0){
            users = new Map<Id, User>([SELECT Id, Profile.UserLicenseId FROM User WHERE Id IN :userIds]);
        }
        if (childContextIds.size() > 0){
            sortNewMessages(userIds, fundingAwardIds, childContextIds);
        }
        if (readChildContexts.size() > 0){
            sortReadMessages(readChildContexts);
        }
        return newMessages;
    }

    public static List<Message__c> sortReadMessages(Map<Id, List<Message_Event__e>> readChildContexts){
        
        Map<String, Object> bindParams = new Map<String, Object>{'childContextIds'=>readChildContexts.keySet()}; 
        List<String> snapshotFields = new List<String>(Schema.Messaging_Snapshot_Child__c.SObjectType.getDescribe().fields.getMap().keySet());
        String snapshotQuery = 'SELECT ' + String.join(snapshotFields, ',') 
            + ', (SELECT Id, Is_Read__c, Time_to_Read__c, When__c, Author__c, Type__c FROM Messages__r WHERE Is_Read__c = false)'
            + ' FROM Messaging_Snapshot_Child__c' 
            + ' WHERE Context_Child__c IN :childContextIds AND'
            + ' Id IN (SELECT Messaging_Snapshot_Child__c FROM Message__c WHERE Is_Read__c = false)';
        Map<Id, Messaging_Snapshot_Child__c> childSnapshots = new Map<Id, Messaging_Snapshot_Child__c>(
            (List<Messaging_Snapshot_Child__c>)Database.queryWithBinds(
                snapshotQuery, 
                bindParams, 
                AccessLevel.SYSTEM_MODE
            ));

        List<Messaging_Snapshot_Child__c> snapshotsForUpdate = new List<Messaging_Snapshot_Child__c>();
        List<Message__c> messagesForUpdate = new List<Message__c>();

        for (Messaging_Snapshot_Child__c snapshot : childSnapshots.values()){
            if (snapshot.Messages__r.size() > 0){
                Decimal totalReadTime = (snapshot.Average_Read_Time_By_DP__c ?? 0) * (snapshot.Number_Of_Messages_Read_By_DP__c ?? 0);
                Integer readMessageCount = (Integer)(snapshot.Number_Of_Messages_Read_By_DP__c ?? 0);
                List<Message_Event__e> events = readChildContexts.get(snapshot.Context_Child__c);
                for (Message__c message : snapshot.Messages__r){
                    Message_Event__e readEvent = findMessageRead(message, events);
                    if (readEvent != null){
                        message.Is_Read__c = true;
                        Long diff = BusinessHours.diff(businessHoursId, message.When__c, readEvent.When__c);
                        message.Time_to_Read__c = (diff)/1000;
                        if (message.Type__c == 'External'){ // if it's an external message being read it's a internal person reading it
                            totalReadTime += message.Time_to_Read__c;
                            readMessageCount += 1;
                        }
                        messagesForUpdate.add(message);
                    }
                }
                if (readMessageCount > 0 && totalReadTime > 0){
                    snapshot.Average_Read_Time_By_DP__c = totalReadTime / readMessageCount;
                    snapshot.Number_Of_Messages_Read_By_DP__c = readMessageCount;
                    snapshotsForUpdate.add(snapshot);
                }
            }
        }
        update snapshotsForUpdate;
        update messagesForUpdate;
        return messagesForUpdate;
    }

    @TestVisible
    private static Message_Event__e findMessageRead(Message__c message, List<Message_Event__e> events){
        System.debug(message.Type__c);
        for (Message_Event__e event : events){
            System.debug(getEventType(event.Author__c));
            if (message.Type__c != getEventType(event.Author__c)){
                return event;
            }      
        }
        return null;
    }

    public static List<Message_Event__e> sortNewMessages(Set<Id> userIds, Set<Id> fundingAwardIds, Map<Id, Message_Event__e> childContextIds){
        // get all the fields everytime 
        Map<Id, Messaging_Snapshot__c> snapshots = handleSnapshotUpdates(fundingAwardIds);
        Map<Id, Messaging_Snapshot_Child__c> childSnapshots = handleChildSnapshotUpdates(childContextIds, snapshots);

        List<Message__c> messages = new List<Message__c>();
        for (Message_Event__e event : newMessages){
            Message__c message = new Message__c();
            // add in check for isread here 
            message.Author__c = event.Author__c;
            message.Type__c = getEventType(message.Author__c);
            message.Case__c = event.Escalation__c;
            message.Funding_Award__c = event.Context_Parent__c;
            message.Message__c = event.Message__c;
            message.When__c = event.When__c;
            // all events should have an upserted snapshot at this point 
            message.Messaging_Snapshot__c = snapshots?.get(event.Context_Parent__c)?.Id;
            message.Messaging_Snapshot_Child__c = childSnapshots?.get(event.Context_Child__c)?.Id;
            message.Message_Id__c = event.Message_Id__c;
            messages.add(message);
        }
        upsert messages Message_Id__c;
        return newMessages;
    }

    public static Map<Id, Messaging_Snapshot__c> handleSnapshotUpdates(Set<Id> fundingAwardIds){
        
        Map<String, Object> bindParams = new Map<String, Object>{'fundingAwardIds'=>fundingAwardIds, 'snapshotPeriod'=>snapshotPeriod}; 
        List<String> snapshotFields = new List<String>(Schema.Messaging_Snapshot__c.SObjectType.getDescribe().fields.getMap().keySet());
        String snapshotQuery = 'SELECT ' + String.join(snapshotFields, ',') + ' FROM Messaging_Snapshot__c WHERE Funding_Award__c IN :fundingAwardIds AND Start__c =:snapshotPeriod';
        Map<Id, Messaging_Snapshot__c> snapshots = new Map<Id, Messaging_Snapshot__c>(
            (List<Messaging_Snapshot__c>)Database.queryWithBinds(
                snapshotQuery, 
                bindParams, 
                AccessLevel.SYSTEM_MODE
            ));
        
        Map<Id, Messaging_Snapshot__c> fundingSnapshots = new Map<Id, Messaging_Snapshot__c>();
        for (Messaging_Snapshot__c snapshot : snapshots.values()){
            fundingSnapshots.put(snapshot.Funding_Award__c, snapshot);
        }
        List<Messaging_Snapshot__c> newSnapshots = new List<Messaging_Snapshot__c>();
        for (Message_Event__e event : MessageEventTriggerHandler.newMessages){
            Messaging_Snapshot__c snapshot = fundingSnapshots?.get(event.Context_Parent__c);
            
            if (snapshot == null){
                snapshot = new Messaging_Snapshot__c();
                snapshot.Start__c = snapshotPeriod;
                snapshot.Funding_Award__c = event.Context_Parent__c;
                snapshot.Status__c = 'Current';
                snapshot.Snapshot_Id__c = event.Context_Parent__c + String.valueOf(snapshotPeriod);
                fundingSnapshots.put(event.Context_Parent__c, snapshot);
                newSnapshots.add(snapshot);
            }
        }
        if (newSnapshots.size() > 0){
            upsert newSnapshots Snapshot_Id__c;
        }
        return fundingSnapshots;
    }

    public static Map<Id, Messaging_Snapshot_Child__c> handleChildSnapshotUpdates(Map<Id, Message_Event__e> childContextIds, Map<Id, Messaging_Snapshot__c> snapshots){

        Map<String, Object> bindParams = new Map<String, Object>{'childContextIds'=>childContextIds.keySet(), 'snapshotPeriod'=>snapshotPeriod}; 
        List<String> snapshotFields = new List<String>(Schema.Messaging_Snapshot_Child__c.SObjectType.getDescribe().fields.getMap().keySet());
        String snapshotQuery = 'SELECT ' + String.join(snapshotFields, ',') 
            + ', (SELECT Id, Is_Responded__c, Time_to_Respond__c, When__c, Author__c, Type__c FROM Messages__r WHERE Is_Responded__c = false)'
            + ' FROM Messaging_Snapshot_Child__c WHERE Context_Child__c IN :childContextIds AND Start__c =:snapshotPeriod';
        Map<Id, Messaging_Snapshot_Child__c> childSnapshots = new Map<Id, Messaging_Snapshot_Child__c>(
            (List<Messaging_Snapshot_Child__c>)Database.queryWithBinds(
                snapshotQuery, 
                bindParams, 
                AccessLevel.SYSTEM_MODE
            ));
        Map<Id, Messaging_Snapshot_Child__c> contextSnapshots = new Map<Id, Messaging_Snapshot_Child__c>();

        List<Message__c> messagesToUpdate = new List<Message__c>();

        for (Messaging_Snapshot_Child__c childSnapshot : childSnapshots.values()){
            contextSnapshots.put(childSnapshot.Context_Child__c, childSnapshot);
            Integer numberOfMessagesRespondedTo = 0;
            Decimal totalResponseTime = 0;
            
            for (Message__c message : childSnapshot.Messages__r){
                if (message.Type__c != getEventType(childContextIds?.get(childSnapshot?.Context_Child__c)?.Author__c)){
                    message.Is_Responded__c = true;
                    Long diff = BusinessHours.diff(businessHoursId, message?.When__c, childContextIds?.get(childSnapshot?.Context_Child__c)?.When__c);
                    Decimal responseTime = (diff)/1000;
                    if (message.Type__c == 'External'){
                        totalResponseTime += responseTime;
                        numberOfMessagesRespondedTo += 1;
                    }
                    message.Time_to_Respond__c = responseTime;
                    messagesToUpdate.add(message);
                }
            }

            if (numberOfMessagesRespondedTo > 0){
                if (childSnapshot.Number_Of_Messages_Responded_To_By_DP__c == null){
                    childSnapshot.Number_Of_Messages_Responded_To_By_DP__c = numberOfMessagesRespondedTo;
                    childSnapshot.Average_Response_Time_By_DP__c = totalResponseTime/numberOfMessagesRespondedTo;
                }else{
                    totalResponseTime += ((childSnapshot?.Average_Response_Time_By_DP__c ?? 0) * (childSnapshot?.Number_Of_Messages_Responded_To_By_DP__c ?? 0));
                    childSnapshot.Number_Of_Messages_Responded_To_By_DP__c += numberOfMessagesRespondedTo;
                    childSnapshot.Average_Response_Time_By_DP__c = totalResponseTime/childSnapshot.Number_Of_Messages_Responded_To_By_DP__c;
                }
            }
        }
        update messagesToUpdate;

        for (Message_Event__e event : MessageEventTriggerHandler.newMessages){
            Messaging_Snapshot_Child__c childSnapshot = contextSnapshots?.get(event.Context_Child__c);
            if (childSnapshot == null){
                childSnapshot = new Messaging_Snapshot_Child__c();
                childSnapshot.Start__c = snapshotPeriod;
                childSnapshot.Funding_Award__c = event.Context_Parent__c;
                childSnapshot.Status__c = 'Current';
                childSnapshot.Number_Of_Messages__c = 1;
                childSnapshot.Snapshot_Id__c = event.Context_Child__c + String.valueOf(snapshotPeriod);
                childSnapshot.Context_Child__c = event.Context_Child__c;
                childSnapshot.Context_Child_Object__c = ((Id)event?.Context_Child__c)?.getSObjectType()?.getDescribe()?.label;
                childSnapshot.Messaging_Snapshot__c = snapshots?.get(event.Context_Parent__c)?.Id;
                contextSnapshots.put(event.Context_Child__c, childSnapshot);
            } else {
                childSnapshot.Number_Of_Messages__c += 1;
            }

            if (getEventType(event.Author__c) == 'External'){
                if (childSnapshot.Number_Of_Unresponded_Messages_By_DP__c == null){
                    childSnapshot.Number_Of_Unresponded_Messages_By_DP__c = 1;
                }else{
                    childSnapshot.Number_Of_Unresponded_Messages_By_DP__c += 1;
                }
            }else{
                childSnapshot.Number_Of_Unresponded_Messages_By_DP__c = 0;
            }
        }   
        upsert contextSnapshots.values() Snapshot_Id__c;
        
        return contextSnapshots;
    }

    public static String getEventType(Id userId){
        if (userLicences?.get(users?.get(userId)?.Profile.UserLicenseId) == null){
            return 'External';
        }
        return 'Internal';
    }

}