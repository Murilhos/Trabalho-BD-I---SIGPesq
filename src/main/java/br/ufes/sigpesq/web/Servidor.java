package br.ufes.sigpesq.web;

import br.ufes.sigpesq.dao.ParticipanteDAO;
import br.ufes.sigpesq.dao.ProjetoPesquisaDAO;
import br.ufes.sigpesq.model.ProjetoPesquisa;
import br.ufes.sigpesq.validation.ValidadorEntidade;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonParseException;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonSerializer;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Map;

/** Servidor web simples (JDK puro): serve a pasta public/ e a API JSON em /api. */
public class Servidor {

    private record Opcao(int id, String nome) {}

    private static final Gson GSON = new GsonBuilder()
        .registerTypeAdapter(LocalDate.class,
            (JsonSerializer<LocalDate>) (data, tipo, ctx) -> new JsonPrimitive(data.toString()))
        .registerTypeAdapter(LocalDate.class,
            (JsonDeserializer<LocalDate>) (json, tipo, ctx) -> {
                String texto = json.getAsString();
                if (texto == null || texto.isBlank()) return null;
                try {
                    return LocalDate.parse(texto);
                } catch (DateTimeParseException e) {
                    throw new JsonParseException("Data inválida: " + texto);
                }
            })
        .create();

    private static final ProjetoPesquisaDAO projetoDAO = new ProjetoPesquisaDAO();
    private static final ParticipanteDAO participanteDAO = new ParticipanteDAO();

    public static void iniciar(int porta) throws IOException {
        HttpServer servidor = HttpServer.create(new InetSocketAddress(porta), 0);
        servidor.createContext("/api/projetos", Servidor::projetos);
        servidor.createContext("/api/docentes", Servidor::docentes);
        servidor.createContext("/", Servidor::estatico);
        servidor.start();
    }

    // GET /api/projetos -> lista | POST /api/projetos -> cadastra
    private static void projetos(HttpExchange ex) throws IOException {
        try {
            String metodo = ex.getRequestMethod();
            if (metodo.equals("GET")) {
                responder(ex, 200, GSON.toJson(projetoDAO.listar()));
            } else if (metodo.equals("POST")) {
                String corpo = new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
                ProjetoPesquisa p = GSON.fromJson(corpo, ProjetoPesquisa.class);
                if (p == null) throw new IllegalArgumentException("Corpo da requisição vazio.");
                p.normalizar();
                ValidadorEntidade.validar(p);   // 1a camada: Bean Validation
                projetoDAO.inserir(p);          // 2a camada: constraints e triggers do MySQL
                responder(ex, 201, GSON.toJson(p));
            } else {
                responder(ex, 405, erro("Método não permitido."));
            }
        } catch (IllegalArgumentException | JsonParseException e) {
            responder(ex, 400, erro(e.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            responder(ex, 500, erro("Erro interno do servidor."));
        }
    }

    // GET /api/docentes -> id e nome dos docentes (sem CPF/e-mail, por causa da LGPD)
    private static void docentes(HttpExchange ex) throws IOException {
        try {
            List<Opcao> opcoes = participanteDAO.listarDocentesAtivos().stream()
                .map(p -> new Opcao(p.getIdParticipante(), p.getNome()))
                .toList();
            responder(ex, 200, GSON.toJson(opcoes));
        } catch (Exception e) {
            e.printStackTrace();
            responder(ex, 500, erro("Erro interno do servidor."));
        }
    }

    // Serve os arquivos de src/main/resources/public (index.html, app.js...)
    private static void estatico(HttpExchange ex) throws IOException {
        String caminho = ex.getRequestURI().getPath();
        if (caminho.equals("/")) caminho = "/index.html";
        if (caminho.contains("..")) {
            responder(ex, 400, erro("Caminho inválido."));
            return;
        }
        try (InputStream in = Servidor.class.getResourceAsStream("/public" + caminho)) {
            if (in == null) {
                responder(ex, 404, erro("Arquivo não encontrado."));
                return;
            }
            byte[] dados = in.readAllBytes();
            ex.getResponseHeaders().set("Content-Type", tipoDoArquivo(caminho));
            ex.sendResponseHeaders(200, dados.length);
            try (OutputStream os = ex.getResponseBody()) { os.write(dados); }
        }
    }

    private static String tipoDoArquivo(String caminho) {
        if (caminho.endsWith(".html")) return "text/html; charset=utf-8";
        if (caminho.endsWith(".js"))   return "text/javascript; charset=utf-8";
        if (caminho.endsWith(".css"))  return "text/css; charset=utf-8";
        return "application/octet-stream";
    }

    private static String erro(String mensagem) {
        return GSON.toJson(Map.of("erro", mensagem == null ? "Erro inesperado." : mensagem));
    }

    private static void responder(HttpExchange ex, int status, String json) throws IOException {
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        ex.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        ex.sendResponseHeaders(status, bytes.length);
        try (OutputStream os = ex.getResponseBody()) { os.write(bytes); }
    }
}
