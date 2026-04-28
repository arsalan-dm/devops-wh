@istest
public with sharing class Stub implements System.StubProvider {

    public static List<String> objectNames = new List<String>();
    public static List<String> callNames = new List<String>();
    public static List<Object> callArgs = new List<Object>();
    public Map<String, Method> mockedMethod = new Map<String, Method>();

    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
        String stubbedObjectName = String.valueOf(stubbedObject).substringBefore(':').substringBefore('__sfdc_ApexStub');

        objectNames.add(stubbedObjectName);
        callNames.add(stubbedMethodName);
        callArgs.add(listOfArgs);
        
        if (stubbedObjectName == returnType.getName()){ // support for builder pattern methods that returns this
            return stubbedObject;
        }
		System.debug(mockedMethod);
        if (mockedMethod?.get(stubbedMethodName) != null){
            return mockedMethod.get(stubbedMethodName).mock();
        }
        return null;
    }

    public static Builder builder(){
        return new Builder();
    }

    public class Builder{
        public Stub stub;
        private String currentMethodName;
        
        public Builder(){
            stub = new Stub();
        }

        public Builder handleMethod(String methodName){
            currentMethodName = methodName;
            return this;
        }

        public Builder with(Stub.Method method){
            stub.mockedMethod.put(currentMethodName, method);
            return this;
        }

        public Builder with(Object returnValue){
            stub.mockedMethod.put(currentMethodName, new Stub.Method(returnValue));
            return this;
        }

        public Object create(Type typeToMock){
            return Test.createStub(typeToMock, stub);
        }
    }

    public static Method method(){
        return new Method();
    }

    public static Method method(Object defaultReturnValue){
        return new Method(defaultReturnValue);
    }

    public class Method{
        // class to store all the info for each particular method that can be called and each one that is called 
        Map<Integer, Object> returnValues = new Map<Integer, Object>();
        Object defaultReturnValue;
        Integer callCount = 0;

        Integer start;
        Integer stop;

        public Method(){
            defaultReturnValue = null;
        }

        public Method(Object defaultReturnValue){
            this.defaultReturnValue = defaultReturnValue; 
        }

        public Method defaultResponse(Object defaultResponse){
            defaultReturnValue = defaultResponse;
            return this;
        }

        public Method handleCall(Integer callNumber){
            this.start = callNumber;
            this.stop = callNumber + 1;
            return this;
        }

        public Method handleCalls(Integer start, Integer stop){
            this.start = start;
            this.stop = stop;
            return this;
        }

        public Method with(Object returnObject){
            for (Integer i = start; i < stop; i += 1){
                returnValues.put(i, returnObject);
            }
            return this;
        }

        public Object mock(){
            Object value;
            if (returnValues?.keySet().contains(callCount)) { // allows for purposefully setting the return value to null for a call
                value = returnValues.get(callCount);
            } else {
                value = defaultReturnValue;
            }
            callCount += 1;
            if (value instanceOf Exception) {
                throw (Exception)value;
            }
            return value;
        }
    }
    
    private static Integer num = 0;

    public static String getId(Schema.SObjectType sot){
        String result = String.valueOf(num++);
        return sot.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
    }

    public static String getId(Id recordId){
        String result = String.valueOf(num++);
        return recordId.getSObjectType().getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
    }

    public static String getId(sObject record){
        String result = String.valueOf(num++);
        return record.getSObjectType().getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
    } 

    public static String getId(List<sObject> records){
        String result = String.valueOf(num++);
        return records[0].getSObjectType().getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
    } 
    
    public static String getId(){
        String result = String.valueOf(num++);
        return '00X' + '0'.repeat(12-result.length()) + result;
    }
}