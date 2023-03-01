/**
* @author Shubham Jain, Traction on Demand
* @date 2019-10-09
*/

public class trac_TranslationParser {

    public Data data;

    public class Data {
        public List<Translations> translations;
    }

    public class Translations {
        public String translatedText;
    }


    public static trac_TranslationParser parse(String json) {
        return (trac_TranslationParser) System.JSON.deserialize(json, trac_TranslationParser.class);
    }
}