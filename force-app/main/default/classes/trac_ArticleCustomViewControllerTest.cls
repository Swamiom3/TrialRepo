@isTest
public class trac_ArticleCustomViewControllerTest {
 @isTest 
    public static void testKnowledge() { 
        Knowledge__kav k = new Knowledge__kav(URLName = 'Apex-Test-URLName', Title='Test'); 
        Insert k; 
        Knowledge__kav article = trac_ArticleCustomViewController.getArticleDetails(k.id);
    } 
}