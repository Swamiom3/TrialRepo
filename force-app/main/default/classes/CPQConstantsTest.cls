@isTest
public class CPQConstantsTest {
    @isTest
    public static void coverConstructor() {
        new CPQConstants(); 
        System.assert(CPQConstants.WORKSPACE == 'Workspace','workspace value valid');
    }
}