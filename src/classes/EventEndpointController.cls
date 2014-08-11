@RestResource(urlMapping='/events/*')
global class EventEndpointController
{
    @HttpGet
    global static void getEvents()
    {   
        
        List<Event__c> events = [SELECT Name, Start_Time__c, SMS_Keys__c, Location__c, External_ID__c FROM Event__c];
        List<EventDecorator> decorators = new List<EventDecorator>();
        for (Event__c event: events)
        {
            decorators.add(new EventDecorator(event));
        }
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(decorators));
    }
    
    global class Result
    {
        global String response {get; set;}
    }
}