public without sharing class GmsLoginReminderFlowAction {
    
    @InvocableMethod(label='Login Reminder Action')
    public static void loginReminderFlowAction() {
        GmsLoginReminderEmailHandler handler = new GmsLoginReminderEmailHandler();
        System.enqueueJob(handler);
    }
}