package br.ufes.sigpesq.dao;

import br.ufes.sigpesq.config.DatabaseConnection;
import br.ufes.sigpesq.model.Participante;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class ParticipanteDAO {

    /** Docentes ativos: so eles podem ser coordenadores (RN-02). */
    public List<Participante> listarDocentesAtivos() {
        String sql = "SELECT id_participante, nome FROM participante "
                   + "WHERE tipo = 'Docente' AND ativo = TRUE ORDER BY nome";
        List<Participante> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Participante p = new Participante();
                p.setIdParticipante(rs.getInt("id_participante"));
                p.setNome(rs.getString("nome"));
                p.setTipo("Docente");
                lista.add(p);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Erro ao listar docentes", e);
        }
        return lista;
    }
}
