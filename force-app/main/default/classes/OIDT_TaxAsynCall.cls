public class OIDT_TaxAsynCall implements Queueable,Database.AllowsCallouts  {
	
	public String recordId;    
    public void execute(QueueableContext context) {
         OIDT_OneSourceTaxGenCtrl.getTaxFields(recordId,false);
    }
}