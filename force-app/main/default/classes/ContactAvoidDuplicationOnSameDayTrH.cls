/*********************************************************************************************************
	Author        :  Swami Onkar 
	Description   :  handlet class for Avoid duplicate creating of contact on same day
	Issue No.     :  
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE             AUTHOR             DETAIL
	1          27-feb-2023        Swami Onkar       Trigger Refactor
**********************************************************************************************************/

public class ContactAvoidDuplicationOnSameDayTrH extends sObjectTriggerHandler {
    @TestVisible
    private List<Contact> newContact;
    public ContactAvoidDuplicationOnSameDayTrH(){
        this((List<Contact>) Trigger.new);
    }
    public ContactAvoidDuplicationOnSameDayTrH(List <Contact> newContact){
        this.newContact = newContact;
    }
    public override void beforeInsert(){
        avoidDuplicationContact();
        System.debug('this is trigger class for checking trigger is working or not  avoidDuplicationContact method');
    }
    public void avoidDuplicationContact(){
        System.debug('this is trigger class for checking trigger is working or not ');
        List<Contact> contactList = [select id , LastName from Contact Where CreatedDate = today ];
        //List<String> EmailList = new List<String>();
        List<String> LastNameList = new List<String>();
        if(!contactList.isEmpty()){
            for(Contact objContact : contactList){
                //EmailList.add(objContact.Email);
                LastNameList.add(objContact.LastName);
            }
        }
        for(Contact objContact : newContact){
            if(/*EmailList.contains(objContact.Email) && */LastNameList.contains(objContact.LastName)){
                objContact.addError('You Cannot Create New Contact Because You created already today itself');
            }
        }
    } 
}