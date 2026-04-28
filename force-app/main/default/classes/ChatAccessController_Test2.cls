@istest
public with sharing class ChatAccessController_Test2 {
    @testsetup
    public static void makeData(){
        try{
            PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'CompliantDataSharingPsl' LIMIT 1];
            PermissionSetLicenseAssign psla = new PermissionSetLicenseAssign(AssigneeId = UserInfo.getUserId(), PermissionSetLicenseId = psl.Id);
            insert psla;
        }catch(Exception e){
            System.debug('current user already has the permission set license');
        }
    }


    @istest
    public static void checkCurrentUserAccessNoChatViewAllSuccess(){
        FundingAward fa = new FundingAward();
        insert fa;
        ParticipantRole pr = [SELECT Id FROM ParticipantRole LIMIT 1];

        FundingAwardParticipant fap = new FundingAwardParticipant();
        fap.ParticipantId = UserInfo.getUserId();
        fap.FundingAwardId = fa.Id;
        fap.ParticipantRoleId = pr.Id;
        insert fap;

        Boolean hasAccess = false;
        ChatAccessController cac = new ChatAccessController();
        Test.startTest();
        hasAccess = cac.checkCurrentUserAccess(fa.Id);
        Test.stopTest();
        Assert.isTrue(hasAccess, 'Expect the current user to have access to this funding award');
    }
}