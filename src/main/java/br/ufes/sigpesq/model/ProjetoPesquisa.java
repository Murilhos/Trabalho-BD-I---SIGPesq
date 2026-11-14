package br.ufes.sigpesq.model;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

public class ProjetoPesquisa {

    @NotBlank(message = "O código do projeto é obrigatório.")
    @Size(max = 20, message = "O código deve ter no máximo 20 caracteres.")
    private String codigo;

    @NotNull(message = "O coordenador principal é obrigatório.")
    private Integer idCoordenador;

    @NotBlank(message = "O título é obrigatório.")
    @Size(max = 200, message = "O título deve ter no máximo 200 caracteres.")
    private String titulo;

    @NotBlank(message = "A descrição é obrigatória.")
    private String descricao;

    @NotNull(message = "A data de início é obrigatória.")
    private LocalDate dataInicio;

    @NotNull(message = "A data de término é obrigatória.")
    private LocalDate dataTermino;

    @NotBlank(message = "A situação é obrigatória.")
    @Pattern(regexp = "Em andamento|Concluido|Cancelado",
             message = "RN-03: A situação deve ser Em andamento, Concluido ou Cancelado.")
    private String situacao = "Em andamento";

    private boolean ativo = true;

    /** Preenchido apenas nas listagens (JOIN com participante). */
    private String nomeCoordenador;

    /** Remove espacos extras e aplica o valor padrao da situacao. */
    public void normalizar() {
        if (codigo != null) codigo = codigo.trim();
        if (titulo != null) titulo = titulo.trim();
        if (descricao != null) descricao = descricao.trim();
        if (situacao == null || situacao.isBlank()) situacao = "Em andamento";
    }

    // Valores nulos ja sao barrados pelos @NotNull; aqui so comparamos quando ha as duas datas.
    @AssertTrue(message = "RN-10: A data de término deve ser posterior à data de início.")
    public boolean isPeriodoValido() {
        if (dataInicio == null || dataTermino == null) return true;
        return dataTermino.isAfter(dataInicio);
    }

    public String getCodigo() { return codigo; }
    public void setCodigo(String codigo) { this.codigo = codigo; }
    public Integer getIdCoordenador() { return idCoordenador; }
    public void setIdCoordenador(Integer idCoordenador) { this.idCoordenador = idCoordenador; }
    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }
    public String getDescricao() { return descricao; }
    public void setDescricao(String descricao) { this.descricao = descricao; }
    public LocalDate getDataInicio() { return dataInicio; }
    public void setDataInicio(LocalDate dataInicio) { this.dataInicio = dataInicio; }
    public LocalDate getDataTermino() { return dataTermino; }
    public void setDataTermino(LocalDate dataTermino) { this.dataTermino = dataTermino; }
    public String getSituacao() { return situacao; }
    public void setSituacao(String situacao) { this.situacao = situacao; }
    public boolean isAtivo() { return ativo; }
    public void setAtivo(boolean ativo) { this.ativo = ativo; }
    public String getNomeCoordenador() { return nomeCoordenador; }
    public void setNomeCoordenador(String nomeCoordenador) { this.nomeCoordenador = nomeCoordenador; }
}
