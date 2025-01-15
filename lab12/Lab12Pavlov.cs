using System.Configuration;
using System.Data;
using Microsoft.Data.SqlClient;

namespace lab_12_pavlov
{
    internal interface IExecutor
    {
        const string SelectQuery = "SELECT * FROM Game";
        
        const string UpdateQuery = "UPDATE Game SET GameName = @GameName WHERE GameID = @GameID";

        const string InsertQuery =
            "INSERT INTO Game(GameID, GameName, ReleaseDate, Description, Price, DeveloperID, AppID)" +
            "VALUES (@GameID, @GameName, @ReleaseDate, @Description, @Price, @DeveloperID, @AppID)";

        const string DeleteQuery = "DELETE FROM Game WHERE GameID = @GameID";

        void Select();

        void Update(int gameID, string newGameName);

        void Insert(int gameID, string gameName, DateTime releaseDate, string description,
            decimal price, int developerID, int appID);

        void Delete(int gameID);
    }

    internal class LinkedExecutor : IExecutor
    {
        private readonly SqlConnection _conn;
        
        public LinkedExecutor(SqlConnection conn)
        {
            _conn = conn;
            _conn.Open();
        }
        
        public void Select()
        {
            try {
                var newComm = _conn.CreateCommand();
                newComm.Connection = _conn;
                newComm.CommandText = IExecutor.SelectQuery;

                using (var reader = newComm.ExecuteReader()) {
                    for (var i = 0; i < reader.FieldCount; i++)
                    {
                        Console.Write(reader.GetName(i) + " ");
                    }

                    Console.WriteLine();
                    while (reader.Read())
                    {
                        for (var i = 0; i < reader.FieldCount; i++)
                        {
                            Console.Write(reader.GetValue(i) + "\t");
                        }
                        Console.WriteLine();
                    }
                }
            }
            catch (Exception e) {
                Console.WriteLine(e.Message);
            }
        }

        public void Update(int gameID, string newGameName)
        {
            try
            {
                var newComm = _conn.CreateCommand();
                newComm.Connection = _conn;
                newComm.CommandText = IExecutor.UpdateQuery;

                SqlParameter[] parameters = new SqlParameter[2];
                parameters[0] = new SqlParameter(parameterName: "@GameID", value: gameID);
                parameters[1] = new SqlParameter(parameterName: "@GameName", value: newGameName);

                newComm.Parameters.AddRange(parameters);
                Console.WriteLine("UPDATE: {0} rows updated ", newComm.ExecuteNonQuery());
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
                throw;
            }
        }
        
        public void Insert(int gameID, string gameName, DateTime releaseDate, string description, 
            decimal price, int developerID, int appID)
        {
            try {
                var newComm = _conn.CreateCommand();
                newComm.Connection = _conn;
                newComm.CommandText = IExecutor.InsertQuery;

                SqlParameter[] parameters = new SqlParameter[7];
                parameters[0] = new SqlParameter(parameterName: "@GameID", value: gameID);
                parameters[1] = new SqlParameter(parameterName: "@GameName", value: gameName);
                parameters[2] = new SqlParameter(parameterName: "@ReleaseDate", value: releaseDate);
                parameters[3] = new SqlParameter(parameterName: "@Description", value: description);
                parameters[4] = new SqlParameter(parameterName: "@Price", value: price);
                parameters[5] = new SqlParameter(parameterName: "@DeveloperID", value: developerID);
                parameters[6] = new SqlParameter(parameterName: "@AppID", value: appID);

                newComm.Parameters.AddRange(parameters);
                Console.WriteLine("INSERT: {0} rows inserted ", newComm.ExecuteNonQuery());
            }
            catch (Exception e) {
                Console.WriteLine(e.Message);
            }
        }

