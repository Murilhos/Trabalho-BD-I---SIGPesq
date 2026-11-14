package br.ufes.sigpesq.dao;

import br.ufes.sigpesq.config.DatabaseConnection;
import br.ufes.sigpesq.model.ProjetoPesquisa;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class ProjetoPesquisaDAO {

    /** Lista os projetos ativos, com o nome do coordenador (RF-05). */
    public List<ProjetoPesquisa> listar() {
        String sql = "SELECT p.codigo, p.id_coordenador, c.nome AS coordenador, p.titulo, p.descricao, "
                   + "p.data_inicio, p.data_termino, p.situacao, p.ativo "
                   + "FROM projeto_pesquisa p "
                   + "JOIN participante c ON c.id_participante = p.id_coordenador "
                   + "WHERE p.ativo = TRUE ORDER BY p.codigo";
        List<ProjetoPesquisa> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ProjetoPesquisa p = new ProjetoPesquisa();
                p.setCodigo(rs.getString("codigo"));
                p.setIdCoordenador(rs.getInt("id_coordenador"));
                p.setNomeCoordenador(rs.getString("coordenador"));
                p.setTitulo(rs.getString("titulo"));
                p.setDescricao(rs.getString("descricao"));
                p.setDataInicio(rs.getDate("data_inicio").toLocalDate());
                p.setDataTermino(rs.getDate("data_termino").toLocalDate());
                p.setSituacao(rs.getString("situacao"));
                p.setAtivo(rs.getBoolean("ativo"));
                lista.add(p);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Erro ao listar projetos", e);
        }
        return lista;
    }

    /** Cadastra um projeto (RF-01). As regras do banco (RN-02, RN-03, RN-04, RN-10) sao reaplicadas aqui. */
    public void inserir(ProjetoPesquisa p) {
        String sql = "INSERT INTO projeto_pesquisa "
                   + "(codigo, id_coordenador, titulo, descricao, data_inicio, data_termino, situacao) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, p.getCodigo());
            ps.setInt(2, p.getIdCoordenador());
            ps.setString(3, p.getTitulo());
            ps.setString(4, p.getDescricao());
            ps.setDate(5, Date.valueOf(p.getDataInicio()));
            ps.setDate(6, Date.valueOf(p.getDataTermino()));
            ps.setString(7, p.getSituacao());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw traduzir(e);
        }
    }

    /** Converte erros do MySQL em mensagens que o usuario entende. */
    private RuntimeException traduzir(SQLException e) {
        if ("45000".equals(e.getSQLState())) {            // SIGNAL dos triggers
            return new IllegalArgumentException(e.getMessage());
        }
        return switch (e.getErrorCode()) {
            case 1062 -> new IllegalArgumentException("RN-04: já existe um projeto com esse código.");
            case 1452 -> new IllegalArgumentException("O coordenador informado não existe.");
            case 3819 -> new IllegalArgumentException("Os dados violam uma regra de validação do banco (ex.: datas ou situação).");
            default -> new RuntimeException("Erro ao gravar no banco", e);
        };
    }
}
