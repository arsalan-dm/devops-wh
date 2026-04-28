@IsTest
public with sharing class Selector_Test {
    
    @TestSetup
    static void makeData(){
        Account a1 = new Account(Name ='new account');
        insert a1;
    }

    @IsTest
    public static void query(){
        String query = 'SELECT Id FROM Account';
        Map<String, Object> binds = new Map<String, Object>();
        Selector selector = new Selector();
        Test.startTest();
        List<SObject> results = selector.query(query);
        Test.stopTest();

        Assert.areEqual(Database.queryWithBinds(query, binds, AccessLevel.USER_MODE), results, 'selector returned records');
    }

    @IsTest
    public static void query_accessType(){
        String query = 'SELECT Id FROM Account';
        Selector selector = new Selector();
        Map<String, Object> binds = new Map<String, Object>();
        
        Test.startTest();
        List<SObject> results = selector.query(query, AccessType.READABLE);
        Test.stopTest();

        Assert.areEqual(Database.queryWithBinds(query, binds, AccessLevel.USER_MODE), results, 'selector returned records');
    }

    @IsTest
    public static void query_binds(){
        String query = 'SELECT Id FROM Account WHERE Name = :name';
        Selector selector = new Selector();
        Map<String, Object> binds = new Map<String, Object>();
        binds.put('name', 'new account');
        Test.startTest();
        List<SObject> results = selector.query(query, binds);
        Test.stopTest();

        Assert.areEqual(Database.queryWithBinds(query, binds, AccessLevel.USER_MODE), results, 'selector returned records');
    }

    @IsTest
    public static void query_bindsAndAccessType(){
        String query = 'SELECT Id FROM Account WHERE Name = :name';
        Selector selector = new Selector();
        Map<String, Object> binds = new Map<String, Object>();
        binds.put('name', 'new account');
        Test.startTest();
        List<SObject> results = selector.query(query, binds, AccessType.READABLE);
        Test.stopTest();

        Assert.areEqual(Database.queryWithBinds(query, binds, AccessLevel.USER_MODE), results, 'selector returned records');
    }
    
    @IsTest
    public static void decision(){
        String query = 'SELECT Id FROM Account WHERE Name = :name';
        Selector selector = new Selector();
        Map<String, Object> binds = new Map<String, Object>();
        binds.put('name', 'new account');
        Test.startTest();
        SObjectAccessDecision decision = selector.decision(query, binds, AccessType.READABLE);
        Test.stopTest();
        List<SObject> checkRecords = Database.queryWithBinds(query, binds, AccessLevel.USER_MODE);
        SObjectAccessDecision checkDecision = Security.stripInaccessible(AccessType.READABLE, checkRecords);
        Assert.areEqual(checkDecision.getRecords(), decision.getRecords(), 'security decision');
    } 

    @IsTest
    public static void setAccessLevel(){
        Selector selector = new Selector();
        Test.startTest();
        selector.setAccessLevel(System.AccessLevel.SYSTEM_MODE);
        Test.stopTest();
        Assert.areEqual(System.AccessLevel.SYSTEM_MODE, selector.accessLevel, 'selector access level');
    }

}