        public void Delete(int gameID)
        {
            try {
                var newComm = _conn.CreateCommand();
                newComm.Connection = _conn;
                newComm.CommandText = IExecutor.DeleteQuery;

                var param = new SqlParameter(parameterName: "@GameID", value: gameID);

                newComm.Parameters.Add(param);
                Console.WriteLine("DELETE: {0} rows deleted ", newComm.ExecuteNonQuery());
            }
            catch (Exception e) {
                Console.Write(e.Message);
            }
        }
    }

    internal class UnlinkedExecutor : IExecutor
    {
        private SqlConnection _conn;
        private DataSet _dataset;
        private SqlDataAdapter _dataAdapter;
        
        const string InsertQuery =
            "INSERT INTO Game(GameID, GameName, ReleaseDate, Description, Price, DeveloperID, AppID) " +
            "VALUES (@GameID, @GameName, @ReleaseDate, @Description, @Price, @DeveloperID, @AppID);" +
            "SELECT CreatedAt FROM Game WHERE GameID = @GameID";

        public UnlinkedExecutor(SqlConnection conn)
        {
            _conn = conn;
            _conn.Open();

            _dataset = new DataSet();
            _dataAdapter = new SqlDataAdapter("SELECT * FROM Game", conn);
            _dataAdapter.Fill(_dataset, "Game");
            
            // Create insert command
            var newComm = _conn.CreateCommand();
            newComm.Connection = _conn;
            newComm.CommandText = InsertQuery;

            SqlParameter[] parameters = new SqlParameter[7];
            parameters[0] = new SqlParameter(parameterName: "@GameID", dbType: SqlDbType.Int);
            parameters[0].SourceColumn = "GameID";

            parameters[1] = new SqlParameter(parameterName: "@GameName", dbType: SqlDbType.VarChar);
            parameters[1].SourceColumn = "GameName";

            parameters[2] = new SqlParameter(parameterName: "@ReleaseDate", dbType: SqlDbType.Date);
            parameters[2].SourceColumn = "ReleaseDate";

            parameters[3] = new SqlParameter(parameterName: "@Description", dbType: SqlDbType.VarChar);
            parameters[3].SourceColumn = "Description";

            parameters[4] = new SqlParameter(parameterName: "@Price", dbType: SqlDbType.Decimal);
            parameters[4].SourceColumn = "Price";
                
            parameters[5] = new SqlParameter(parameterName: "@DeveloperID", dbType: SqlDbType.Int);
            parameters[5].SourceColumn = "DeveloperID";
                
            parameters[6] = new SqlParameter(parameterName: "@AppID", dbType: SqlDbType.Int);
            parameters[6].SourceColumn = "AppID";
            
            newComm.Parameters.AddRange(parameters);
            _dataAdapter.InsertCommand = newComm;
            _dataAdapter.InsertCommand.Connection = _conn;
            
            // Create update command
            newComm = _conn.CreateCommand();
            newComm.Connection = _conn;
            newComm.CommandText = IExecutor.UpdateQuery;

            parameters = new SqlParameter[2];
            parameters[0] = new SqlParameter(parameterName: "@GameID", dbType: SqlDbType.Int);
            parameters[0].SourceColumn = "GameID";

            parameters[1] = new SqlParameter(parameterName: "@GameName", dbType: SqlDbType.VarChar);
            parameters[1].SourceColumn = "GameName";

            newComm.Parameters.AddRange(parameters);
            _dataAdapter.UpdateCommand = newComm;
            _dataAdapter.UpdateCommand.Connection = _conn;
            
            // Create delete command
            newComm = _conn.CreateCommand();
            newComm.Connection = _conn;
            newComm.CommandText = IExecutor.DeleteQuery;

            var param = new SqlParameter(parameterName: "@GameID", dbType: SqlDbType.Int);
            param.SourceColumn = "GameID";
            
            newComm.Parameters.Add(param);
            _dataAdapter.DeleteCommand = newComm;
            _dataAdapter.DeleteCommand.Connection = _conn;
        }
        
