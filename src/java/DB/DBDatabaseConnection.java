
package DB;
import java.sql.*;
public class DBDatabaseConnection {
    public Connection con;
    public Statement stmt;
    public PreparedStatement pstmt;
    public PreparedStatement pstmt2;
    public  ResultSet rst;
    public DBDatabaseConnection()
    {
        try
        {
            Class.forName("com.mysql.jdbc.Driver");
            con=DriverManager.getConnection("jdbc:mysql://localhost:3306/library_db","root","root");
            
            
        }
        catch(Exception e)
        {
           e.printStackTrace();
        }
        }
           
           
           
           
}
