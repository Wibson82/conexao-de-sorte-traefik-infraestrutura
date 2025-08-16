# 📊 ANÁLISE DE MÉTRICAS E CONFLITOS

## 🔍 Busca por Registros de Métricas Duplicados

### 📈 Registros de Métricas Encontrados

/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/metricas/ControladorMetricas.java:    @GetMapping("/timers")
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/metricas/ControladorMetricas.java:            resposta.put("timers", metricas.get("timers"));
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/metrics/RateLimitMetricsWebFilter.java:        // Dois counters com a mesma métrica mas tags diferentes (result=allowed|blocked)
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/metrics/RateLimitMetricsWebFilter.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/metrics/RateLimitMetricsWebFilter.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:    private Timer timerConsultasSessao;
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:    private Timer timerConsultasLog;
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:        timerConsultasSessao = Timer.builder(METRICA_CONSULTAS_SESSAO)
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:        timerConsultasLog = Timer.builder(METRICA_CONSULTAS_LOG)
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:        timerConsultasSessao.record(tempoExecucaoMs, java.util.concurrent.TimeUnit.MILLISECONDS);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java:        timerConsultasLog.record(tempoExecucaoMs, java.util.concurrent.TimeUnit.MILLISECONDS);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:            meterRegistry.gauge("jwt.chave.idade_horas", idadeChave.toHours());
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:        meterRegistry.counter("jwt.rotacao.sucesso").increment();
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:        meterRegistry.gauge("jwt.chave.idade_horas", 0); // Nova chave tem idade 0
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:                meterRegistry.counter("jwt.backup.sucesso").increment();
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:                meterRegistry.gauge("jwt.backup.ultimo_timestamp", System.currentTimeMillis());
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:                meterRegistry.counter("jwt.backup.falha", "motivo", "chaves_nao_carregadas").increment();
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:            meterRegistry.counter("jwt.backup.falha", "motivo", "erro_io").increment();
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:            meterRegistry.gauge("jwt.chave.idade_horas", idadeChave.toHours());
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:            meterRegistry.gauge("jwt.chave.proxima_rotacao_horas", Math.max(0, horasRotacaoChave - idadeChave.toHours()));
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:        meterRegistry.gauge("jwt.configuracao.rotacao_horas", horasRotacaoChave);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:        meterRegistry.gauge("jwt.configuracao.backup_habilitado", backupChaveHabilitado ? 1 : 0);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java:        meterRegistry.gauge("jwt.configuracao.tamanho_chave", TAMANHO_CHAVE_RSA);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:        // Inicialização de timers com programação defensiva
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:        this.tempoResposta = Timer.builder(CHAT_PREFIX + ".timer.resposta")
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:        // Inicialização de gauges com API correta do Micrometer
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:                .register(meterRegistry);
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:     * Inicia um timer genérico (compatibilidade com código legado).
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:     * Obtém um timer específico por nome (compatibilidade com código legado).
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:     * @param nomeTimer Nome do timer desejado
/Volumes/NVME/Projetos/conexao-de-sorte-backend/src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/metricas/RegistroMetricasBatePapo.java:     * @return Timer correspondente ao nome ou timer padrão
