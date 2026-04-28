@IsTest
public with sharing class Dml_Test {

    @TestSetup
    static void makeData(){
        // create data for undelete methods 
        Dml dml = new Dml();
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 30; i+=1){
            Account a = new Account(Name = 'test' + i.format());
            accounts.add(a);
        }
        dml.setTarget(accounts).doInsert();
    }

    // set access level
    @IsTest
    public static void setAccessLevel(){
        Dml dml = new Dml();
        Test.startTest();
        dml.setAccessLevel(System.AccessLevel.SYSTEM_MODE);
        Test.stopTest();
        Assert.areEqual(System.AccessLevel.SYSTEM_MODE, dml.current.accessLevel, 'dml access level'); 
    }

    // set options 
    @IsTest
    public static void setOptions(){
        Dml dml = new Dml();
        Database.DMLOptions options = new Database.DMLOptions();
        options.optAllOrNone = false;
        Test.startTest();
        dml.setOptions(options);
        Test.stopTest();
        Assert.isFalse(dml.current.options.optAllOrNone, 'dml options'); 
    }   

    @IsTest
    public static void setOptions_allOrNoneNull(){
        Dml dml = new Dml();
        Database.DMLOptions options = new Database.DMLOptions();
        Test.startTest();
        dml.setOptions(options);
        Test.stopTest();
        Assert.isTrue(dml.current.options.optAllOrNone, 'dml options'); 
    } 

    @IsTest
    public static void setAllOrNone(){
        Dml dml = new Dml();
        Test.startTest();
        dml.setAllOrNone(false);
        Test.stopTest();
        Assert.isFalse(dml.current.options.optAllOrNone, 'dml options all or none'); 
    }

    @IsTest
    public static void setAllowFieldTruncation(){
        Dml dml = new Dml();
        Test.startTest();
        dml.setAllowFieldTruncation(true);
        Test.stopTest();
        Assert.isTrue(dml.current.options.allowFieldTruncation, 'dml options allow field truncation'); 
    }

    @IsTest
    public static void setAssignmentRuleHeader(){
        Dml dml = new Dml();
        Id assignmentRuleId = Stub.getId();
        Test.startTest();
        dml.setAssignmentRuleHeader(assignmentRuleId);
        Test.stopTest();
        Assert.isFalse(dml.current.options.assignmentRuleHeader.useDefaultRule, 'dml options assignment rule header use default rule'); 
        Assert.areEqual(assignmentRuleId, dml.current.options.assignmentRuleHeader.assignmentRuleId, 'dml options assignment rule header assignment rule id'); 
    }

    @IsTest
    public static void useDefultAssignmentRuleHeader(){
        Dml dml = new Dml();
        Test.startTest();
        dml.useDefultAssignmentRuleHeader();
        Test.stopTest();
        Assert.isTrue(dml.current.options.assignmentRuleHeader.useDefaultRule, 'dml options assignment rule header use default rule'); 
    }

    @IsTest
    public static void setEmailHeader(){
        Dml dml = new Dml();
        Database.DmlOptions.EmailHeader emailHeader = new Database.DmlOptions.EmailHeader();
        emailHeader.TriggerAutoResponseEmail = true;
        Test.startTest();
        dml.setEmailHeader(emailHeader);
        Test.stopTest();
        Assert.isTrue(dml.current.options.EmailHeader.TriggerAutoResponseEmail, 'dml all or none'); 
    }

    @IsTest
    public static void setLocale(){
        Dml dml = new Dml();
        Test.startTest();
        dml.setLocale('en_GB');
        Test.stopTest();
        Assert.areEqual(dml.current.options.localeOptions, 'en_GB', 'local set'); 
    }

    @IsTest
    public static void setUpsertFields(){
        Dml dml = new Dml();
        Test.startTest();
        dml.setUpsertField(Contact.Id);
        Test.stopTest();
        Assert.areEqual(Contact.Id, dml.current.fieldToUpsertAgainst, 'dml upsert field'); 
    }

    // setTarget

    @IsTest
    public static void setTarget_record(){
        Account a = new Account(Name='setTarget1');
        Dml dml = new Dml();
        Test.startTest();
        dml.setTarget(a);
        Test.stopTest();
        Assert.areEqual(1, dml.current.records.size(), 'number of dml records');
    }   

    @IsTest
    public static void setTarget_recordList(){
        Account a = new Account(Name='setTarget2');
        Account a2 = new Account(Name='setTarget3');
        List<Account> accs = new List<Account>{a, a2};
        Dml dml = new Dml();
        Test.startTest();
        dml.setTarget(accs);
        Test.stopTest();
        Assert.areEqual(2, dml.current.records.size(), 'number of dml records');
    }

    @IsTest
    public static void setTarget_Id(){
        Account a = new Account(Name='setTarget4');
        insert a;
       
        Dml dml = new Dml();
        Test.startTest();
        dml.setTarget(a.Id);
        Test.stopTest();
        Assert.areEqual(1, dml.current.records.size(), 'number of dml records');
    }

    @IsTest
    public static void setTarget_IdList(){
        Account a = new Account(Name='setTarget6');
        Account a2 = new Account(Name='setTarget7');
        List<Account> accs = new List<Account>{a, a2};
        insert accs;
        List<Id> ids = new List<Id>();
        for (Account acc :accs){
            ids.add(acc.Id);
        }
        Dml dml = new Dml();
        Test.startTest();
        dml.setTarget(ids);
        Test.stopTest();
        Assert.areEqual(2, dml.current.records.size(), 'number of dml records');
    }

    // insert 
    @IsTest
    public static void doInsert(){
        Account a = new Account(Name = 'single');
        Dml dml = new Dml();
        Test.startTest();
        List<Account> aAfter = dml.setTarget(a).doInsert();
        Test.stopTest();
        Assert.isNotNull(aAfter[0].Id, 'account Id');
    }

    // upsert
    @IsTest
    public static void doUpsert(){
        Account a = new Account(Name ='upsertSingle1');
        insert a;
        Dml dml = new Dml();
        Test.startTest();
        List<Account> aAfter = dml.setTarget(a.Id).doUpsert();
        Test.stopTest();
        Assert.isNotNull(aAfter[0].Id, 'account Id');
    }

    // update
    @IsTest
    public static void doUpdate(){
        Account a = new Account(Name = 'single');
        Dml dml = new Dml();
        List<Account> insertedA = dml.setTarget(a).doInsert();
        String updatedName = 'single updated 1';
        insertedA[0].Name = updatedName;
        Test.startTest();
        List<Account> aAfter = dml.setTarget(insertedA).doUpdate();
        Test.stopTest();
        Assert.areEqual(updatedName, aAfter[0].Name, 'account Name');
    }

    // delete 
    @IsTest
    public static void doDelete(){
        Account a = new Account(Name = 'delete1');
        Dml dml = new Dml();
        List<Account> aAfterInsert = dml.setTarget(a).doInsert();
        Test.startTest();
        List<Database.DeleteResult> dr = dml.setTarget(aAfterInsert).doDelete();
        Test.stopTest();
        Assert.isTrue(dr[0].isSuccess(), 'delete result is a success');
    }

    // undelete
    @IsTest
    public static void doUndelete_id_single(){
        Selector selector = new Selector();
        Dml dml = new Dml();
        List<Account> accounts = selector.query('SELECT Id FROM Account LIMIT 1');
        Account a = accounts[0];
        dml.setTarget(a).doDelete();
        Test.startTest();
        List<Database.UndeleteResult> ur = dml.setTarget(a.Id).doUndelete();
        Test.stopTest();
        Assert.isTrue(ur[0].isSuccess(), 'the undelete result isSuccess');
    }

    @IsTest
    public static void lastResult(){
        Account a = new Account(Name = 'lastResult1');
        Dml.DmlType testType = Dml.DmlType.IS_INSERT;
        Dml dml = new Dml();
        dml.setAccessLevel(System.AccessLevel.SYSTEM_MODE);
        dml.setTarget(a).doInsert();
        Test.startTest();
        Dml.DmlResult result = dml.getLastResult();
        Test.stopTest();
        Assert.areEqual(System.AccessLevel.SYSTEM_MODE, result.accessLevel, 'access level the result stores');
        Assert.areEqual(testType, result.dmlType, 'the results dmlType');
    }

    @IsTest
    public static void delete_byId_multiObjects(){
        Contact c = new Contact(LastName = 'test');
        insert c;
        Account a = new Account(Name = 'test');
        insert a;
        List<Id> ids = new List<Id>{c.Id, a.Id};
        Test.startTest();
        Database.delete(ids);
        Test.stopTest();
    }

    @IsTest
    public static void actOnNothing(){
        String message;
        Dml dml = new Dml();
        Test.startTest();
        try{
            dml.doInsert();
        }catch(Exception e){
            message = e.getMessage();
        }
        Test.stopTest();
        Assert.areEqual('No records to action', message, 'the error message');
    }

    @IsTest
    public static void actOnEmptyList(){
        String message;
        Dml dml = new Dml();
        Test.startTest();
        try{
            dml.setTarget(new List<SObject>()).doInsert();
        }catch(Exception e){
            message = e.getMessage();
        }
        Test.stopTest();
        Assert.areEqual('No records to action', message, 'the error message');
    }
}