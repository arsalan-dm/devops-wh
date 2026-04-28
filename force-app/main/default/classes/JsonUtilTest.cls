@istest
public with sharing class JsonUtilTest {

    @istest
    public static void constructor(){
        Test.startTest();
        JsonUtil body = new JsonUtil();
        body.startArray();
        Test.stopTest();
        String stringBody = body.getAsString();
        System.debug(stringBody);
        Assert.isTrue(stringBody == '[ ]', 'expect the string body to be \'[ ]\', but received \'' + stringBody + '\'');
    }

    @istest
    public static void prettyConstructor(){
        Test.startTest();
        JsonUtil body = new JsonUtil(true);
        body.startObject();
        Test.stopTest();
        String stringBody = body.getAsString();
        System.debug(stringBody);
        Assert.isTrue(stringBody == '{ }', 'expect the string body to be \'{ }\', but received \'' + stringBody + '\'');
    }

    @istest
    public static void contructorObject(){
        Test.startTest();
        JsonUtil body = new JsonUtil(true, false);
        Test.stopTest();
        String stringBody = body.getAsString();
        System.debug(stringBody);
        Assert.isTrue(stringBody == '{ }', 'expect the string body to be \'{ }\', but received \'' + stringBody + '\'');
    }

    @istest
    public static void contructorArray(){
        Test.startTest();
        JsonUtil body = new JsonUtil(true, true);
        Test.stopTest();
        String stringBody = body.getAsString();
        System.debug(stringBody);
        Assert.isTrue(stringBody == '[ ]', 'expect the string body to be \'[ ]\', but received \'' + stringBody + '\'');
    }

    @istest
    public static void startObjectNamed(){
        JsonUtil jsonBody = new JsonUtil(false, false);
        Test.startTest();
        jsonBody.startObject('firstObject');
        Test.stopTest();
        String stringBody = jsonBody.getAsString();
        System.debug(stringBody);
        Assert.isTrue(stringBody.contains('firstObject'), 'the firstObject object is missing from the json');
    }

    @istest
    public static void startObject(){
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.startObject();
        Test.stopTest();
        String stringBody = jsonBody.getAsString();
        System.debug(stringBody);
        Assert.isTrue(stringBody == '[ { } ]', 'expected an empty object inside the array, got \'' + stringBody + '\'');
    }

    @istest
    public static void newObject(){
        JsonUtil jsonBody = new JsonUtil(true, true);
        jsonBody.startObject();
        Test.startTest();
        jsonBody.newObject();
        Test.stopTest();
        String stringBody = jsonBody.getAsString();
        Assert.isTrue(stringBody == '[ { }, { } ]', 'expected a list of 2 empty objects inside the array, got \'' + stringBody + '\'');
    }

    @istest
    public static void endObject(){
        JsonUtil jsonBody = new JsonUtil(true, true);
        jsonBody.startObject();
        Test.startTest();
        jsonBody.endObject();
        Test.stopTest();
        jsonBody.startObject();
        String stringBody = jsonBody.getAsString();
        System.debug(stringBody);
        Assert.isTrue(stringBody == '[ { }, { } ]', 'expected a list of 2 empty objects inside the array, got \'' + stringBody + '\'');
    }

    @istest
    public static void startArrayNamed(){
        JsonUtil jsonBody = new JsonUtil();
        jsonBody.startObject();
        Test.startTest();
        jsonBody.startArray('firstArray');
        Test.stopTest();
        String stringBody = jsonBody.getAsString();
        System.debug(stringBody);
        Assert.isTrue(stringBody.contains('firstArray'), 'the firstObject object is missing from the json');
    }

    @istest
    public static void startArray(){
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.startArray();
        Test.stopTest();
        String stringBody = jsonBody.getAsString();
        System.debug(stringBody);
        Assert.isTrue(stringBody == '[ [ ] ]', 'expected an empty array inside the array, got \'' + stringBody + '\'');
    }

    @istest
    public static void endArray(){
        JsonUtil jsonBody = new JsonUtil();
        jsonBody.startObject();
        jsonBody.startArray('array1');
        Test.startTest();
        jsonBody.endArray();
        Test.stopTest();
        jsonBody.startArray('array2');
        Map<String,Object> createdJson = (Map<String,Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue(createdJson.get('array1') != null, 'the array array1 was not found on the returned object');
    }

    @istest
    public static void addString(){
        String value = 'this value';
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.add(value);
        Test.stopTest();
        List<Object> createdJson = (List<Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue((String)createdJson.get(0) == value, 'expect the first list element to have a value of \'' + value + '\', but received \'' + (String)createdJson.get(0) + '\'');
    }

    @istest
    public static void addStringNull(){
        String value;
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.add(value);
        Test.stopTest();
        List<Object> createdJson = (List<Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue((String)createdJson.get(0) == value, 'expect the first list element to have a value of \'' + value + '\', but received \'' + (String)createdJson.get(0) + '\'');
    }

    @istest
    public static void addInteger(){
        Integer value = 5;
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.add(value);
        Test.stopTest();
        List<Object> createdJson = (List<Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue((Integer)createdJson.get(0) == value, 'expect the first list element to have a value of \'' + value + '\', but received \'' + (Integer)createdJson.get(0) + '\'');
    }

    @istest
    public static void addIntegerNull(){
        Integer value;
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.add(value);
        Test.stopTest();
        List<Object> createdJson = (List<Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue((Integer)createdJson.get(0) == value, 'expect the first list element to have a value of \'' + value + '\', but received \'' + (Integer)createdJson.get(0) + '\'');
    }

    @istest
    public static void addLong(){
        Long value = 5;
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.add(value);
        Test.stopTest();
        List<Object> createdJson = (List<Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue((Long)createdJson.get(0) == value, 'expect the first list element to have a value of \'' + value + '\', but received \'' + (Long)createdJson.get(0) + '\'');
    }

    @istest
    public static void addLongNull(){
        Long value;
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.add(value);
        Test.stopTest();
        List<Object> createdJson = (List<Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue((Long)createdJson.get(0) == value, 'expect the first list element to have a value of \'' + value + '\', but received \'' + (Long)createdJson.get(0) + '\'');
    }

    @istest
    public static void addDecimal(){
        Decimal value = 5.05;
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.add(value);
        Test.stopTest();
        List<Object> createdJson = (List<Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue((Decimal)createdJson.get(0) == value, 'expect the first list element to have a value of \'' + value + '\', but received \'' + (Decimal)createdJson.get(0) + '\'');
    }

    @istest
    public static void addDecimalNull(){
        Decimal value;
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.add(value);
        Test.stopTest();
        List<Object> createdJson = (List<Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue((Decimal)createdJson.get(0) == value, 'expect the first list element to have a value of \'' + value + '\', but received \'' + (Decimal)createdJson.get(0) + '\'');
    }

    @istest
    public static void addDouble(){
        Double value = 5.05;
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.add(value);
        Test.stopTest();
        List<Object> createdJson = (List<Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue((Double)createdJson.get(0) == value, 'expect the first list element to have a value of \'' + value + '\', but received \'' + (Double)createdJson.get(0) + '\'');
    }

    @istest
    public static void addDoubleNull(){
        Double value;
        JsonUtil jsonBody = new JsonUtil(true, true);
        Test.startTest();
        jsonBody.add(value);
        Test.stopTest();
        List<Object> createdJson = (List<Object>)JSON.deserializeUntyped(jsonBody.getAsString());
        Assert.isTrue((Double)createdJson.get(0) == value, 'expect the first list element to have a value of \'' + value + '\', but received \'' + (Double)createdJson.get(0) + '\'');
    }

    @istest
    public static void putString(){
        String input = 'this is my string';
        JsonUtil jsonUtil = new JsonUtil(true, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((String)jsonBody.get('stringField') == input, 'expecting the stringField to be set to \'' + input + '\' but received ' + (String)jsonBody.get('stringField')) ;
    }

    @istest
    public static void putStringNull(){
        String input = null;
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((String)jsonBody.get('stringField') == null, 'expecting the stringField to be set to \'' + input + '\' but received ' + (String)jsonBody.get('stringField')) ;
    }

    @istest
    public static void putDate(){
        Date input = Date.today();
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((String)jsonBody.get('stringField') == String.valueOf(input), 'expecting the stringField to be set to \'' + String.valueOf(input) + '\' but received ' + (String)jsonBody.get('stringField')) ;
    }

    @istest
    public static void putDateNull(){
        Date input = null;
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((Date)jsonBody.get('stringField') == null, 'expecting the stringField to be set to \'null\' but received ' + (String)jsonBody.get('stringField')) ;
    }

    @istest
    public static void putDateTime(){
        DateTime input = DateTime.Now();
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((String)jsonBody.get('stringField') == input.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS') + 'Z', 'expecting the stringField to be set to \'' + input.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS') + 'Z\' but received ' + (String)jsonBody.get('stringField')) ;
    }

    @istest
    public static void putDateTimeNull(){
        DateTime input = null;
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((String)jsonBody.get('stringField') == null, 'expecting the stringField to be set to \'null\' but received ' + (String)jsonBody.get('stringField')) ;
    }
    @istest
    public static void putInteger(){
        Integer input = 1;
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((Integer)jsonBody.get('stringField') == input, 'expecting the stringField to be set to \'' + input + '\' but received ' + ((Integer)jsonBody.get('stringField')).format());
    }

    @istest
    public static void putIntegerNull(){
        Integer input = null;
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((Integer)jsonBody.get('stringField') == null, 'expecting the stringField to be set to \'null\' but received ' + String.valueOf((Integer)jsonBody.get('stringField')));
    }


    @istest
    public static void putDecimal(){
        Decimal input = 1.23232323;
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((Decimal)jsonBody.get('stringField') == input, 'expecting the stringField to be set to \'' + input.format() + '\' but received ' + ((Decimal)jsonBody.get('stringField')).format()) ;
    }

    @istest
    public static void putDecimalNull(){
        Decimal input = null;
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((Decimal)jsonBody.get('stringField') == null, 'expecting the stringField to be set to \'null\' but received ' + String.valueOf((Decimal)jsonBody.get('stringField')));
    }

    @istest
    public static void putBoolean(){
        Boolean input = true;
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((Boolean)jsonBody.get('stringField') == input, 'expecting the stringField to be set to \''+ String.valueOf(input) +'\' but received ' + String.valueOf((Boolean)jsonBody.get('stringField')));
    }

    @istest
    public static void putBooleanNull(){
        Boolean input = null;
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((Boolean)jsonBody.get('stringField') == null, 'expecting the stringField to be set to \'null\' but received ' + String.valueOf((Boolean)jsonBody.get('stringField')));
    }

    @istest
    public static void putTime(){
        Time input = time.newInstance(6, 12, 24, 48);
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((String)jsonBody.get('stringField') == String.valueOf(input), 'expecting the stringField to be set to \''+ String.valueOf(input) +'\' but received ' + (String)jsonBody.get('stringField'));
    }

    @istest
    public static void putTimeNull(){
        Time input = null;
        JsonUtil jsonUtil = new JsonUtil(false, false);
        Test.startTest();
        jsonUtil.put('stringField', input);
        Test.stopTest();
        String jsonString = jsonUtil.getAsString();
        Map<String, Object> jsonBody = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Assert.istrue((Time)jsonBody.get('stringField') == null, 'expecting the stringField to be set to \'null\' but received ' + String.valueOf((Time)jsonBody.get('stringField')));
    }

    @istest
    public static void getAsString(){
        JsonUtil json = new JsonUtil(true, false);
        Test.startTest();
        String jsonString = json.getAsString();
        Test.stopTest();
        Assert.istrue(jsonString == '{ }', 'Expected the json string to be \'{ }\' but received ' + jsonString);
    }
}