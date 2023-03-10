/**
 * Copyright 2018 OpFocus, Inc
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation 
 * files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
 * modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the 
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
 * IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

public with sharing class RTPL_RecordTypePicklistValuesCtrl {

	static RTPL_Settings__c settings = RTPL_Settings__c.getInstance(UserInfo.getUserId());

	/**
	 * callout to user interface api to get picklist values for given record type
	 * @param  sobjectName    [sobject api name]
	 * @param  recordTypeId   [record type id]
	 * @param  recordTypeName [record type name]
	 * @return                [description]
	 */
	@AuraEnabled
	public static String getPicklistValues(String sobjectName, String recordTypeId, String recordTypeName){
		try{
			HttpRequest req = new HttpRequest();

			// if recordtypeid is null, use recordtype name to get the id
			if(recordTypeId == null){
				if(recordTypeName == null){
					throw new RecordTypeValuesCtrlException('Record Type Name is required is Record Type Id is not supplied');
				}
				try{
					recordTypeId = Schema.getGlobalDescribe().get(sobjectName).getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
				}
				catch(Exception re){
					throw new RecordTypeValuesCtrlException('Record Type Name ' + recordTypeName + ' is invalid for SObject ' + sobjectName);
				}
			}

			String method = 'GET';
			String endpoint = String.format('/services/data/v46.0/ui-api/object-info/{0}/picklist-values/{1}', new String[]{sobjectName, recordTypeId});
//			String endpoint = String.format('/services/data/v46.0/ui-api/object-info/{0}/picklist-values/{1}/{2}', new String[]{sobjectName, recordTypeId, fieldName});

			req.setEndpoint('callout:' + TLOrgConstants.CALL_ME_BACK_NAMED_CREDENTIALS + endpoint);
			req.setMethod(method);

			HttpResponse res = new Http().send(req);
			for(String h : res.getHeaderKeys()){
				System.debug(h + ' => ' + res.getHeader(h));
			}
			System.debug(res.getBody());
			RTPL_PicklistValues pl = (RTPL_PicklistValues) JSON.deserialize(res.getBody(), RTPL_PicklistValues.class);
//			System.debug(JSON.serialize(pl));
			return JSON.serialize(pl);
		}
		catch(Exception e){
			if(!Test.isRunningTest()) throw new AuraHandledException(e.getMessage());
			else throw e;
		}
	}

	public class RecordTypeValuesCtrlException extends Exception{}
}