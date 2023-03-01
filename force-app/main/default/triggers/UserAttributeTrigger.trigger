/**
 * @File Name          : UserAttributeTrigger.trigger
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Ashish Sharma
 * @Last Modified On   : 01/15/2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    8/31/2019   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
trigger UserAttributeTrigger on User_Attribute__c (before insert, before update, after insert, after update, before delete) { 
    new MetadataDrivenTriggerHandler().run();
}