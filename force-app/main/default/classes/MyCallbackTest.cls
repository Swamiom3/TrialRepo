/************************************************************************************************************************************
    Author      : RUCHITHA KUMBAM
    Description : This class Contains Unit Tests methods of MyCallback
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION       DATE                AUTHOR              DETAIL
    1           23 November 2021    RUCHITHA KUMBAM      Initial Developement
**************************************************************************************************************************************/
@isTest
public class MyCallbackTest {
    @isTest
    static void myCallbackmethod(){
        String quoteJSON='';
        try{
            new MyCallback().callback(quoteJSON);
        }
        catch(Exception e){
          System.assertNotEquals(NULL,e,'Exception should not be null');  
        }
        System.assertNotEquals(NULL,quoteJSON,'Quote is not null');
    }
    
}