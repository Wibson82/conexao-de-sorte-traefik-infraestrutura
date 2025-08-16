# 📋 RELATÓRIO DE CLASSES DUPLICADAS E SIMILARES

## 🔍 Metodologia
- Busca por classes com nomes similares
- Identificação de sufixos problemáticos (*Consolidada, *Refatorado, etc.)
- Análise de pacotes incorretos
- Detecção de nomes em inglês vs português

## 📊 RESULTADOS DA ANÁLISE

### 🚨 Classes com Sufixos Problemáticos

- **ConfiguracaoRecursosUnificada** → `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/ConfiguracaoRecursosUnificada.java`
- **ConfiguracaoExecutoresConsolidada** → `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/sistema/ConfiguracaoExecutoresConsolidada.java`
- **ConfiguracaoJpaConsolidada** → `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/jpa/ConfiguracaoJpaConsolidada.java`
- **ConfiguracaoWebSocketConsolidada** → `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/web/websocket/ConfiguracaoWebSocketConsolidada.java`
- **ConfiguracaoAuditoriaConsolidada** → `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaConsolidada.java`
- **ServicoAuditoriaUnificada** → `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoriaUnificada.java`

### 🔄 Classes com Nomes Similares

**Grupo: PerformanceTest** (       2 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/util/PerformanceTest.java`
  - `src/test/performance/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/performance/ExtracaoPublicaPerformanceTest.java`

**Grupo: HorarioValidoDTO** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/horario/HorarioValidoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/sistema/RequisicaoHorarioValidoDTO.java`

**Grupo: VisualizacaoDTO** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/estatistica/VisualizacaoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/estatistica/EstatisticaVisualizacaoDTO.java`

**Grupo: RespostaDTO** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/erro/ErroRespostaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/comum/RespostaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/OperacaoGrupoRespostaDTO.java`

**Grupo: ContaDTO** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/contas/ContaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/contas/TransacaoContaDTO.java`

**Grupo: AuditoriaDTO** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/EstatisticaAuditoriaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/RegistroAuditoriaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/AuditoriaDTO.java`

**Grupo: ManipuladorExcecoesGlobal** (       2 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/controlador/excecao/ManipuladorExcecoesGlobalTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/excecao/ManipuladorExcecoesGlobal.java`

**Grupo: LoteriaDTO** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/dto/loteria/LoteriaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/dto/FabricaLoteriaDTO.java`

**Grupo: ControladorResultado** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/controle/ControladorResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/controle/ControladorResultadoLoteria.java`

**Grupo: ControladorExtracaoPublica** (       2 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/controller/ControladorExtracaoPublicaTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/controle/ControladorExtracaoPublica.java`

**Grupo: ServicoResultadoLoteria** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/loteria/ServicoResultadoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/ServicoResultadoLoteriaExtensao.java`

**Grupo: ServicoResultado** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/loteria/ServicoResultadoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/ServicoResultadoLoteriaExtensao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/ServicoResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/servico/ExcecaoServicoResultado.java`

**Grupo: ServicoExtracaoPublica** (       2 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/service/ServicoExtracaoPublicaTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/ServicoExtracaoPublica.java`

**Grupo: ServicoSessao** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoSessaoComFallback.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoSessaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoSessao.java`

**Grupo: ValidadorUsuario** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ValidadorUsuarioServico.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/util/ValidadorUsuario.java`

**Grupo: PublicadorEventoUsuario** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ImplementacaoPublicadorEventoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/PublicadorEventoUsuario.java`

**Grupo: GerenciadorLocksUsuario** (       2 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/service/GerenciadorLocksUsuarioTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/GerenciadorLocksUsuario.java`

**Grupo: MensagemDTO** (       4 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/EventoMensagemDTOTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/ResumoMensagemDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/EventoMensagemDTO.java`

**Grupo: PresencaUsuarioDTO** (       2 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/PresencaUsuarioDTOTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/PresencaUsuarioDTO.java`

**Grupo: MensagemBatePapoDTO** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/EnviarMensagemBatePapoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemBatePapoDTO.java`

**Grupo: GrupoDTO** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/CriarGrupoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/GrupoDTO.java`

**Grupo: MensagemWebSocketDTO** (       2 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemWebSocketDTOTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemWebSocketDTO.java`

**Grupo: ConversaDTO** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/CriarConversaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/ConversaDTO.java`

**Grupo: EventoMensagemDTO** (       2 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/EventoMensagemDTOTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/EventoMensagemDTO.java`

**Grupo: ComandoMensagemBatePapo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/comando/impl/ComandoMensagemBatePapoImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/comando/ComandoMensagemBatePapo.java`

**Grupo: ComandoMensagemBatePapo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/comando/impl/ComandoMensagemBatePapoImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/comando/ComandoMensagemBatePapo.java`

**Grupo: MensagemBatePapoService** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/impl/MensagemBatePapoServiceImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/RetencaoMensagemBatePapoService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/MensagemBatePapoService.java`

**Grupo: CriptografiaBatePapo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/crypto/CriptografiaBatePapoService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/chat/ExcecaoCriptografiaBatePapo.java`

**Grupo: ConsultaMensagemBatePapo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/consulta/impl/ConsultaMensagemBatePapoImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/consulta/ConsultaMensagemBatePapo.java`

**Grupo: ConsultaMensagemBatePapo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/consulta/impl/ConsultaMensagemBatePapoImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/consulta/ConsultaMensagemBatePapo.java`

**Grupo: ConversaBatePapo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/ConversaBatePapoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/ConversaBatePapoService.java`

**Grupo: Conversa** (      15 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/UsuarioConversasGerenciador.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/CriarConversaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/ConversaBatePapoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/ConversaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/controle/ConversaControlador.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/ConversaBatePapoService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/ServicoTipoConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/servico/ConversaServico.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/batepapo/MapeadorConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/valor/batepapo/IdentificadorConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/batepapo/Conversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/chat/ExcecaoConversaNaoEncontrada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/conversa/CodigosErroConversa.java`

**Grupo: AnexoBatePapo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/AnexoBatePapoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/AnexoBatePapoService.java`

**Grupo: MensagemBatePapo** (       9 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/EnviarMensagemBatePapoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemBatePapoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/comando/impl/ComandoMensagemBatePapoImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/comando/ComandoMensagemBatePapo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/impl/MensagemBatePapoServiceImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/consulta/impl/ConsultaMensagemBatePapoImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/consulta/ConsultaMensagemBatePapo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/RetencaoMensagemBatePapoService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/MensagemBatePapoService.java`

**Grupo: ModalidadeDTO** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/dto/ItemModalidadeDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/dto/ModalidadeDTO.java`

**Grupo: MapeadorLoteria** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/loteria/fabrica/MapeadorLoteriaFabrica.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/loteria/MapeadorLoteria.java`

**Grupo: GerenciadorChaves** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/seguranca/GerenciadorChavesJwt.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/jwt/GerenciadorChaves.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/seguranca/GerenciadorChavesCacheLRU.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/criptografia/GerenciadorChavesCriptografia.java`

**Grupo: ConfiguracaoAzureKeyVault** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/azure/ConfiguracaoAzureKeyVault.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/integracao/azure/ConfiguracaoAzureKeyVaultSpringCloud.java`

**Grupo: ConfiguracaoSeguranca** (       5 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/ConfiguracaoSeguranca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/reactive/ConfiguracaoSegurancaHealthWebFlux.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/reactive/ConfiguracaoSegurancaHeadersWebFlux.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/reactive/ConfiguracaoSegurancaOAuth2WebFlux.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/reactive/ConfiguracaoSegurancaWebFlux.java`

**Grupo: ConfiguracaoCache** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/cache/ConfiguracaoCacheAvancado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/cache/ConfiguracaoCache.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/batepapo/ConfiguracaoCacheBatePapo.java`

**Grupo: ServicoCache** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/cache/ServicoCache.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/cache/ServicoCacheIpsRecentes.java`

**Grupo: ConfiguracaoJpa** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/jpa/ConfiguracaoJpaConsolidada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/persistencia/ConfiguracaoJpaRepositorios.java`

**Grupo: GeradorToken** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/token/GeradorToken.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/util/GeradorTokens.java`

**Grupo: PropriedadesSeguranca** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/PropriedadesSeguranca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/ConfiguracaoPropriedadesSeguranca.java`

**Grupo: ConstantesURL** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/ConstantesURL.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesURLs.java`

**Grupo: RegistroUrlSeguranca** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/registro/RegistroUrlSegurancaSimplificado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/registro/RegistroUrlSeguranca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/adaptador/AdaptadorRegistroUrlSeguranca.java`

**Grupo: ValidadorUrl** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/util/ValidadorUrl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/ValidadorUrlUnificado.java`

**Grupo: ProvedorUrl** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/provedores/ProvedorUrlPagina.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/provedores/ProvedorUrl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/ProvedorUrlBase.java`

**Grupo: ConfiguracaoUrlSeguranca** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/ConfiguracaoUrlSegurancaSimplificada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/ConfiguracaoUrlSeguranca.java`

**Grupo: EstrategiaDetecaoComportamento** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/estrategia/EstrategiaDetecaoComportamentoSimples.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/estrategia/EstrategiaDetecaoComportamento.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/estrategia/EstrategiaDetecaoComportamentoAvancada.java`

**Grupo: Validacao** (      26 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TentativaValidacaoTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/erro/ErroValidacaoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/verificacao/RequisicaoValidacaoCodigoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/servico/ValidacaoIntegridadeService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoValidacaoSenha.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoTentativaValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoConsultaTentativaValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoValidacaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/validacao/ServicoValidacaoEntrada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/validacao/Validacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/validacao/ValidacaoCampo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/GruposValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidacaoAtualizacaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ServicoValidacaoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidacaoCriacaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/ServicoValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioTentativaValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/ValidacaoSite.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TentativaValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/negocio/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesValidacaoConsolidadas.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/validacao/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/ViolacaoValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/validacao/ExcecaoValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/validacao/CodigosErroValidacao.java`

**Grupo: UsuarioCriadoEvent** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/evento/UsuarioCriadoEvent.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/usuario/UsuarioCriadoEvent.java`

**Grupo: Auditavel** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/Auditavel.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/base/RevisaoAuditavel.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/base/EntidadeAuditavel.java`

**Grupo: ProcessadorEventosAuditoria** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ProcessadorEventosAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoProcessadorEventosAuditoria.java`

**Grupo: ConfiguracaoAuditoria** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaSegurancaAvancada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaPerformance.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaConsolidada.java`

**Grupo: ConfiguracaoPropriedades** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/cache/ConfiguracaoPropriedadesCache.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/ConfiguracaoPropriedadesSeguranca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/ConfiguracaoPropriedades.java`

**Grupo: ServicoNotificacao** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/notificacao/ServicoNotificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/notificacao/ServicoNotificacaoAdmin.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/notificacao/ServicoNotificacaoPush.java`

**Grupo: ServicoExtracaoLoteria** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoLoteriaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ServicoExtracaoLoteria.java`

**Grupo: ValidadorResultado** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ValidadorResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/ValidadorResultadoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/ValidadorResultadoLoteriaRefatorado.java`

**Grupo: ServicoExtracao** (      11 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/service/ServicoExtracaoPublicaTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/ServicoExtracaoPublica.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoLoteriaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoArmazenamentoRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoArmazenamento.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ServicoExtracaoLoteria.java`

**Grupo: ExtratorResultadoQuina** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoQuinaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoQuina.java`

**Grupo: ServicoExtracaoArmazenamento** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoArmazenamentoRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoArmazenamento.java`

**Grupo: ExtratorResultadoDeuNoPoste** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDeuNoPosteRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDeuNoPoste.java`

**Grupo: ExtratorResultadoLoteriaBase** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLoteriaBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultadoLoteriaBaseRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultadoLoteriaBase.java`

**Grupo: ExtratorResultadoMegaSena** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMegaSenaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMegaSena.java`

**Grupo: ValidadorCriacaoUsuario** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorCriacaoUsuarioRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorCriacaoUsuario.java`

**Grupo: ValidadorHorarioData** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorHorarioDataRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorHorarioData.java`

**Grupo: SenhaForte** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/SenhaForteValidatorRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/SenhaForte.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/SenhaForteValidator.java`

**Grupo: Maioridade** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/MaioridadeValidator.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/Maioridade.java`

**Grupo: ValidadorCPF** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorCPF.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorCPFRefatorado.java`

**Grupo: SenhaForteValidator** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/SenhaForteValidatorRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/SenhaForteValidator.java`

**Grupo: ServicoValidacao** (       5 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoValidacaoSenha.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoValidacaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/validacao/ServicoValidacaoEntrada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ServicoValidacaoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/ServicoValidacao.java`

**Grupo: MetricasAuditoria** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/auditoria/MetricasAuditoriaService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/auditoria/ExcecaoMetricasAuditoria.java`

**Grupo: ExtratorResultado** (      21 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoPortalBrasil.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLotomania.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoQuinaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoSuperSete.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoFederal.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLoteca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDiaDeSorte.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDeuNoPosteRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoOclick.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMegaSenaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoTimemania.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDuplaSena.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLotofacil.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMaisMilionaria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoQuina.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDeuNoPoste.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLoteriaBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMegaSena.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultadoLoteriaBaseRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultadoLoteriaBase.java`

**Grupo: ServicoExtracaoLoteria** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoLoteriaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ServicoExtracaoLoteria.java`

**Grupo: ExtratorResultadoLoteriaBase** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLoteriaBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultadoLoteriaBaseRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultadoLoteriaBase.java`

**Grupo: ValidadorUsuario** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ValidadorUsuarioServico.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/util/ValidadorUsuario.java`

**Grupo: RepositorioTransacao** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioTransacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioTransacaoItem.java`

**Grupo: RepositorioAuditoria** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioAuditoriaUnificado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioAuditoria.java`

**Grupo: ServicoAuditoria** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/privacidade/ServicoAuditoriaDados.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoriaUnificada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/core/ServicoAuditoriaCore.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoria.java`

**Grupo: ValidadorAuditoria** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/core/ValidadorAuditoriaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/core/ValidadorAuditoria.java`

**Grupo: ServicoAuditoria** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/privacidade/ServicoAuditoriaDados.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoriaUnificada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/core/ServicoAuditoriaCore.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoria.java`

**Grupo: EstrategiaAuditoria** (       6 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoriaUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoriaResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoriaBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoriaBatePapo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/estrategia/GerenciadorEstrategiaAuditoria.java`

**Grupo: CpfEncryptionConverter** (       2 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/criptografia/CpfEncryptionConverterTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/criptografia/CpfEncryptionConverter.java`

**Grupo: CPF** (       5 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/CPFValido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorCPF.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorCPFRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/persistencia/converter/CPFConverter.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/valueobject/CPF.java`

**Grupo: Email** (      10 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/email/EnvioEmailDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioEnvioEmail.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/persistencia/converter/EmailConverter.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/email/ConfiguracaoEmailNotificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/email/ServicoEnvioEmail.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/criptografia/EmailEncryptionConverter.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/valueobject/Email.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/comunicacao/EnvioEmail.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/sistema/ExcecaoConfigEmail.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/email/CodigosErroEmail.java`

**Grupo: Telefone** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/persistencia/converter/TelefoneConverter.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/criptografia/TelefoneEncryptionConverter.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/valueobject/Telefone.java`

**Grupo: UsuarioRepositoryReativo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/adapter/UsuarioRepositoryReativoAdapter.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/repositorio/UsuarioRepositoryReativo.java`

**Grupo: LoteriaRepositoryReativo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/adapter/LoteriaRepositoryReativoAdapter.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/repositorio/LoteriaRepositoryReativo.java`

**Grupo: ControleSistema** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioControleSistema.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/controle/ControleSistema.java`

**Grupo: TipoUsuario** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/usuario/ServicoTipoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoUsuario.java`

**Grupo: Grupo** (      10 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/CriarGrupoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/OperacaoGrupoRespostaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/GrupoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/batepapo/MapeadorGrupo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/GruposValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioGrupo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/Grupo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/batepapo/ExcecaoServicoGrupo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/grupo/CodigosErroGrupo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/grupo/ExcecaoServicoGrupo.java`

**Grupo: Prioridade** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/Prioridade.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/notificacao/Prioridade.java`

**Grupo: Mensagem** (      33 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/EventoMensagemDTOTest.java`
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemWebSocketDTOTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/EnviarMensagemBatePapoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/ResumoMensagemDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemBatePapoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemWebSocketDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/EventoMensagemDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/comando/impl/ComandoMensagemBatePapoImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/comando/ComandoMensagemBatePapo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/impl/MensagemBatePapoServiceImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/consulta/impl/ConsultaMensagemBatePapoImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/consulta/ConsultaMensagemBatePapo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/RetencaoMensagemBatePapoService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/MensagemBatePapoService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/batepapo/MapeadorMensagem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/mapeamento/MensagemMapper.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioMensagem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/valor/batepapo/ConteudoMensagem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/repositorio/MensagemRepositoryReativo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/modelo/MensagemDominio.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/Mensagem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/StatusMensagem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/MensagemResumo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/batepapo/EventoMensagemExcluida.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/batepapo/EventoMensagemLida.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/batepapo/EventoMensagemEditada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/batepapo/EventoMensagemEnviada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/invariante/MensagemInvariantes.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/MensagemDoCampo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/mensagem/CodigosErroMensagem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/mensagem/ExcecaoServicoMensagem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/batepapo/ExcecaoServicoMensagem.java`

**Grupo: EnvioEmail** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/email/EnvioEmailDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioEnvioEmail.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/email/ServicoEnvioEmail.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/comunicacao/EnvioEmail.java`

**Grupo: UsuarioSeguranca** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/autenticacao/MapeadorUsuarioSeguranca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/UsuarioSeguranca.java`

**Grupo: Visualizacao** (       5 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/estatistica/VisualizacaoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/estatistica/EstatisticaVisualizacaoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/estatistica/ServicoEstatisticaVisualizacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioVisualizacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/estatistica/Visualizacao.java`

**Grupo: TokenRevogado** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioTokenRevogado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TokenRevogado.java`

**Grupo: FalhaAutenticacao** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoFalhaAutenticacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioFalhaAutenticacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/FalhaAutenticacao.java`

**Grupo: TipoVerificacao** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoVerificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/verificacao/TipoVerificacao.java`

**Grupo: Prioridade** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/Prioridade.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/notificacao/Prioridade.java`

**Grupo: Notificacao** (      14 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/notificacao/NotificacaoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/notificacao/ControladorNotificacaoOperador.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/notificacao/MapeadorNotificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/NotificacaoInicializacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/evento/EventoNotificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/notificacao/ServicoNotificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/notificacao/ServicoNotificacaoAdmin.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/notificacao/ServicoNotificacaoPush.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioNotificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/email/ConfiguracaoEmailNotificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/notificacao/StatusNotificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/notificacao/TipoNotificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/notificacao/Notificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/notificacao/CodigosErroNotificacao.java`

**Grupo: Usuario** (      54 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/service/GerenciadorLocksUsuarioTest.java`
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/PresencaUsuarioDTOTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/estrategia/AtividadeUsuarioDetalhada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/AtividadeUsuarioResumo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/diagnostico/ControladorDiagnosticoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/dto/UsuarioUpdateDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/dto/UsuarioListagemDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/dto/UsuarioRequestDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/dto/UsuarioResponseDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/UsuarioConversasGerenciador.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/EventosUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoSessaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoSegurancaUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ImplementacaoPublicadorEventoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoValidacaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ValidadorUsuarioServico.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/PublicadorEventoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/GerenciadorLocksUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/PresencaUsuarioDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/presenca/ServicoPresencaUsuarios.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/evento/handler/UsuarioEventHandler.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/autenticacao/MapeadorUsuarioSeguranca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/UsuarioDetailsServiceImpl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/PapelUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/evento/UsuarioCriadoEvent.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ProvedorAuditorUsuarioAutenticado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/usuario/ServicoTipoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorAtualizacaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorCriacaoUsuarioRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidacaoAtualizacaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorCriacaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidacaoCriacaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/inicializacao/ServicoInicializacaoUsuarioTeste.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/mapeamento/UsuarioMapper.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/util/UsuarioTesteUtil.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/util/ContextoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/util/ValidadorUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/adapter/UsuarioRepositoryReativoAdapter.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioSessaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoriaUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/repositorio/UsuarioRepositoryReativo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/modelo/UsuarioDominio.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/UsuarioSeguranca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/Usuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/SessaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/usuario/UsuarioCriadoEvent.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/usuario/UsuarioAtualizadoEvent.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/invariante/UsuarioInvariantes.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/ValidadorInsercaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/InsercaoUsuarioValida.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/privacidade/ExcecaoUsuarioInativo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/usuario/CodigosErroUsuario.java`

**Grupo: AlteracaoCampo** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioAlteracaoCampo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAlteracaoCampo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/campos/AlteracaoCampo.java`

**Grupo: TipoItem** (       6 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/dto/TipoItemDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/controle/ControladorTipoItem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/servico/ServicoTipoItem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/transacao/MapeadorTipoItem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioTipoItem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoItem.java`

**Grupo: SessaoUsuario** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoSessaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioSessaoUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/SessaoUsuario.java`

**Grupo: Conversa** (      15 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/UsuarioConversasGerenciador.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/CriarConversaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/ConversaBatePapoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/ConversaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/controle/ConversaControlador.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/ConversaBatePapoService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/ServicoTipoConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/servico/ConversaServico.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/batepapo/MapeadorConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/valor/batepapo/IdentificadorConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/batepapo/Conversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/chat/ExcecaoConversaNaoEncontrada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/conversa/CodigosErroConversa.java`

**Grupo: Anexo** (       8 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/AnexoBatePapoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/AnexoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/servico/GerenciadorAnexos.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/AnexoBatePapoService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/batepapo/MapeadorAnexo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoAnexo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/batepapo/Anexo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/chat/ExcecaoAnexoMuitoGrande.java`

**Grupo: Horario** (      14 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/horario/HorarioValidoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/sistema/RequisicaoHorarioValidoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/publico/ControladorHorarioPublico.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/base/MapeadorHorarioValido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/sistema/ConfiguracaoHorarioValido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/horario/ServicoHorarioValido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/TipoHorario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorHorarioDataRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/validacao/ValidadorHorarioData.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioHorarioValido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/Horario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/HorarioValido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/horario/CodigosErroHorario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/horario/ExcecaoHorario.java`

**Grupo: Endereco** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/util/ValidadorEndereco.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioEndereco.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/comum/Endereco.java`

**Grupo: CodigoVerificacao** (       8 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/verificacao/CodigoVerificacaoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/verificacao/ControladorCodigoVerificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/verificacao/MapeadorCodigoVerificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/verificacao/ServicoCodigoVerificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioCodigoVerificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/verificacao/CodigoVerificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/autenticacao/CodigoVerificacaoConstantes.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/verificacao/ExcecaoCodigoVerificacao.java`

**Grupo: TipoVerificacao** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoVerificacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/verificacao/TipoVerificacao.java`

**Grupo: TipoConversa** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/ServicoTipoConversa.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoConversa.java`

**Grupo: TentativaValidacao** (       5 classes)
  - `src/test/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TentativaValidacaoTest.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoTentativaValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/servico/ServicoConsultaTentativaValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioTentativaValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TentativaValidacao.java`

**Grupo: Modalidade** (       7 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/dto/ItemModalidadeDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/dto/ModalidadeDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/transacao/MapeadorItemModalidade.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/transacao/MapeadorModalidade.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioModalidade.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/transacao/modalidade/Modalidade.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/transacao/modalidade/ItemModalidade.java`

**Grupo: ItemModalidade** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/dto/ItemModalidadeDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/transacao/MapeadorItemModalidade.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/transacao/modalidade/ItemModalidade.java`

**Grupo: ItemTransacao** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/dto/ItemTransacaoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/transacao/MapeadorItemTransacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioItemTransacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/transacao/item/ItemTransacao.java`

**Grupo: TransacaoComercial** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/dto/TransacaoComercialDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/servico/ServicoTransacaoComercial.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/transacao/MapeadorTransacaoComercial.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/transacao/TransacaoComercial.java`

**Grupo: ResultadoLotofacil** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoLotofacilDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLotofacil.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoLotofacil.java`

**Grupo: ResultadoDuplaSena** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDuplaSena.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoDuplaSena.java`

**Grupo: ResultadoMegaSena** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoMegaSenaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMegaSenaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMegaSena.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoMegaSena.java`

**Grupo: ResultadoQuina** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoQuinaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoQuinaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoQuina.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoQuina.java`

**Grupo: ResultadoFederal** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoFederalDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoFederal.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoFederal.java`

**Grupo: ResultadoLoteca** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoLotecaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLoteca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoLoteca.java`

**Grupo: ResultadoSuperSete** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoSuperSeteDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoSuperSete.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoSuperSete.java`

**Grupo: ResultadoLotomania** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoLotomaniaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLotomania.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoLotomania.java`

**Grupo: ResultadoLoteriaBase** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLoteriaBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultadoLoteriaBaseRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultadoLoteriaBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoLoteriaBase.java`

**Grupo: ResultadoTimemania** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoTimemaniaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoTimemania.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoTimemania.java`

**Grupo: ResultadoDiaDeSorte** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoDiaDeSorteDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDiaDeSorte.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoDiaDeSorte.java`

**Grupo: ResultadoMaisMilionaria** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoMaisMilionariaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMaisMilionaria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoMaisMilionaria.java`

**Grupo: Resultado** (      71 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoTimemaniaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoFederalDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoLotofacilDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoLotomaniaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoMaisMilionariaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoDiaDeSorteDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoQuinaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoLotecaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoSuperSeteDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/loteria/ResultadoMegaSenaDto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/dto/ResultadoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/dto/ExtracaoResultadoResponseDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/dto/ExtracaoResultadoRequestDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/controle/ControladorResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/controle/EventoResultadoSalvo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/controle/ControladorResultadoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/loteria/ServicoResultadoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/ResultadoEventoListener.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/ServicoResultadoLoteriaExtensao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/servico/ServicoResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/resultado/MapeadorResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoPortalBrasil.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLotomania.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoQuinaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoSuperSete.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoFederal.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLoteca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDiaDeSorte.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ValidadorResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDeuNoPosteRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoOclick.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMegaSenaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoTimemania.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDuplaSena.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLotofacil.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/cliente/ClienteExtracaoResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMaisMilionaria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/processador/ProcessadorExtracaoResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoQuina.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoDeuNoPoste.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoLoteriaBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ExtratorResultadoMegaSena.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/integridade/VerificadorIntegridadeResultados.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultadoLoteriaBaseRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/scraping/ExtratorResultadoLoteriaBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoriaResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoLotofacil.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoDuplaSena.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoMegaSena.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoQuina.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoFederal.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoLoteca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoSuperSete.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoLotomania.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoLoteriaBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoTimemania.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoDiaDeSorte.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/loteria/ResultadoMaisMilionaria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/resultado/Resultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/ValidadorResultadoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/ValidadorResultadoLoteriaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/loteria/ExcecaoExtrairResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/servico/ExcecaoServicoResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/ResultadoIndisponivelException.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/resultado/ExcecaoExtrairResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/resultado/CodigosErroResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/resultado/ExcecaoResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/resultado/ResultadoIndisponivelException.java`

**Grupo: TransacaoConta** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/contas/TransacaoContaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/contas/MapeadorTransacaoConta.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/contas/TransacaoConta.java`

**Grupo: Conta** (      13 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/contas/ContaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/contas/TransacaoContaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/contas/MapeadorConta.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/contas/MapeadorTransacaoConta.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/filtro/ContadorRequisicao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/GeradorNumeroConta.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioConta.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/contas/TransacaoConta.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/contas/Conta.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/ValidadorNumeroConta.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/ExcecaoNumeroContaInvalido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/contas/ExcecaoNumeroContaInvalido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/contas/CodigosErroContas.java`

**Grupo: HorarioValido** (       7 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/horario/HorarioValidoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/sistema/RequisicaoHorarioValidoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/base/MapeadorHorarioValido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/sistema/ConfiguracaoHorarioValido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/horario/ServicoHorarioValido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioHorarioValido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/HorarioValido.java`

**Grupo: Auditoria** (      53 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/EstatisticaAuditoriaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/AuditoriaResumoDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/RegistroAuditoriaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/AuditoriaFiltroDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/AuditoriaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/monitoramento/ServicoMonitoramentoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/privacidade/ServicoAuditoriaDados.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/auditoria/MapeadorAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/auditoria/MapeadorEventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/PropriedadesAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/reactive/FiltroAuditoriaWebFlux.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/LeitorAuditoriaTransacional.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaSegurancaAvancada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaPerformance.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/AuditoriaAspecto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ProcessadorEventosAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaConsolidada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/auditoria/MetricasAuditoriaService.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioAuditoriaUnificado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioEventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioEstatisticaAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoriaUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoriaUnificada.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/core/ValidadorAuditoriaRefatorado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/core/ValidadorAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/core/ServicoAuditoriaCore.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoriaResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoriaBase.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoriaBatePapo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/EstrategiaAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoProcessadorEventosAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/estrategia/GerenciadorEstrategiaAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoEstatisticaAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/IdentificacaoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/fabrica/FabricaEventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/StatusEventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/OrigemAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/AuditoriaEvento.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/EventoAuditoriaExtensao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/Auditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/EventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/DadosAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/EstatisticaAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/EntidadeRevisaoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/GerenciamentoStatusAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoEventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/auditoria/ConstantesAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/privacidade/ExcecaoAuditoriaDados.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/auditoria/CodigosErroAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/auditoria/ExcecaoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/auditoria/ExcecaoMetricasAuditoria.java`

**Grupo: EventoAuditoria** (       7 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/auditoria/MapeadorEventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioEventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/fabrica/FabricaEventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/StatusEventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/EventoAuditoriaExtensao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/EventoAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/TipoEventoAuditoria.java`

**Grupo: SessaoAtiva** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioSessaoAtiva.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/SessaoAtiva.java`

**Grupo: LogAcesso** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioLogAcesso.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/LogAcesso.java`

**Grupo: EstatisticaAuditoria** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/auditoria/EstatisticaAuditoriaDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioEstatisticaAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoEstatisticaAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/auditoria/EstatisticaAuditoria.java`

**Grupo: HistoricoSenha** (       5 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/dto/HistoricoSenhaResponseDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/autenticacao/MapeadorHistoricoSenha.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/cache/HistoricoSenhaCache.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioHistoricoSenha.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/HistoricoSenha.java`

**Grupo: Papel** (       6 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/dto/PapelDTO.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/mapeamento/autenticacao/MapeadorPapel.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/PapelUsuario.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/RepositorioPapel.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/contas/TipoPapel.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/Papel.java`

**Grupo: DomainEvent** (       6 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/DomainEventConfiguration.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/evento/DomainEventBus.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/evento/DomainEventHandler.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/evento/DomainEventStore.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/DomainEvent.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/AbstractDomainEvent.java`

**Grupo: UsuarioCriadoEvent** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/evento/UsuarioCriadoEvent.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/usuario/UsuarioCriadoEvent.java`

**Grupo: EventoBatePapo** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/evento/EventoBatePapoProducer.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/evento/EventoBatePapoConsumer.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/evento/batepapo/EventoBatePapo.java`

**Grupo: ConstantesValidacao** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/negocio/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesValidacaoConsolidadas.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/validacao/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesValidacao.java`

**Grupo: ConstantesConfiguracao** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/configuracao/ConstantesConfiguracao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/configuracao/ConstantesConfiguracaoConsolidadas.java`

**Grupo: ConstantesValidacao** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/negocio/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesValidacaoConsolidadas.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/validacao/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesValidacao.java`

**Grupo: ConstantesNumericas** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesNumericas.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesNumericasConsolidadas.java`

**Grupo: Constantes** (      33 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/url/ConstantesURL.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesTexto.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/temporal/ConstantesTempo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/loteria/ConstantesLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/gerenciamento/ConstantesGerenciamentoRecursos.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/autorizacao/ConstantesAutorizacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/core/ConstantesHTTP.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesURLs.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/web/ConstantesEndpoints.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/negocio/ConstantesDocumentosBrasil.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/negocio/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesSistema.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/configuracao/ConstantesConfiguracao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/configuracao/ConstantesConfiguracaoConsolidadas.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesMensagens.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/monitoramento/ConstantesMonitoramento.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/extracao/ConstantesExtracao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesValidacaoConsolidadas.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesPrivacidadeLGPD.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/infraestrutura/ConstantesMemoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/infraestrutura/ConstantesCriptografia.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/erro/ConstantesErro.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/seguranca/ConstantesSeguranca.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/seguranca/ConstantesDetecaoComportamento.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/autenticacao/CodigoVerificacaoConstantes.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/log/ConstantesLog.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/validacao/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesNumericas.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/comum/Constantes.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/auditoria/ConstantesAuditoria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesNumericasConsolidadas.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesNegocio.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesValidacao.java`

**Grupo: ConstantesValidacao** (       4 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/negocio/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesValidacaoConsolidadas.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/validacao/ConstantesValidacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/constantes/ConstantesValidacao.java`

**Grupo: ValidadorResultadoLoteria** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/ValidadorResultadoLoteria.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/ValidadorResultadoLoteriaRefatorado.java`

**Grupo: ExcecaoToken** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/token/ExcecaoTokenInvalido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/token/ExcecaoToken.java`

**Grupo: CodigosErroConfiguracao** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/tecnica/CodigosErroConfiguracao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/configuracao/CodigosErroConfiguracaoUrl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/configuracao/CodigosErroConfiguracao.java`

**Grupo: ExcecaoExtrairResultado** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/loteria/ExcecaoExtrairResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/resultado/ExcecaoExtrairResultado.java`

**Grupo: CodigosErroMapeamento** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/mapeamento/CodigosErroMapeamento.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/codigos/CodigosErroMapeamento.java`

**Grupo: CodigosErroNaoEncontrado** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/naoencontrado/CodigosErroNaoEncontrado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/negocio/CodigosErroNaoEncontrado.java`

**Grupo: ExcecaoServicoMensagem** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/mensagem/ExcecaoServicoMensagem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/batepapo/ExcecaoServicoMensagem.java`

**Grupo: CodigosErroNaoEncontrado** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/naoencontrado/CodigosErroNaoEncontrado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/negocio/CodigosErroNaoEncontrado.java`

**Grupo: CodigosErroConfiguracao** (       3 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/tecnica/CodigosErroConfiguracao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/configuracao/CodigosErroConfiguracaoUrl.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/configuracao/CodigosErroConfiguracao.java`

**Grupo: CodigosErroVersionamento** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/sistema/CodigosErroVersionamento.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/CodigosErroVersionamento.java`

**Grupo: ExcecaoVersionamentoConcorrencia** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/sistema/ExcecaoVersionamentoConcorrencia.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/ExcecaoVersionamentoConcorrencia.java`

**Grupo: ResultadoIndisponivelException** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/ResultadoIndisponivelException.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/resultado/ResultadoIndisponivelException.java`

**Grupo: ExcecaoExportacao** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/arquivo/ExcecaoExportacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/ExcecaoExportacao.java`

**Grupo: ExcecaoServicoMensagem** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/mensagem/ExcecaoServicoMensagem.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/batepapo/ExcecaoServicoMensagem.java`

**Grupo: ExcecaoServicoGrupo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/batepapo/ExcecaoServicoGrupo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/grupo/ExcecaoServicoGrupo.java`

**Grupo: ExcecaoNumeroContaInvalido** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/ExcecaoNumeroContaInvalido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/contas/ExcecaoNumeroContaInvalido.java`

**Grupo: CodigosErroVersionamento** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/sistema/CodigosErroVersionamento.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/CodigosErroVersionamento.java`

**Grupo: ExcecaoVersionamentoConcorrencia** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/sistema/ExcecaoVersionamentoConcorrencia.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/ExcecaoVersionamentoConcorrencia.java`

**Grupo: CodigosErroConflito** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/CodigosErroConflito.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/conflito/CodigosErroConflito.java`

**Grupo: ExcecaoExportacao** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/arquivo/ExcecaoExportacao.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/ExcecaoExportacao.java`

**Grupo: ExcecaoRegistroDuplicado** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/ExcecaoRegistroDuplicado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/conflito/ExcecaoRegistroDuplicado.java`

**Grupo: CodigosErroConflito** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/CodigosErroConflito.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/conflito/CodigosErroConflito.java`

**Grupo: ExcecaoRegistroDuplicado** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/ExcecaoRegistroDuplicado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/conflito/ExcecaoRegistroDuplicado.java`

**Grupo: ExcecaoExtrairResultado** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/loteria/ExcecaoExtrairResultado.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/resultado/ExcecaoExtrairResultado.java`

**Grupo: ResultadoIndisponivelException** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/ResultadoIndisponivelException.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/resultado/ResultadoIndisponivelException.java`

**Grupo: ExcecaoNumeroContaInvalido** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/comum/ExcecaoNumeroContaInvalido.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/contas/ExcecaoNumeroContaInvalido.java`

**Grupo: ExcecaoAuditoria** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/privacidade/ExcecaoAuditoriaDados.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/auditoria/ExcecaoAuditoria.java`

**Grupo: ExcecaoServicoGrupo** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/batepapo/ExcecaoServicoGrupo.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/grupo/ExcecaoServicoGrupo.java`

**Grupo: CodigosErroMapeamento** (       2 classes)
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/mapeamento/CodigosErroMapeamento.java`
  - `src/main/java/br/tec/facilitaservicos/conexaodesorte/excecao/codigos/CodigosErroMapeamento.java`

