CREATE OR REPLACE JAVA SOURCE NAMED getPropertie AS
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Properties;
public class getPropertie {
    public static String getProp(String prop) throws FileNotFoundException, IOException {
        Properties appProps = new Properties();
        FileInputStream fis = new FileInputStream("/home/oracle/oracleAccess/credentials.store.properties");
        try {
            appProps.load(fis);
            String propName = appProps.getProperty(prop.toLowerCase(), "notFound");
            return propName;
        } catch (FileNotFoundException e) {
            return "FileNotFound";
        } catch (IOException e) {
            return "IOEXCeption";
        } finally {
            fis.close();
        }
    }
};
/