        public void Select()
        {
            try {
                var tableReader = _dataset.Tables["Game"].CreateDataReader();
                var countCols = tableReader.FieldCount;
                for (var i = 0; i < countCols; i++) {
                    Console.Write(tableReader.GetName(i) + " ");
                }
                Console.WriteLine();
                while (tableReader.Read()) {
                    for (var i = 0; i < countCols; i++) {
                        Console.Write(tableReader.GetValue(i) + "\t");
                    }
                    Console.WriteLine();
                }
                Console.WriteLine();
                tableReader.Close();
            }
            catch (Exception e) {
                Console.WriteLine(e);
            }
        }

        public void Update(int gameID, string newGameName)
        {
            try {
                var countRows = _dataset.Tables["Game"].Rows.Count;
                for (var i = 0; i < countRows; i++) {
                    if (_dataset.Tables["Game"].Rows[i]["GameID"].Equals(gameID)) {
                        _dataset.Tables["Game"].Rows[i]["GameName"] = newGameName;
                        break;
                    }
                }
            }
            catch (Exception e) {
                Console.WriteLine(e);
            }
        }
        
        public void Insert(int gameID, string gameName, DateTime releaseDate, string description, 
            decimal price, int developerID, int appID)
        {
            try {
                DataRow dataRow = _dataset.Tables["Game"].NewRow();
                dataRow["GameID"] = gameID;
                dataRow["GameName"] = gameName;
                dataRow["ReleaseDate"] = releaseDate;
                dataRow["Description"] = description;
                dataRow["Price"] = price;
                dataRow["DeveloperID"] = developerID;
                dataRow["AppID"] = appID;
                _dataset.Tables["Game"].Rows.Add(dataRow);
            }
            catch (Exception e) {
                Console.WriteLine(e);
            }
        }

        public void Delete(int gameID)
        {
            try {
                var countRows = _dataset.Tables["Game"].Rows.Count;
                for (var i = 0; i < countRows ; i++) {
                    if (!_dataset.Tables["Game"].Rows[i]["GameID"].Equals(gameID))
                    {
                        continue;
                    }
                    _dataset.Tables["Game"].Rows[i].Delete();
                    break;
                }
            }
            catch (Exception e) {
                Console.WriteLine(e);
            }
        }

        public void Commit()
        {
            try {
                var rowsAffected = _dataAdapter.Update(_dataset, "Game");
                Console.WriteLine("{0} rows commited ", rowsAffected);
            } 
            catch (Exception e) {
                Console.WriteLine(e.Message);
            }
        }
    }
    
    internal class Lab12Pavlov
    {
        private static void Main()
        {
            var mode = ConfigurationManager.AppSettings.Get("Mode");

            using (SqlConnection conn = new SqlConnection(ConfigurationManager.AppSettings.Get("ConnStringDB")))
            {
                if (mode == "linked")
                {
                    var exec = new LinkedExecutor(conn);
                    exec.Select();
                    Console.WriteLine();
                    exec.Delete(9);
                    exec.Select();
                    Console.WriteLine();
                    exec.Insert(9, "Some Test Game", DateTime.Now, "Some Description", 
                        Decimal.One, 1, 9);
                    exec.Select();
                    Console.WriteLine();
                    exec.Update(3, "Some UPDATED Game");
                    exec.Select();
                }
                else if (mode == "unlinked")
                {
                    var exec = new UnlinkedExecutor(conn);
                    exec.Select();
                    Console.WriteLine();
                    exec.Delete(9);
                    exec.Commit();
                    exec.Select();
                    Console.WriteLine();
                    exec.Insert(9, "Some Test Game", DateTime.Now, "Some Description", 
                        Decimal.One, 1, 9);
                    exec.Commit();
                    exec.Select();
                    Console.WriteLine();
                    exec.Update(3, "Some UPDATED Game");
                    exec.Commit();
                    exec.Select();
                }

                conn.Close();
            }
        }
    }
}
