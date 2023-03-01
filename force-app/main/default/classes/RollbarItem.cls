/*************************************************************************************************************************************
    Author      :   Rashad Saeed
    Description :   Class for RollbarItem wrapper.
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR          DETAIL
    1          31 Dec, 2018    Rashad Saeed    Initial Deployment - WeWork SF-Rollbar Integration Google Doc
**************************************************************************************************************************************/
public class RollbarItem {
    public String fileName {get; private set;}
    public String className {get; private set;}
    public String methodName {get; private set;}
    public Decimal lineNumber {get; private set;}
    public String exceptionClass {get; private set;}
    public String errorMessage {get; private set;}
    public String stackTrace {get; private set;}
    public List<Object> args {get; private set;}
    public Map<String, Object> kwargs {get; private set;}
    public String Login_UserId {get; private set;}
    public RollbarItem (Apex_Debug_Log__c apexDebugLog){
        this.fileName='Apex Error';
        this.className = apexDebugLog.Apex_Class__c;
        this.methodName = apexDebugLog.Method__c;
        this.lineNumber= apexDebugLog.ErrorLineNumber__c;
        this.exceptionClass = apexDebugLog.Apex_Class__c;
        this.errorMessage = apexDebugLog.Message__c;
        this.stackTrace = apexDebugLog.Stack_Trace__c;
        this.Login_UserId = apexDebugLog.Login_UserId__c;
    }
    public Map<String, object> buildRollbarItemMessage(String key, String env) {
        return new Map<String, Object>{
            'payload' => new Map<String, Object>{
                'access_token' => key,
                    'data' => new Map<String, Object>{
                        'environment' => env,
                            'body' => new Map<String, Object>{
                                'trace' => new Map<String, Object>{
                                    'frames' => new List<Map<String, Object>>{
                                        new Map<String, Object>{
                                            'filename' => fileName,
                                                'class_name' => className,
                                                'method' => methodName,
                                                'lineno' => lineNumber,
                                                'varargspec' => args,
                                                'keywordspec' => kwargs,
                                                'LoginUserId' => Login_UserId
                                                }
                                    },
                                        'exception' => new Map<String, Object>{
                                            'class' => exceptionClass,
                                                'message' => errorMessage,
                                                'description' => stackTrace
                                                }
                                }
                            }
                    }
            }
        };
    }
}