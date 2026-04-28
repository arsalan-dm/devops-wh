@istest
public with sharing class SystemUtil_Test {
    @istest
    public static void enqueueJob(){
        SystemUtil systemUtil = new SystemUtil();
        Id jobId;
        Test.startTest();
        jobId = systemUtil.enqueueJob(systemUtil);
        Test.stopTest();
        Assert.isTrue(jobId != null, 'expect job id to not be null');
    }
}