/************************************************************************************************************************************
Author      :   Maciej Miłosz
Description :   This class is a baseline for Data Access Layer. It contains dynamic queries that are secure. Every selector should 
                extend this class. In SObject specific selectors static queries should be used.
Usage       :   eg. ContactSelector extends SObjectSelector
**************************************************************************************************************************************/

public abstract class SObjectSelector {
    public Schema.SObjectType sObjectType;

    @TestVisible
    private List<String> defaultFields;
    private String sObjectName;

    private Object binding0;
    private Object binding1;
    private Object binding2;
    private Object binding3;
    private Object binding4;
    private Object binding5;
    private Object binding6;
    private Object binding7;
    private Object binding8;
    private Object binding9;

    /****************************************************************************************************************************
     Author              : Maciej Miłosz
     Description         : Constructor
     *****************************************************************************************************************************/
    public SObjectSelector(Schema.SObjectType sObjectType){
        this.sObjectType = sObjectType;
        defaultFields = new List<String>(getDefaultFields());
        sObjectName = sObjectType.getDescribe().getName();
    }
    /****************************************************************************************************************************
        Author              : Oleg Krasko
        Description         : This method should be overrided for add required filters in the class which extends this class
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    protected virtual String addRequiredFilters(Boolean isThereWhereClause){
        return '';
    }

    /****************************************************************************************************************************
        Author              : Oleg Krasko
        Description         : This method is used to get SObjects by Id
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    public virtual List<SObject> getSObjectByIds(List<String> fields, List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return null;
        }
        return getSObjectByField(fields, 'Id', ids, false);
    }

    /****************************************************************************************************************************
        Author              : Oleg Krasko
        Description         : This method is used to get SObjects by list of Ids
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    public virtual List<SObject> getSObjectByIds(List<String> fields, Id id){
        if (id == null) {
            return null;
        }
        return getSObjectByField(fields, 'Id', id, false);
    }

    /****************************************************************************************************************************
        Author              : Oleg Krasko
        Description         : This method is used to get SObjects by Name
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    public virtual List<SObject> getSObjectByName(List<String> fields, List<String> names, Boolean isLikeOperator){
        if (names == null || names.isEmpty() || isLikeOperator == null) {
            return null;
        }
        return getSObjectByField(fields, 'Name', names, isLikeOperator);
    }

    /****************************************************************************************************************************
        Author              : Oleg Krasko
        Description         : This method is used to get SObjects by list of Names
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    public virtual List<SObject> getSObjectByName(List<String> fields, String name, Boolean isLikeOperator){
        if (String.isBlank(name) || isLikeOperator == null) {
            return null;
        }
        return getSObjectByField(fields, 'Name', name, isLikeOperator);
    }

    /****************************************************************************************************************************
        Author              : Oleg Krasko
        Description         : This method is used to get SObjects without filters
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    public virtual List<SObject> getSObjectsWithoutFilters(List<String> fields){
        return getSObjects(fields);
    }

    /*
    * Supports parent relationship fields, but not sub-queries.
    */
    /****************************************************************************************************************************
    Author              : Maciej Miłosz
    Description         : Method that must be implemented by SObject specific selector to set default fields for the queries
    *****************************************************************************************************************************/
    protected abstract Set<String> getDefaultFields();

