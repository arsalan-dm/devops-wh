public with sharing class JsonUtil {
    public JSONGenerator gen;

    public JsonUtil(){
        gen = JSON.createGenerator(true);
    }

    public JsonUtil(Boolean pretty){
        gen = JSON.createGenerator(pretty);
    }

    public JsonUtil(Boolean pretty, Boolean outerArray){
        gen = JSON.createGenerator(pretty);
        if (outerArray){
            gen.writeStartArray();
        }else{
            gen.writeStartObject();
        }
    }

    public JsonUtil startObject(String objectName){
        gen.writeFieldName(objectName);
        gen.writeStartObject();
        return this;
    }

    public JsonUtil startObject(){
        gen.writeStartObject();
        return this;
    }

    public JsonUtil endObject(){
        gen.writeEndObject();
        return this;
    }

    public JsonUtil newObject(){
        gen.writeEndObject();
        gen.writeStartObject();
        return this;
    }

    public JsonUtil startArray(String arrayName){
        gen.writeFieldName(arrayName);
        gen.writeStartArray();
        return this;
    }

    public JsonUtil startArray(){
        gen.writeStartArray();
        return this;
    }

    public JsonUtil endArray(){
        gen.writeEndArray();
        return this;
    }

    public JsonUtil add(String value){
        if (value == null){
            gen.writeNull();
        }else{
            gen.writeString(value);
        }
        return this;
    }

    public JsonUtil add(Integer value){
        if (value == null){
            gen.writeNull();
        }else{
            gen.writeNumber(value);
        }
        return this;
    }

    public JsonUtil add(Long value){
        if (value == null){
            gen.writeNull();
        }else{
            gen.writeNumber(value);
        }
        return this;
    }

    public JsonUtil add(Decimal value){
        if (value == null){
            gen.writeNull();
        }else{
            gen.writeNumber(value);
        }
        return this;
    }

    public JsonUtil add(Double value){
        if (value == null){
            gen.writeNull();
        }else{
            gen.writeNumber(value);
        }
        return this;
    }

    public JsonUtil put(String attributeName, String value){
        if (value == null){
            gen.writeNullField(attributeName);
        }else{
            gen.writeStringField(attributeName, value);
        }
        return this;
    }

    public JsonUtil put(String attributeName, Date value){
        if (value == null){
            gen.writeNullField(attributeName);
        }else{
            gen.writeDateField(attributeName, value);
        }
        return this;
    }

    public JsonUtil put(String attributeName, DateTime value){
        if (value == null){
            gen.writeNullField(attributeName);
        }else{
            gen.writeDateTimeField(attributeName, value);
        }
        return this;
    }

    public JsonUtil put(String attributeName, Integer value){
        if (value == null){
            gen.writeNullField(attributeName);
        }else{
            gen.writeNumberField(attributeName, value);
        }
        return this;
    }

    public JsonUtil put(String attributeName, Decimal value){
        if (value == null){
            gen.writeNullField(attributeName);
        }else{
            gen.writeNumberField(attributeName, value);
        }
        return this;
    }

    public JsonUtil put(String attributeName, Boolean value){
        if (value == null){
            gen.writeNullField(attributeName);
        }else{
            gen.writeBooleanField(attributeName, value);
        }
        return this;
    }

    public JsonUtil put(String attributeName, Time value){
        if (value == null){
            gen.writeNullField(attributeName);
        }else{
            gen.writeTimeField(attributeName, value);
        }
        return this;
    }

    public String getAsString(){
        return gen.getAsString();
    }
}