# Projeto FIN -db (MySQL 8.0)

Sistema financeiro (Billing & Pagamentos) com:
- Contas a Receber (AR) e a Pagar (AP) com parcelas e baixas
- Lançamentos contábeis de dupla entrada (razão)
- Plano de contas com natureza (Débito/Crédito)
- Centro de custo por item
- Conciliação bancária (extrato + baixas)

Projeto alinhado ao desafio DIO: inclui esquema lógico, DDL, carga de dados (seed) e consultas com SELECT, WHERE, expressões derivadas, ORDER BY, HAVING e JOIN.

## Sumário
- Contexto e objetivos
- Diagrama lógico (EER)
- Requisitos
- Estrutura do repositório
- Como executar (Docker e local)
- Como gerar o .mwb no Workbench
- Como popular com dados de exemplo (seed)
- Consultas de exemplo
- Roadmap e observações

## Contexto e objetivos
- Contexto: Gestão financeira com AR/AP, razão contábil e conciliação.
- Objetivo: Demonstrar modelagem relacional robusta e consultas gerenciais, com foco em integridade (dupla entrada) e clareza de regras.

Principais decisões de modelagem:
- Dupla entrada: cada lançamento possui itens de débito/crédito que se equilibram.
- AR/AP com parcelas e baixas parciais.
- Baixas geram movimentos no extrato bancário para conciliação.
- Centro de custo nos itens (despesas/receitas).

## Diagrama lógico (EER)
Visualize abaixo (GitHub renderiza Mermaid automaticamente):

```mermaid
erDiagram
    plano_contas ||--o{ lancamento_item : "contabiliza"
    centro_custo ||--o{ lancamento_item : "aloca"
    lancamento ||--o{ lancamento_item : "detalha"

    cliente ||--o{ fatura_receber : "fatura"
    fatura_receber ||--o{ receber_parcela : "parcelas"

    fornecedor ||--o{ fatura_pagar : "fatura"
    fatura_pagar  ||--o{ pagar_parcela  : "parcelas"

    conta_bancaria ||--o{ extrato_bancario : "movimenta"
    receber_parcela ||--o{ baixa_receber : "baixas"
    pagar_parcela   ||--o{ baixa_pagar   : "baixas"

    lancamento ||..o| fatura_receber : "origem AR (opcional)"
    lancamento ||..o| fatura_pagar   : "origem AP (opcional)"
    baixa_receber ||..o| lancamento  : "gera"
    baixa_pagar   ||..o| lancamento  : "gera"
    baixa_receber ||..o| extrato_bancario : "concilia"
    baixa_pagar   ||..o| extrato_bancario : "concilia"
