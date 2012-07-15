class CryptoHelper {
  final String SALT0 = ">3>4lObbD16#WCK28MT5OjWD2bfmsS8GCKO9iGf@zS>),F|{+A";
  final String SALT1 = "]ND6E94n&6sZlmS^60-wA$oPknALm5+VQ,7w6%!EEOlvr!U0as";
  final String SALT2 = "@Dqiu!u9}[+wMV[o1nH4u95wqgatr:4O6Xb[.e5<hgofv7zi2p";
  final String SALT3 = "V2Uo;`qM5.U9N|QS7NgPBoT1yeECA7%`I(6`djU]O5g.Zp54EB";

  /**
   * Decrypt production config.
   * Here mainly for obfuscation of my API credentials in production builds,
   * this of course won't stop a smart person like you who is reading my code :)
   * Please don't hijack my Twitter API credentials! Thanks. -Eliot
   */
  String[] decryptCredentials(String[] credentials) {
    return cryptCredentials(true, credentials);
  }

  String[] encryptCredentials(String[] credentials) {
    return cryptCredentials(false, credentials);
  }

  String[] cryptCredentials(boolean decrypt, String[] credentials) {
    String[] result = new String[4];
    try {
      Crypto crypto = new Crypto("?u:9)254]I{_6bWR");

      for (int i = 0; i < credentials.length; i++) {
        String salt;
        switch(i) {
          case 0:
            salt = SALT0;
            break;
          case 1:
            salt = SALT1;
            break;
          case 2:
            salt = SALT2;
            break;
          case 3:
            salt = SALT3;
            break;
          default:
            //This shouldn't happen unless there is whitespace at the end of the file...
            continue;
        }

        if (decrypt) {
          result[i] = crypto.decrypt(credentials[i], salt);
        } else {
          result[i] = crypto.encrypt(credentials[i], salt);
        }
      }
    } catch (Exception e) {
      println("Got exception from crypto library: " + e.getClass().toString());
      noLoop();
      exit();
    }

    return result;
  }
}
