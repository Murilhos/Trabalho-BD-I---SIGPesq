package br.ufes.sigpesq.validation;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import java.util.Set;
import java.util.stream.Collectors;

public class ValidadorEntidade {
    private static final ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
    private static final Validator validator = factory.getValidator();

    /** Valida as anotacoes do objeto; se algo falhar, lanca IllegalArgumentException com as mensagens. */
    public static <T> void validar(T objeto) {
        Set<ConstraintViolation<T>> violacoes = validator.validate(objeto);
        if (!violacoes.isEmpty()) {
            String erros = violacoes.stream()
                .map(ConstraintViolation::getMessage)
                .sorted()
                .collect(Collectors.joining(" | "));
            throw new IllegalArgumentException(erros);
        }
    }
}
