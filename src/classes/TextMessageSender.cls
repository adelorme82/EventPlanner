public with sharing class TextMessageSender 
{

    public static final String TWILIO_NUMBER = '+13043978075';
    
    public static void send(Set<String> toNumbers, String message)
    {
        List<SMS_Message__c> messages = new List<SMS_Message__c>();

        for (String toNumber : toNumbers)
        {
            SMS_Message__c sms = new SMS_Message__c();
            sms.From_Number__c = TWILIO_NUMBER;
            sms.To_Number__c = toNumber;
            sms.Body__c = message;
            sms.Type__c = 'Outgoing';
            sms.Sent__c = false;
            messages.add(sms);
        }

        insert messages;
        MassTextMessageSender sender = new MassTextMessageSender();
        Id batchprocessid = Database.executebatch(sender,1);
        System.debug('###batchprocessid: ' + batchprocessid);

    }

}