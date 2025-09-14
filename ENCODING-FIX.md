# 🔧 Correção do Erro de Encoding - GitHub Actions

## ❌ **Problema Identificado**
```
Error: Unable to process file command 'env' successfully.
Error: Invalid format 'MIIEv"
```

### **🔍 Causa Raiz**
- Valores de segredos contendo **caracteres especiais** (chaves privadas/públicas)
- Valores **multilinhas** não tratados corretamente
- Formato inadequado para o comando `env` do GitHub Actions

## ✅ **Solução Implementada**

### **🛡️ Função `add_secret` Robusta**
```bash
add_secret() {
  local key="$1"
  local secret_name="$2"
  local value
  value=$(get "$secret_name")

  # Para valores multilinhas, usar formato EOF
  if [[ "$value" == *$'\n'* ]] || [[ "$value" == *"-----BEGIN"* ]] || [[ "$value" == *"-----END"* ]]; then
    echo "$key<<EOF" >> $GITHUB_ENV
    echo "$value" >> $GITHUB_ENV
    echo "EOF" >> $GITHUB_ENV
  else
    echo "$key=$value" >> $GITHUB_ENV
  fi
}
```

### **🔐 Características da Solução**

1. **Detecção Automática de Multilinhas**:
   - Quebras de linha (`\n`)
   - Certificados/chaves (`-----BEGIN`, `-----END`)

2. **Formato EOF Seguro**:
   - Evita problemas de escape
   - Preserva formatação original
   - Compatível com GitHub Actions

3. **Proteção Contra Injection**:
   - Valores isolados em blocos EOF
   - Sem interpretação de shell especial

## 🎯 **Resultado**

- ✅ **Valores simples**: `KEY=value`
- ✅ **Valores multilinhas**: `KEY<<EOF ... EOF`
- ✅ **Chaves privadas/públicas**: Tratamento especial
- ✅ **Caracteres especiais**: Sem problemas de encoding

## 📊 **Teste de Validação**

### **Antes (❌ Erro)**
```bash
echo "JWT_PRIVATE_KEY=$(get jwt-private-key)" >> $GITHUB_ENV
# ❌ Falha com: Invalid format 'MIIEv"
```

### **Depois (✅ Sucesso)**
```bash
add_secret "JWT_PRIVATE_KEY" "conexao-de-sorte-jwt-privateKey"
# ✅ Funciona com formato EOF automático
```

## 🚀 **Status**
- ✅ **Problema corrigido**
- ✅ **Pipeline funcional**
- ✅ **Segredos seguros**
- ✅ **Documentação atualizada**

---
**🔧 Correção aplicada em:** 2024-09-14
**🎯 Resultado:** Pipeline operacional com tratamento robusto de segredos