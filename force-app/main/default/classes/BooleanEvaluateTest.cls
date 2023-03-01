/************************************************************************************************************************************
Author      :   Rupesh Patil
Description :   This class contain test methods related to BooleanEvaluate class.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           14 May 2019        Rupesh Patil         	Initial Developement
**************************************************************************************************************************************/
@isTest
public class BooleanEvaluateTest {
    
    /************************************************************************************************************************************
        Author          : Rupesh Patil  
        Description     : This Method is used to verify Boolean evaluate.
        Created Date    : 15 May 2019
        Issue No        : ST-3966
    **************************************************************************************************************************************/
    public static testMethod void verifyBooleanEvaluate(){
        String expression = '1 || 2 || 3';
        Map<Integer, Boolean> mapBooleanValues = new Map<Integer, Boolean>();
        mapBooleanValues.put(1, false);
        mapBooleanValues.put(2, false);
        mapBooleanValues.put(3, false);
        BooleanEvaluate objBooleanEvaluate = new BooleanEvaluate(expression, mapBooleanValues);
        Boolean result = objBooleanEvaluate.evaluate();
        System.assert(!result);
        expression = '1 && 2 && 3';
        mapBooleanValues.clear();
        mapBooleanValues.put(1, true);
        mapBooleanValues.put(2, true);
        mapBooleanValues.put(3, true);
        objBooleanEvaluate = new BooleanEvaluate(expression, mapBooleanValues);
        result = objBooleanEvaluate.evaluate();
        System.assert(result);
        expression = '1 && (2 || 3)';
        mapBooleanValues.clear();
        mapBooleanValues.put(1, true);
        mapBooleanValues.put(2, true);
        mapBooleanValues.put(3, false);
        objBooleanEvaluate = new BooleanEvaluate(expression, mapBooleanValues);
        result = objBooleanEvaluate.evaluate();       
        System.assert(result);
        mapBooleanValues.clear();
        objBooleanEvaluate = new BooleanEvaluate(expression, mapBooleanValues);
        result = objBooleanEvaluate.evaluate();
        System.assert(result);
    }
}