@isTest
public class GmsLoginReminderFlowAction_Test {
    @isTest
    public static void callFlowAction() {
        //Call invocable flow action
        Test.startTest();
        GmsLoginReminderFlowAction.loginReminderFlowAction();
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, ApexClass.Name, JobType
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'GmsLoginReminderEmailHandler'
        ];

        System.assertEquals(1, jobs.size(),'No GmsLoginReminderEmailHandler found in apex jobs');
    }
}