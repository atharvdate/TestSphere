 import org.mindrot.jbcrypt.BCrypt;

  public class HashGenerator {
      public static void main(String[] args) {
          String password = "YOUR_PASSWORD_HERE";
          String hash = BCrypt.hashpw(password, BCrypt.gensalt(12));
          System.out.println(hash);
      }
  }