    /*
    *   Below methods should be used in SObject specific selectors to construct queries
    *   Do not expose them to business logic classes
    */
    /****************************************************************************************************************************
     Author              : Maciej Miłosz
     Description         : Query records by fields
                           Add boolean to disable escape singleqiotes for filters example in inne query
     *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjectByField(List<String> fields, String filter, List<Object> filterValues, Boolean isLikeOperator){
        return getSObjectByField(fields, filter, filterValues, isLikeOperator, true);
    }

    @TestVisible
    protected virtual List<SObject> getSObjectByField(List<String> fields,
                                                      String filter, List<Object> filterValues,
                                                      Boolean isLikeOperator, Boolean escapeSingleQuotes){
        String fieldsForQuery = prepareFields(fields);
        String query = 'SELECT ' + fieldsForQuery +
                       ' FROM ' + sObjectName +
                       ' WHERE ' + filter + (isLikeOperator ? ' LIKE ' : ' IN ') + ':filterValues';
        query += addRequiredFilters(true);
        if (escapeSingleQuotes) {
            return Database.query(String.escapeSingleQuotes(query));
        }
        return Database.query(query);
    }
    /****************************************************************************************************************************
     Author              : Maciej Miłosz
     Description         : Query records by field
     *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjectByField(List<String> fields, String filter, Object filterValue, Boolean isLikeOperator){
        String fieldsForQuery = prepareFields(fields);
        String query = 'SELECT ' + fieldsForQuery +
                       ' FROM ' + sObjectName +
                       ' WHERE ' + filter + (isLikeOperator ? ' LIKE ' : ' = ') + ':filterValue';
        query += addRequiredFilters(true);
        return Database.query(String.escapeSingleQuotes(query));
    }

    /****************************************************************************************************************************
     Author              : Ashish Sharma
     Description         : QUery records with FOR UPDATE
     *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjectByField(List<String> fields, String filter, Object filterValue, Boolean isLikeOperator, Boolean addForUpdate){
        String fieldsForQuery = prepareFields(fields);
        String query = 'SELECT ' + fieldsForQuery +
                       ' FROM ' + sObjectName +
                       ' WHERE ' + filter + (isLikeOperator ? ' LIKE ' : ' = ') + ':filterValue';
        query += addRequiredFilters(true);
        query += addForUpdate ? addForUpdate() : '';
        return Database.query(String.escapeSingleQuotes(query));
    }

    /****************************************************************************************************************************
     Author              : Maciej Miłosz
     Description         : Query all records
     *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjects(List<String> fields) {
        String fieldsForQuery = prepareFields(fields);
        String query = 'SELECT ' + fieldsForQuery +
                ' FROM ' + sObjectName;
        query += addRequiredFilters(false);
        return Database.query(String.escapeSingleQuotes(query));
    }

    /****************************************************************************************************************************
     Author              : Maciej Miłosz
     Description         : Query records with where clause
     *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjects(List<String> fields, String whereClause) {
        String fieldsForQuery = prepareFields(fields);
        String query = 'SELECT ' + fieldsForQuery +
                       ' FROM ' + sObjectName + ' ' +
                       whereClause;
        query += addRequiredFilters(true);
        if(!fieldsForQuery.contains('Business_Hours_Id__c'))
        return Database.query(String.escapeSingleQuotes(query));
        else
           return Database.query(query); 
    }

    /****************************************************************************************************************************
     Author              : Maciej Miłosz
     Description         : Query standard fields from records with where clause and bindings
    *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjects(String whereClause, List<Object> bindings) {
        String fieldsForQuery = prepareDefaultFields();
        setBindings(bindings);
        String query = 'SELECT ' + fieldsForQuery +
                      ' FROM ' + sObjectName +
                       normalizeWhereClauseForMultipleBindings(whereClause, bindings.size());
        query += addRequiredFilters(true);
        return Database.query(String.escapeSingleQuotes(query));
    }

    /****************************************************************************************************************************
     Author              : Maciej Miłosz
     Description         : Query records with where clause and bindings
     *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjects(List<String> fields, String whereClause, List<Object> bindings) {
        return getSObjects(fields, whereClause, bindings, true);
    }

    @TestVisible
    protected virtual List<SObject> getSObjects(List<String> fields, String whereClause, List<Object> bindings, Boolean escapeSingleQuotes) {
        String fieldsForQuery = prepareFields(fields);
        setBindings(bindings);
        String query = 'SELECT ' + fieldsForQuery +
                       ' FROM ' + sObjectName +
                       normalizeWhereClauseForMultipleBindings(whereClause, bindings.size());
        query += addRequiredFilters(true);
        if (escapeSingleQuotes) {
            return Database.query(String.escapeSingleQuotes(query));
        }
        return Database.query(query);
    }

    /****************************************************************************************************************************
     Author              : Pawel Biszczak
     Description         : Query records with where clause, bindings and Limit
     Created Date        : 19 Feb, 2021
     *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjects(List<String> fields, String whereClause, List<Object> bindings, Integer recordsLimit) {
        String fieldsForQuery = prepareFields(fields);
        setBindings(bindings);
        String query = 'SELECT ' + fieldsForQuery +
                ' FROM ' + sObjectName +
                normalizeWhereClauseForMultipleBindings(whereClause, bindings.size());
        query += addRequiredFilters(true);
        query += addLimit(recordsLimit);
        return Database.query(String.escapeSingleQuotes(query));
    }

    /****************************************************************************************************************************
     Author              : Maciej Miłosz
     Description         : Query records with where clause and bindings with order by clause
     *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjects(List<String> fields, String whereClause, List<Object> bindings, String orderbyClause) {
        String fieldsForQuery = prepareFields(fields);
        setBindings(bindings);
        String query = 'SELECT ' + fieldsForQuery +
                      ' FROM ' + sObjectName +
                       normalizeWhereClauseForMultipleBindings(whereClause, bindings.size());
        query += addRequiredFilters(true);
        query += addOrderByClause(orderbyClause);
        return Database.query(String.escapeSingleQuotes(query));
    }

    /****************************************************************************************************************************
     Author              : Vipul Chaudhari
     Description         : Query records with where clause and bindings with group by clause
     *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjectsByGroup(List<String> fields, String whereClause, List<Object> bindings, String groupbyClause) {
        String fieldsForQuery = prepareFields(fields);
        setBindings(bindings);
        String query = 'SELECT ' + fieldsForQuery +
                      ' FROM ' + sObjectName +
                       normalizeWhereClauseForMultipleBindings(whereClause, bindings.size());
        query += addRequiredFilters(true);
        query += addGroupByClause(groupbyClause);
        return Database.query(String.escapeSingleQuotes(query));
    }
    
    /****************************************************************************************************************************
         Author              : Jitesh Adwani
         Description         : Query records with where clause and Limit
    *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjects(List<String> fields, String filter, Object filterValue, Boolean isLikeOperator, Integer recordsLimit) {
        String fieldsForQuery = prepareFields(fields);
        String query = 'SELECT ' + fieldsForQuery +
                ' FROM ' + sObjectName +
                ' WHERE ' + filter + (isLikeOperator ? ' LIKE ' : ' = ') + ':filterValue';
        query += addRequiredFilters(true);
        query += addLimit(recordsLimit);
        return Database.query(String.escapeSingleQuotes(query));
    }

    /****************************************************************************************************************************
         Author              : Vipul Chaudhari
         Description         : Query records with child records
    *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjectsWithChilds(List<String> fields, String innerQuery, String innerWhere, String outerWhere, List<Object> innerBindings, List<Object> allBindings) {
        String subQuery = '(' + innerQuery + normalizeWhereClauseForMultipleBindings(innerWhere, innerBindings.size()) + ')';
        fields.add(subQuery);
        String fieldsForQuery = prepareFields(fields);
        setBindings(allBindings);
        String query = 'SELECT ' + fieldsForQuery +
                      ' FROM ' + sObjectName +
                       normalizeWhereClauseForOuterQueryMultipleBindings(outerWhere, allBindings.size(), innerBindings.size());
        query += addRequiredFilters(true);
        return Database.query(String.escapeSingleQuotes(query));
    }
    
    /****************************************************************************************************************************
         Author              : Ishwar Shinde
         Description         : Query records with child records
    *****************************************************************************************************************************/
    @TestVisible
    protected virtual List<SObject> getSObjectsWithChilds(List<String> fields, String innerQuery, String outerWhere, List<Object> bindings) {
        String subQuery = '(' + innerQuery + ')';
        fields.add(subQuery);
        String fieldsForQuery = prepareFields(fields);
        setBindings(bindings);
        String query = 'SELECT ' + fieldsForQuery +
                      ' FROM ' + sObjectName +
                       normalizeWhereClauseForMultipleBindings(outerWhere, bindings.size());
        query += addRequiredFilters(false);
        return Database.query(String.escapeSingleQuotes(query));
    }

/****************************************************************************************************************************
     Author              : Roshan Kankrayane 
     Description         : Create query for Query Locator 
*****************************************************************************************************************************/
    @TestVisible
    protected virtual String getQuery(List<String> fields, String whereClause) {
        String fieldsForQuery = prepareFields(fields);
        String query = 'SELECT ' + fieldsForQuery +
                       ' FROM ' + sObjectName;
        if(String.isNotBlank(whereClause)){
            query+= ' WHERE ' + whereClause;
        }else{
            query+= ' LIMIT 0';
        }
        return query; 
    }
         
