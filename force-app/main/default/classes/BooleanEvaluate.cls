/************************************************************************************************************************************
Author      :   Nikhil Mehta
Description :   This class contain logic of fetching values of 'Partner Affiliate Leads Metadata' dynamically
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           14 May 2019        Nikhil Mehta       	Initial Developement
**************************************************************************************************************************************/
public with sharing class BooleanEvaluate {
    private String expression;
    private String finalExpression;
    
    public BooleanEvaluate(String expression, Map<Integer, Boolean> mapBooleanValues){       
        this.expression = expression.deleteWhitespace().replaceAll('\\|\\|', 'OR').replaceAll('&&', 'AND');
        this.formatExpression(mapBooleanValues);
    }
	
    /************************************************************************************************************************************
        Author          : Nikhil Mehta
        Description     : This Method is used to pass expression to evaluate expression.
        Created Date    : 14 May 2019
        Issue No        : ST-3966
    **************************************************************************************************************************************/
    public Boolean evaluate(){
        evaluate(this.expression);
        return evaluateExpression(this.finalExpression);
    }
	
    /************************************************************************************************************************************
        Author          : Nikhil Mehta
        Description     : This Method is used to evaluate.
        Created Date    : 14 May 2019
        Issue No        : ST-3966
    **************************************************************************************************************************************/
    private void evaluate(String expression){
        if(!expression.contains('(')){
            this.finalExpression = expression;
            return;
        }

        Integer indexOfOpenBracket = -1;
        Integer indexOfCloseBracket = -1;
        List<String> lstCharaters = expression.split('');
        for(Integer iIndex = 0; iIndex < lstCharaters.size(); iIndex++){
            String singleCharater = lstCharaters[iIndex];
            if(singleCharater.equalsIgnoreCase('(')) {
                indexOfOpenBracket = iIndex;
                continue;
            }
            if(singleCharater.equalsIgnoreCase(')')) {
                indexOfCloseBracket = iIndex;
                break;
            }
        }

        String replace = expression.substring(indexOfOpenBracket + 1 , indexOfCloseBracket);
        expression = expression.replace('(' + replace + ')', String.valueOf(evaluateExpression(replace)));
        evaluate(expression);
    }

	/************************************************************************************************************************************
        Author          : Nikhil Mehta
        Description     : This Method is used to evaluate expression.
        Created Date    : 13 May 2019
        Issue No        : ST-3966
    **************************************************************************************************************************************/    
    private Boolean evaluateExpression(String expression){
        Boolean result = false;
        Boolean temp;
        for(String orSplit : expression.split('OR')){
            temp = true;
            for(String andSplit : orSplit.split('AND')){
                temp &= (andSplit.contains('NOT') ? !Boolean.valueOf(andSplit.replace('NOT', '').trim()) : Boolean.valueOf(andSplit.trim()));
            }
            result |= temp;
        }
        return result;
    }
    
    /************************************************************************************************************************************
        Author          : Nikhil Mehta
        Description     : This Method is used to format expression.
        Created Date    : 13 May 2019
        Issue No        : ST-3966
    **************************************************************************************************************************************/
    private void formatExpression(Map<Integer, Boolean> mapBooleanValues){
        for(String strCharacter : expression.split('')){
            try{
                Integer integerValue = Integer.valueOf(strCharacter);
                if(mapBooleanValues.get(integerValue) != NULL){
                    this.expression = this.expression.replace(strCharacter, String.valueOf(mapBooleanValues.get(integerValue))); 
                }else{
                    this.expression = this.expression.replace(strCharacter, String.valueOf(true));
                }               
            }catch(Exception e){
                continue;
            }
        }
    }
}