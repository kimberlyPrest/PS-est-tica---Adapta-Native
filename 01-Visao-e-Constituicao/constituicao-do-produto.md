# Constituição do produto

1. **A pessoa atendida continua no centro.** A automação facilita resposta e continuidade; situações clínicas, risco, baixa confiança e pedido de humano vão para a equipe.
2. **O humano responde por decisões sensíveis.** A IA pode classificar, resumir e sugerir. Diagnóstico, avaliação por foto, desconto, promessa de resultado, confirmação de booking e escrita externa obedecem aos limites do escopo e às políticas aprovadas.
3. **Cada clínica é um espaço segregado.** A clínica do número receptor define o contexto; usuário, fila, mensagem, paciente e configuração seguem membership/RLS.
4. **Cada domínio tem fonte de verdade clara.** O CRM operacional é próprio em Supabase; Clínica Experts mantém autoridade sobre dados clínicos e transacionais disponíveis.
5. **Segredos não são conteúdo do produto.** Credenciais ficam no cofre server-side; não aparecem no navegador, banco operacional, logs ou documentos.
6. **Falhas devem ser visíveis e recuperáveis.** Integrações usam correlação, idempotência, retry limitado, dead-letter e alternativa humana. Falha externa não apaga conversa nem inventa sucesso.
7. **Canais não são intercambiáveis silenciosamente.** Uma conversa preserva número e provedor de origem; mudanças requerem ação humana e trilha auditável.
8. **Configuração é versionada.** Prompts, agentes, templates e políticas têm preview, versão publicada e rollback.
9. **Dados são minimizados e protegidos.** Acesso segue finalidade e menor privilégio; conteúdos pessoais não são usados para treinar modelos externos por padrão.
10. **A operação é mensurada com evidência.** Métricas têm definição, origem, versão e responsável; recomendações apontam dados e não alteram metas sozinhas.
