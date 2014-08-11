global class EventDecorator {

    global Long externalId {get; set;}
    global DateTime startTime {get; set;}
    global String location {get; set;}
    global String name {get; set;}
    global String smsKeys {get; set;}

    global EventDecorator(Event__c rec)
    {
		externalId = Long.valueOf(rec.External_ID__c);
		startTime = rec.Start_Time__c;
		location = rec.Location__c;
		name = rec.Name;
		smsKeys = rec.SMS_Keys__c;
    }
}