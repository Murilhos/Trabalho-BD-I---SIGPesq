package br.ufes.sigpesq.config;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

/**
 * Le as configuracoes do arquivo .env (na raiz do projeto).
 * Se uma variavel nao estiver no arquivo, tenta as variaveis de ambiente do sistema.
 */
public class EnvLoader {
    private static final Map<String, String> VALORES = new HashMap<>();

    static {
        Path arquivo = Path.of(".env");
        if (Files.exists(arquivo)) {
            try {
                for (String linha : Files.readAllLines(arquivo)) {
                    linha = linha.trim();
                    if (!linha.isEmpty() && !linha.startsWith("#") && linha.contains("=")) {
                        String[] partes = linha.split("=", 2);
                        VALORES.put(partes[0].trim(), partes[1].trim());
                    }
                }
            } catch (IOException e) {
                throw new RuntimeException("Erro ao ler o arquivo .env", e);
            }
        }
    }

    /** Retorna o valor da variavel ou lanca erro se ela nao existir. */
    public static String get(String chave) {
        String valor = get(chave, null);
        if (valor == null) {
            throw new IllegalStateException("Variavel '" + chave + "' nao encontrada. "
                    + "Copie .env.example para .env na raiz do projeto.");
        }
        return valor;
    }

    /** Retorna o valor da variavel ou o padrao informado. */
    public static String get(String chave, String padrao) {
        String valor = VALORES.get(chave);
        if (valor == null) valor = System.getenv(chave);
        return valor != null ? valor : padrao;
    }
}
