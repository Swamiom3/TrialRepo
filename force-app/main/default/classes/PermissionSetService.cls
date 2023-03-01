/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class is the service class for fetching permission set for logged in user .
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           13 July 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
public with sharing class PermissionSetService {

   
    public static final String INSIDE_SALES_MANAGER = 'Inside_Sales_Manager';

    /*****************************************************************************************************************************************
        Author              :   Salesforce
        Description         :   This method is used to retrieve the permission set Id of "Inside Sales" for logged in user.
        Created Date        :   13 July 2021
    ******************************************************************************************************************************************/


    public static string getPermissionSetId(Id userId){      
        
       return [SELECT Id, PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Name 
               FROM PermissionSetAssignment 
               WHERE AssigneeId=:userId and PermissionSet.Name=:INSIDE_SALES_MANAGER]?.PermissionSetId;
    }
}