    /****************************************************************************************************************************
        Author              : Maciej Milosz
        Description         : Set bindings
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    private void setBindings(List<Object> bindings){
        if(bindings.size() > 10 || bindings == null || bindings.isEmpty()){
            throw new IllegalArgumentException('SELECTOR: Query bindings must be specified.');
        }
        binding0 = bindings[0];
        if(!canAssignBinding(1, bindings)){
            return;
        }
        binding1 = bindings[1];
        if(!canAssignBinding(2, bindings)){
            return;
        }
        binding2 = bindings[2];
        if(!canAssignBinding(3, bindings)){
            return;
        }
        binding3 = bindings[3];
        if(!canAssignBinding(4, bindings)){
            return;
        }
        binding4 = bindings[4];
        if(!canAssignBinding(5, bindings)){
            return;
        }
        binding5 = bindings[5];
        if(!canAssignBinding(6, bindings)){
            return;
        }
        binding6 = bindings[6];
        if(!canAssignBinding(7, bindings)){
            return;
        }
        binding7 = bindings[7];
        if(!canAssignBinding(8, bindings)){
            return;
        }
        binding8 = bindings[8];
        if(!canAssignBinding(9, bindings)){
            return;
        }
        binding9 = bindings[9];
    }

    /****************************************************************************************************************************
    Author              : Maciej Milosz 
        Description         : Check if can assign binding
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    private Boolean canAssignBinding(Integer bindingNumber, List<Object> bindings){
        return bindingNumber < bindings.size();
    }

    /****************************************************************************************************************************
        Author              : Maciej Milosz
        Description         : Add ORDER BY clause
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    private String addOrderByClause(String orderbyClause){
        return ' ORDER BY ' + orderbyClause;
    }
    
/****************************************************************************************************************************
    Author              : Vipul Chaudhari
    Description         : Add GROUP BY clause
    Created Date        : 6 April 2022
*****************************************************************************************************************************/
    private String addGroupByClause(String groupbyClause){
        return ' GROUP BY ' + groupbyClause;
    }

