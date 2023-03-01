/************************************************************************************************************************************
    Author 		: Shobhit Gahlot
    Description : This class will have the logic to perform dmls on list of sobjects
	Issue		: ST-6416
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION					DATE					AUTHOR							DETAIL
    1					    12 June, 2020		    Shobhit Gahlot               	Initial Development
*************************************************************************************************************************************/
public class QueueDmlOnSobjects implements Queueable, Callable {
    private List<sObject> lstSobjectsForDml;
    private Boolean isDeleteDml = false;
    private Boolean isUpdateDml = false;
    private Boolean isInsertDml = false;
    private Boolean isUnDeleteDml = false;
    private Boolean allowPartialSave = false;
    public final String ERROR_MESSAGE = 'Please pass the list of sobjects in first parameter of QueueDmlOnSobjects class to perform dml.';

    public QueueDmlOnSobjects(){}

    public QueueDmlOnSobjects(List<sObject> lstSobjects, Boolean isDelete, Boolean isUpdate, Boolean isInsert, Boolean isUnDelete, Boolean allowPartialSave){
        this.lstSobjectsForDml = lstSobjects;
        this.isDeleteDml = isDelete;
        this.isUpdateDml = isUpdate;
        this.isInsertDml = isInsert;
        this.isUnDeleteDml = isUnDelete;
        this.allowPartialSave = allowPartialSave;
    }

    public QueueDmlOnSobjects call(String action, Map<String, Object> args) {
        return new QueueDmlOnSobjects((List<sObject>)args.get('SObjects'), (Boolean)args.get('isDelete'), (Boolean)args.get('isUpdate'), (Boolean)args.get('isInsert'), (Boolean)args.get('isUndelete'), (Boolean)args.get('allowPartialSave'));
    }

    public void execute(QueueableContext qc) {
        try{
            if(this.lstSobjectsForDml == null || this.lstSobjectsForDml.isEmpty()){
                throw new QueueDmlOnSobjectsException(this.ERROR_MESSAGE);
            }
            if(this.lstSobjectsForDml != null && !this.lstSobjectsForDml.isEmpty()){
                if(this.isInsertDml){
                    Database.insert(this.lstSobjectsForDML , this.allowPartialSave);
                }else if(this.isUpdateDml){
                    Database.update(this.lstSobjectsForDML , this.allowPartialSave);
                }else if(this.isDeleteDml){
                    Database.delete(this.lstSobjectsForDML , this.allowPartialSave);
                }else if(this.isUnDeleteDml){
                    Database.undelete(this.lstSobjectsForDML , this.allowPartialSave);
                }
            }
        }catch(Exception ex){
            ApexDebugLog.logException(ex, JSON.serializePretty(this.lstSobjectsForDml), 'QueueDmlOnSobjects', 'execute');
            throw new QueueDmlOnSobjectsException(ex.getMessage());
        }
    }
    public class QueueDmlOnSobjectsException extends Exception{}
}