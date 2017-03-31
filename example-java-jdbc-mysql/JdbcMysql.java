import java.sql.*;


public class JdbcMysql
{
  // The JDBC Connector Class.
  private static final String dbClassName = "com.mysql.jdbc.Driver";
  private static final String CONNECTION = System.getenv("JDBC_MYSQL_URI");


  public static void main(String[] args) throws
                                        ClassNotFoundException,SQLException
  {
    Class.forName(dbClassName);
    Connection c = null;

    while (true){
      try {
        c = DriverManager.getConnection(CONNECTION);
      }
      catch (Exception e) {
        System.out.println(e);
        e.printStackTrace();
        System.exit(1);
      }
      finally {
        c.close();
      }
      System.out.println("MySQL Connection Successful!");

      try {
        Thread.sleep(1000);
      } catch(InterruptedException ex) {
        Thread.currentThread().interrupt();
      }
    }
  }
}