    /****************************************************************************************************************************
        Author              : Jitesh Adwani
        Description         : Add Limit in Query
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    private String addLimit(Integer recordsLimit){
        return (recordsLimit > 0) ? ' LIMIT ' + recordsLimit : '';
    }
    /****************************************************************************************************************************
        Author              : Maciej Milosz
        Description         : Normalize where clause for multiple bindings
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    private String normalizeWhereClauseForMultipleBindings(String whereClause, Integer bindingsAmount) {
        if (whereClause == null) {
            return '';
        }
        // Splitting where clause on expressions for variable bindings
        // this regex is done to find and remove bindings
        // eg: splittedString for whereClause = 'Id IN :ids AND name = :name' will result into ['id IN ','AND name =' ]
        List<String> splittedString = whereClause.split(':(.+?)(?=[^\\w\\.]|[ )]|$)');
        if(bindingsAmount != splittedString.size() && bindingsAmount != splittedString.size() - 1){
            throw new IllegalArgumentException('SELECTOR: Query bindings number do not match.');
        }
        String result = ' WHERE ';
        for (Integer i = 0; i < splittedString.size(); i++) {
            String binding = '';
            if (i < bindingsAmount) {
                binding = ' :binding' + String.valueOf(i);
            }
            result += splittedString.get(i) + binding;
        }
        result += addRequiredFilters(true);
        return result;
    }

/****************************************************************************************************************************
    Author              : Vipul Chaudhari
    Description         : Normalize where clause for outer query multiple bindings
*****************************************************************************************************************************/
    @TestVisible
    private String normalizeWhereClauseForOuterQueryMultipleBindings(String whereClause, Integer bindingsAmount, Integer startingBindinAmount) {
        if (whereClause == null) {
            return '';
        }
        // Splitting where clause on expressions for variable bindings
        // this regex is done to find and remove bindings
        // eg: splittedString for whereClause = 'Id IN :ids AND name = :name' will result into ['id IN ','AND name =' ]
        List<String> splittedString = whereClause.split(':(.+?)(?=[^\\w\\.]|[ )]|$)');
        if(bindingsAmount-startingBindinAmount != splittedString.size() && bindingsAmount-startingBindinAmount != splittedString.size() - 1){
            throw new IllegalArgumentException('SELECTOR: Query bindings number do not match.');
        }
        String result = ' WHERE ';
        for (Integer i = 0; i < splittedString.size(); i++) {
            String binding = '';
            if (startingBindinAmount < bindingsAmount) {
                binding = ' :binding' + String.valueOf(startingBindinAmount++);
            }
            result += splittedString.get(i) + binding;
        }
        result += addRequiredFilters(true);
        return result;
    }

    /****************************************************************************************************************************
        Author              : Maciej Milosz
        Description         : Prepare default fields
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    private String prepareDefaultFields(){
        return String.join(defaultFields, ',');
    }

    /****************************************************************************************************************************
        Author              : Maciej Milosz
        Description         : Prepare fields
        Created Date        : 7/9/2020
    *****************************************************************************************************************************/
    private String prepareFields(List<String> fields){
        if(fields != null && !fields.isEmpty()){
            return String.join(fields, ', ');
        }else{
            return String.join(defaultFields, ',');
        }
    }

    /****************************************************************************************************************************
        Author              : Ashish Sharma
        Description         : Add for update
        Created Date        : 17/06/2021
    *****************************************************************************************************************************/
    private String addForUpdate(){
        return ' FOR UPDATE';
    }
}