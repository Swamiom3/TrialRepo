/*******************************************************************************************
    Class Name: CSVReaderTest
    Description : Test Class for CSVReader
    Created By : Sandilya, 12/2/2021
    Last Modified By : Sangeetha ,  12/2/2021
**********************************************************************************************/
@istest
public class CSVReaderTest {

    @istest
    public static void csvReaderTestMethod(){
        String csvTestStringOne = 'QUOTE data for CSV Reader Class';
        String csvTestStringTwo = 'Test data for CSV Reader Class QUOTE';
        String csvTestStringThree = 'Test data for CSV Reader, Class QUOTE';
        String csvTestStringFour = '"Test data for CSV Reader, Class QUOTE"';
        String testObject = 'QUOTE';
        Test.startTest();
        List<String> readLineOutputOne = CSVReader.ReadLine(csvTestStringOne);
        List<String> readLineOutputTwo = CSVReader.ReadLine(csvTestStringTwo);
        List<String> readLineOutputThree = CSVReader.ReadLine(csvTestStringThree);
        List<String> readLineOutputFour = CSVReader.ReadLine(csvTestStringFour);
        List<List<String>> readLineOutputParse = CSVReader.Parse(csvTestStringOne,testObject);


        Test.stopTest();
        System.assertEquals(2, readLineOutputOne.size() , 'Please add quote at the beginning of sentence');
        System.assertEquals(2, readLineOutputTwo.size(), 'Please add quote at the end of the sentence');
        System.assertEquals(3, readLineOutputThree.size() , 'Please do not add comma in the beginning or end of the text' );
        System.assertEquals(1, readLineOutputParse.size(), 'Please add double quotes to text');
      
    } 

}