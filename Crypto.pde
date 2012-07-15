/**
 * Here mainly for obfuscation of our API credentials in production builds,
 * this of course won't stop a smart person like you who is reading my code :)
 * Please don't hijack my Twitter API credentials! Thanks. -Eliot
 *
 * Based on sample code from http://www.digizol.org/2009/10/java-encrypt-decrypt-jce-salt.html
 */
import java.security.*;
import java.security.spec.InvalidKeySpecException;
import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import javax.xml.bind.DatatypeConverter;

public class Crypto {

    private final String ALGORITHM = "AES";
    private final int ITERATIONS = 2;
    private final byte[] keyValue;

    /**
     * @param String keyValueString 16-character ASCII string to use as encryption key
     */
    Crypto(String keyValueString) {
      keyValue = keyValueString.getBytes();
    }

    String encrypt(String value, String salt) throws Exception {
        Key key = generateKey();
        Cipher c = Cipher.getInstance(ALGORITHM);  
        c.init(Cipher.ENCRYPT_MODE, key);
  
        String valueToEnc = null;
        String eValue = value;
        for (int i = 0; i < ITERATIONS; i++) {
            valueToEnc = salt + eValue;
            byte[] encValue = c.doFinal(valueToEnc.getBytes());
            eValue = DatatypeConverter.printBase64Binary(encValue);
        }
        return eValue;
    }

    String decrypt(String value, String salt) throws Exception {
        Key key = generateKey();
        Cipher c = Cipher.getInstance(ALGORITHM);
        c.init(Cipher.DECRYPT_MODE, key);
  
        String dValue = null;
        String valueToDecrypt = value;
        for (int i = 0; i < ITERATIONS; i++) {
            byte[] decordedValue = DatatypeConverter.parseBase64Binary(valueToDecrypt);
            byte[] decValue = c.doFinal(decordedValue);
            dValue = new String(decValue).substring(salt.length());
            valueToDecrypt = dValue;
        }
        return dValue;
    }

    private Key generateKey() throws Exception {
        Key key = new SecretKeySpec(keyValue, ALGORITHM);
        // Example of using another algorithm (DES) :
        // SecretKeyFactory keyFactory = SecretKeyFactory.getInstance(ALGORITHM);
        // key = keyFactory.generateSecret(new DESKeySpec(keyValue));
        return key;
    }
}
