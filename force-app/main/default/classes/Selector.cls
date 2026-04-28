global with sharing class Selector {
    
    @TestVisible
    System.AccessLevel accessLevel = System.AccessLevel.USER_MODE;

    global Selector setAccessLevel(System.AccessLevel accessLevel){
        this.accessLevel = accessLevel;
        return this;
    }

    global List<SObject> query(String query){
        return query(query, new Map<String, Object>(), AccessType.READABLE);
    }

    global List<SObject> query(String query, AccessType accessType){
        return query(query, new Map<String, Object>(), accessType);
    }

    global List<SObject> query(String query, Map<String, Object> bindParams){
        return query(query, bindParams, AccessType.READABLE);
    }

    global List<SObject> query(String query, Map<String, Object> bindParams, AccessType accessType){
        return decision(query, bindParams, accessType).getRecords();
    }

    global SObjectAccessDecision decision(String query, Map<String, Object> bindParams, AccessType accessType){
        List<SObject> records = Database.queryWithBinds(query, bindParams, accessLevel);
        return Security.stripInaccessible(accessType, records);
    }
}