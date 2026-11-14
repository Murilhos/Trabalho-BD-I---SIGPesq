package br.ufes.sigpesq.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {

    /** Abre uma nova conexao com o MySQL. Quem chama deve fechar (try-with-resources). */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(
            EnvLoader.get("DB_URL"),
            EnvLoader.get("DB_USER"),
            EnvLoader.get("DB_PASS")
        );
    }
}
