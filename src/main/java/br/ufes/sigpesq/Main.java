package br.ufes.sigpesq;

import br.ufes.sigpesq.config.DatabaseConnection;
import br.ufes.sigpesq.config.EnvLoader;
import br.ufes.sigpesq.web.Servidor;
import java.sql.Connection;
import java.sql.SQLException;

public class Main {
    public static void main(String[] args) throws Exception {
        // 1. Testa o banco antes de subir o servidor
        try (Connection con = DatabaseConnection.getConnection()) {
            System.out.println("Conectado ao MySQL: " + con.getMetaData().getURL());
        } catch (SQLException e) {
            System.err.println("Nao foi possivel conectar ao MySQL: " + e.getMessage());
            System.err.println("O container esta no ar? Rode: docker compose up -d");
            System.exit(1);
        }

        // 2. Sobe o servidor web
        int porta = Integer.parseInt(EnvLoader.get("APP_PORT", "8080"));
        Servidor.iniciar(porta);
        System.out.println("SIGPesq no ar: http://localhost:" + porta);
    }
}
