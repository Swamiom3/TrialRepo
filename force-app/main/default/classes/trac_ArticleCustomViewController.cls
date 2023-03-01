/**
 * @description Controller class for ArticleCustomViewComponent
 * @name trac_ArticleCustomViewController 
 * @author Shubham Jain, Traction on Demand
 * @date 2020-01-31
 */
 
public class trac_ArticleCustomViewController {
    
    @AuraEnabled
    public static Knowledge__kav getArticleDetails(Id articleId) {
        Knowledge__kav article = [SELECT Id, Title, Body__c, ArticleTotalViewCount
                                  FROM Knowledge__kav
                                  WHERE Id =: articleId LIMIT 1 UPDATE VIEWSTAT];
        return article;
    }
    
}