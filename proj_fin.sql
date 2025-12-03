-- Core para geração de .mwb (sem CHECK/VIEW/TRIGGER)
CREATE DATABASE IF NOT EXISTS finance_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;
USE finance_db;

-- Domínio
CREATE TABLE plano_contas (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(30) NOT NULL UNIQUE,
  nome VARCHAR(200) NOT NULL,
  tipo ENUM('ATIVO','PASSIVO','RECEITA','DESPESA','PL') NOT NULL,
  natureza ENUM('DEBITO','CREDITO') NOT NULL,
  analitica BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE centro_custo (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(30) NOT NULL UNIQUE,
  nome VARCHAR(150) NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- Cadastros
CREATE TABLE cliente (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('PF','PJ') NOT NULL,
  nome VARCHAR(150) NOT NULL,
  cpf_cnpj VARCHAR(20) UNIQUE,
  email VARCHAR(150),
  telefone VARCHAR(30),
  ativo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE fornecedor (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('PF','PJ') NOT NULL,
  razao_nome VARCHAR(150) NOT NULL,
  cpf_cnpj VARCHAR(20) UNIQUE,
  email VARCHAR(150),
  telefone VARCHAR(30),
  ativo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE conta_bancaria (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  banco VARCHAR(100) NOT NULL,
  agencia VARCHAR(20),
  conta VARCHAR(30),
  moeda CHAR(3) NOT NULL DEFAULT 'BRL',
  saldo_inicial DECIMAL(14,2) NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- AR
CREATE TABLE fatura_receber (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  cliente_id BIGINT NOT NULL,
  numero VARCHAR(40) NOT NULL UNIQUE,
  emissao DATE NOT NULL,
  total DECIMAL(14,2) NOT NULL,
  status ENUM('ABERTA','FECHADA','CANCELADA') NOT NULL DEFAULT 'ABERTA',
  obs TEXT,
  CONSTRAINT fk_fr_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE receber_parcela (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  fatura_id BIGINT NOT NULL,
  num_parcela INT NOT NULL,
  vencimento DATE NOT NULL,
  valor DECIMAL(14,2) NOT NULL,
  status ENUM('ABERTA','PAGA','CANCELADA') NOT NULL DEFAULT 'ABERTA',
  data_pagamento DATE NULL,
  valor_pago DECIMAL(14,2) NOT NULL DEFAULT 0,
  UNIQUE (fatura_id, num_parcela),
  CONSTRAINT fk_rp_fatura FOREIGN KEY (fatura_id) REFERENCES fatura_receber(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_rp_venc ON receber_parcela (vencimento, status);

-- AP
CREATE TABLE fatura_pagar (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  fornecedor_id BIGINT NOT NULL,
  numero VARCHAR(40) NOT NULL UNIQUE,
  emissao DATE NOT NULL,
  total DECIMAL(14,2) NOT NULL,
  status ENUM('ABERTA','FECHADA','CANCELADA') NOT NULL DEFAULT 'ABERTA',
  obs TEXT,
  CONSTRAINT fk_fp_forn FOREIGN KEY (fornecedor_id) REFERENCES fornecedor(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pagar_parcela (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  fatura_id BIGINT NOT NULL,
  num_parcela INT NOT NULL,
  vencimento DATE NOT NULL,
  valor DECIMAL(14,2) NOT NULL,
  status ENUM('ABERTA','PAGA','CANCELADA') NOT NULL DEFAULT 'ABERTA',
  data_pagamento DATE NULL,
  valor_pago DECIMAL(14,2) NOT NULL DEFAULT 0,
  UNIQUE (fatura_id, num_parcela),
  CONSTRAINT fk_pp_fatura FOREIGN KEY (fatura_id) REFERENCES fatura_pagar(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_pp_venc ON pagar_parcela (vencimento, status);

-- Lançamentos (razão)
CREATE TABLE lancamento (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  data DATE NOT NULL,
  historico VARCHAR(300),
  origem ENUM('AR','AP','BANCO','AJUSTE') NOT NULL,
  documento_ref VARCHAR(60),
  fatura_receber_id BIGINT NULL,
  fatura_pagar_id  BIGINT NULL,
  status ENUM('RASCUNHO','FECHADO') NOT NULL DEFAULT 'RASCUNHO',
  CONSTRAINT fk_l_fr FOREIGN KEY (fatura_receber_id) REFERENCES fatura_receber(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_l_fp FOREIGN KEY (fatura_pagar_id) REFERENCES fatura_pagar(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE lancamento_item (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  lancamento_id BIGINT NOT NULL,
  conta_id BIGINT NOT NULL,
  centro_custo_id BIGINT NULL,
  debito DECIMAL(14,2) NOT NULL DEFAULT 0,
  credito DECIMAL(14,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_li_lanc FOREIGN KEY (lancamento_id) REFERENCES lancamento(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_li_conta FOREIGN KEY (conta_id) REFERENCES plano_contas(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_li_cc FOREIGN KEY (centro_custo_id) REFERENCES centro_custo(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_li_lanc ON lancamento_item (lancamento_id);

-- Baixas e extrato
CREATE TABLE baixa_receber (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  parcela_id BIGINT NOT NULL,
  conta_bancaria_id BIGINT NOT NULL,
  data DATE NOT NULL,
  valor DECIMAL(14,2) NOT NULL,
  forma_pagamento ENUM('PIX','DINHEIRO','CARTAO','BOLETO','TED','DOC','OUTRO') NOT NULL,
  lancamento_id BIGINT NOT NULL,
  CONSTRAINT fk_br_parc FOREIGN KEY (parcela_id) REFERENCES receber_parcela(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_br_cb FOREIGN KEY (conta_bancaria_id) REFERENCES conta_bancaria(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_br_lanc FOREIGN KEY (lancamento_id) REFERENCES lancamento(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE baixa_pagar (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  parcela_id BIGINT NOT NULL,
  conta_bancaria_id BIGINT NOT NULL,
  data DATE NOT NULL,
  valor DECIMAL(14,2) NOT NULL,
  forma_pagamento ENUM('PIX','DINHEIRO','CARTAO','BOLETO','TED','DOC','OUTRO') NOT NULL,
  lancamento_id BIGINT NOT NULL,
  CONSTRAINT fk_bp_parc FOREIGN KEY (parcela_id) REFERENCES pagar_parcela(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_bp_cb FOREIGN KEY (conta_bancaria_id) REFERENCES conta_bancaria(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_bp_lanc FOREIGN KEY (lancamento_id) REFERENCES lancamento(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE extrato_bancario (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  conta_bancaria_id BIGINT NOT NULL,
  data DATE NOT NULL,
  historico VARCHAR(300),
  valor DECIMAL(14,2) NOT NULL,
  documento_ref VARCHAR(60),
  conciliado BOOLEAN NOT NULL DEFAULT FALSE,
  baixa_receber_id BIGINT NULL,
  baixa_pagar_id BIGINT NULL,
  CONSTRAINT fk_ex_cb FOREIGN KEY (conta_bancaria_id) REFERENCES conta_bancaria(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ex_br FOREIGN KEY (baixa_receber_id) REFERENCES baixa_receber(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_ex_bp FOREIGN KEY (baixa_pagar_id) REFERENCES baixa_pagar(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_ex_cb_data ON extrato_bancario (conta_bancaria_id, data);
CREATE INDEX idx_fr_cliente  ON fatura_receber (cliente_id, status, emissao);
CREATE INDEX idx_fp_forn     ON fatura_pagar   (fornecedor_id, status, emissao);
CREATE INDEX idx_lanc_data   ON lancamento     (data, status);
CREATE INDEX idx_ex_docref   ON extrato_bancario (documento_ref);
-- =====================================================================
-- finance_db - SEED (dados de exemplo) - MySQL 8.0
-- Pré-requisito: executar o DDL core (finance_db_mwb_core.sql)
-- =====================================================================
USE finance_db;

-- ----------------------------
-- Plano de Contas
-- ----------------------------
INSERT INTO plano_contas (codigo, nome, tipo, natureza, analitica) VALUES
 ('1.1.1', 'Caixa',                       'ATIVO',   'DEBITO',  TRUE),
 ('1.1.2', 'Banco Conta Movimento',       'ATIVO',   'DEBITO',  TRUE),
 ('1.1.3', 'Clientes (A Receber)',        'ATIVO',   'DEBITO',  TRUE),
 ('2.1.1', 'Fornecedores (A Pagar)',      'PASSIVO', 'CREDITO', TRUE),
 ('2.3.1', 'Impostos a Recolher',         'PASSIVO', 'CREDITO', TRUE),
 ('3.1.1', 'Receita de Serviços',         'RECEITA', 'CREDITO', TRUE),
 ('3.1.2', 'Receita de Produtos',         'RECEITA', 'CREDITO', TRUE),
 ('4.1.1', 'Despesa com Aluguel',         'DESPESA', 'DEBITO',  TRUE),
 ('4.1.2', 'Despesa com Energia',         'DESPESA', 'DEBITO',  TRUE),
 ('5.1.1', 'Capital Social',              'PL',      'CREDITO', TRUE)
ON DUPLICATE KEY UPDATE nome = VALUES(nome);

-- ----------------------------
-- Centro de Custo
-- ----------------------------
INSERT INTO centro_custo (codigo, nome, ativo) VALUES
 ('ADM',  'Administrativo', TRUE),
 ('OPER', 'Operações',      TRUE),
 ('MKT',  'Marketing',      TRUE)
ON DUPLICATE KEY UPDATE nome = VALUES(nome);

-- ----------------------------
-- Cadastros de Cliente e Fornecedor
-- ----------------------------
INSERT INTO cliente (tipo, nome, cpf_cnpj, email, telefone, ativo) VALUES
 ('PJ', 'Empresa ABC Ltda',       '12.345.678/0001-99', 'financeiro@abc.com.br', '(61) 3333-0001', TRUE),
 ('PF', 'João da Silva',          '111.222.333-44',     'joao@email.com',        '(61) 99999-0001', TRUE),
 ('PJ', 'Comercial Delta S/A',    '98.765.432/0001-11', 'contato@delta.com',     '(11) 4002-8922', TRUE)
ON DUPLICATE KEY UPDATE email = VALUES(email);

INSERT INTO fornecedor (tipo, razao_nome, cpf_cnpj, email, telefone, ativo) VALUES
 ('PJ', 'Imobiliária Centro',        '22.222.222/0001-22', 'cobranca@imo.com',        '(61) 3333-1000', TRUE),
 ('PJ', 'Concessionária de Energia', '33.333.333/0001-33', 'faturamento@energia.com', '(61) 3222-2000', TRUE),
 ('PJ', 'Agência MKT Criativa',      '44.444.444/0001-44', 'contato@agenciamkt.com',  '(11) 3555-7788', TRUE)
ON DUPLICATE KEY UPDATE email = VALUES(email);

-- ----------------------------
-- Contas Bancárias
-- ----------------------------
INSERT INTO conta_bancaria (banco, agencia, conta, moeda, saldo_inicial) VALUES
 ('Banco do Brasil',  '0001', '12345-6', 'BRL', 5000.00),
 ('Itaú',             '0321', '98765-4', 'BRL', 10000.00);

-- ----------------------------
-- Faturas a Receber (AR) e Parcelas
-- ----------------------------
-- R-1001 (Empresa ABC) total 3000 em 2x 1500
INSERT INTO fatura_receber (cliente_id, numero, emissao, total, status, obs)
SELECT c.id, 'R-1001', CURDATE() - INTERVAL 5 DAY, 3000.00, 'ABERTA', 'Projeto implantação'
FROM cliente c WHERE c.nome='Empresa ABC Ltda'
ON DUPLICATE KEY UPDATE total=VALUES(total);

INSERT INTO receber_parcela (fatura_id, num_parcela, vencimento, valor, status, valor_pago)
SELECT fr.id, 1, CURDATE() + INTERVAL 10 DAY, 1500.00, 'ABERTA', 0
FROM fatura_receber fr WHERE fr.numero='R-1001'
ON DUPLICATE KEY UPDATE valor = VALUES(valor);
INSERT INTO receber_parcela (fatura_id, num_parcela, vencimento, valor, status, valor_pago)
SELECT fr.id, 2, CURDATE() + INTERVAL 40 DAY, 1500.00, 'ABERTA', 0
FROM fatura_receber fr WHERE fr.numero='R-1001'
ON DUPLICATE KEY UPDATE valor = VALUES(valor);

-- R-1002 (João) total 800 em 1x 800
INSERT INTO fatura_receber (cliente_id, numero, emissao, total, status, obs)
SELECT c.id, 'R-1002', CURDATE() - INTERVAL 2 DAY, 800.00, 'ABERTA', 'Serviço manutenção'
FROM cliente c WHERE c.nome='João da Silva'
ON DUPLICATE KEY UPDATE total=VALUES(total);

INSERT INTO receber_parcela (fatura_id, num_parcela, vencimento, valor, status, valor_pago)
SELECT fr.id, 1, CURDATE() + INTERVAL 8 DAY, 800.00, 'ABERTA', 0
FROM fatura_receber fr WHERE fr.numero='R-1002'
ON DUPLICATE KEY UPDATE valor = VALUES(valor);

-- R-1003 (Delta) total 1200 em 3x 400
INSERT INTO fatura_receber (cliente_id, numero, emissao, total, status, obs)
SELECT c.id, 'R-1003', CURDATE() - INTERVAL 1 DAY, 1200.00, 'ABERTA', 'Venda de produto'
FROM cliente c WHERE c.nome='Comercial Delta S/A'
ON DUPLICATE KEY UPDATE total=VALUES(total);

INSERT INTO receber_parcela (fatura_id, num_parcela, vencimento, valor, status, valor_pago)
SELECT fr.id, 1, CURDATE() + INTERVAL 15 DAY, 400.00, 'ABERTA', 0
FROM fatura_receber fr WHERE fr.numero='R-1003'
ON DUPLICATE KEY UPDATE valor = VALUES(valor);
INSERT INTO receber_parcela (fatura_id, num_parcela, vencimento, valor, status, valor_pago)
SELECT fr.id, 2, CURDATE() + INTERVAL 45 DAY, 400.00, 'ABERTA', 0
FROM fatura_receber fr WHERE fr.numero='R-1003'
ON DUPLICATE KEY UPDATE valor = VALUES(valor);
INSERT INTO receber_parcela (fatura_id, num_parcela, vencimento, valor, status, valor_pago)
SELECT fr.id, 3, CURDATE() + INTERVAL 75 DAY, 400.00, 'ABERTA', 0
FROM fatura_receber fr WHERE fr.numero='R-1003'
ON DUPLICATE KEY UPDATE valor = VALUES(valor);

-- ----------------------------
-- Faturas a Pagar (AP) e Parcelas
-- ----------------------------
-- P-2001 (Imobiliária) 2000 em 1x
INSERT INTO fatura_pagar (fornecedor_id, numero, emissao, total, status, obs)
SELECT f.id, 'P-2001', CURDATE() - INTERVAL 3 DAY, 2000.00, 'ABERTA', 'Aluguel'
FROM fornecedor f WHERE f.razao_nome='Imobiliária Centro'
ON DUPLICATE KEY UPDATE total=VALUES(total);

INSERT INTO pagar_parcela (fatura_id, num_parcela, vencimento, valor, status, valor_pago)
SELECT fp.id, 1, CURDATE() + INTERVAL 7 DAY, 2000.00, 'ABERTA', 0
FROM fatura_pagar fp WHERE fp.numero='P-2001'
ON DUPLICATE KEY UPDATE valor = VALUES(valor);

-- P-2002 (Energia) 650 em 1x
INSERT INTO fatura_pagar (fornecedor_id, numero, emissao, total, status, obs)
SELECT f.id, 'P-2002', CURDATE() - INTERVAL 1 DAY, 650.00, 'ABERTA', 'Conta de energia'
FROM fornecedor f WHERE f.razao_nome='Concessionária de Energia'
ON DUPLICATE KEY UPDATE total=VALUES(total);

INSERT INTO pagar_parcela (fatura_id, num_parcela, vencimento, valor, status, valor_pago)
SELECT fp.id, 1, CURDATE() + INTERVAL 15 DAY, 650.00, 'ABERTA', 0
FROM fatura_pagar fp WHERE fp.numero='P-2002'
ON DUPLICATE KEY UPDATE valor = VALUES(valor);

-- ----------------------------
-- Lançamentos de Reconhecimento (Dupla Entrada)
-- ----------------------------
-- R-1001: D Clientes 3000 / C Receita Serviços 3000
INSERT INTO lancamento (data, historico, origem, documento_ref, fatura_receber_id, status)
SELECT fr.emissao, 'Fatura AR R-1001', 'AR', 'R-1001', fr.id, 'FECHADO'
FROM fatura_receber fr WHERE fr.numero='R-1001';

INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='1.1.3'), 3000.00, 0
FROM lancamento l WHERE l.documento_ref='R-1001';
INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='3.1.1'), 0, 3000.00
FROM lancamento l WHERE l.documento_ref='R-1001';

-- R-1002: D Clientes 800 / C Receita Serviços 800
INSERT INTO lancamento (data, historico, origem, documento_ref, fatura_receber_id, status)
SELECT fr.emissao, 'Fatura AR R-1002', 'AR', 'R-1002', fr.id, 'FECHADO'
FROM fatura_receber fr WHERE fr.numero='R-1002';

INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='1.1.3'), 800.00, 0
FROM lancamento l WHERE l.documento_ref='R-1002';
INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='3.1.1'), 0, 800.00
FROM lancamento l WHERE l.documento_ref='R-1002';

-- R-1003: D Clientes 1200 / C Receita Produtos 1200
INSERT INTO lancamento (data, historico, origem, documento_ref, fatura_receber_id, status)
SELECT fr.emissao, 'Fatura AR R-1003', 'AR', 'R-1003', fr.id, 'FECHADO'
FROM fatura_receber fr WHERE fr.numero='R-1003';

INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='1.1.3'), 1200.00, 0
FROM lancamento l WHERE l.documento_ref='R-1003';
INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='3.1.2'), 0, 1200.00
FROM lancamento l WHERE l.documento_ref='R-1003';

-- P-2001: D Despesa Aluguel 2000 / C Fornecedores 2000 (ADM)
INSERT INTO lancamento (data, historico, origem, documento_ref, fatura_pagar_id, status)
SELECT fp.emissao, 'Fatura AP P-2001', 'AP', 'P-2001', fp.id, 'FECHADO'
FROM fatura_pagar fp WHERE fp.numero='P-2001';

INSERT INTO lancamento_item (lancamento_id, conta_id, centro_custo_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='4.1.1'),
       (SELECT id FROM centro_custo WHERE codigo='ADM'), 2000.00, 0
FROM lancamento l WHERE l.documento_ref='P-2001';
INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='2.1.1'), 0, 2000.00
FROM lancamento l WHERE l.documento_ref='P-2001';

-- P-2002: D Despesa Energia 650 / C Fornecedores 650 (OPER)
INSERT INTO lancamento (data, historico, origem, documento_ref, fatura_pagar_id, status)
SELECT fp.emissao, 'Fatura AP P-2002', 'AP', 'P-2002', fp.id, 'FECHADO'
FROM fatura_pagar fp WHERE fp.numero='P-2002';

INSERT INTO lancamento_item (lancamento_id, conta_id, centro_custo_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='4.1.2'),
       (SELECT id FROM centro_custo WHERE codigo='OPER'), 650.00, 0
FROM lancamento l WHERE l.documento_ref='P-2002';
INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='2.1.1'), 0, 650.00
FROM lancamento l WHERE l.documento_ref='P-2002';

-- ----------------------------
-- Recebimentos (baixas AR) e pagamento (baixa AP)
-- ----------------------------
-- Recebimento parcial R-1001 parcela 1: 1000 hoje
INSERT INTO lancamento (data, historico, origem, documento_ref, fatura_receber_id, status)
SELECT CURDATE(), 'Recebimento Parcial R-1001/1', 'BANCO', 'REC-R1001-1', fr.id, 'FECHADO'
FROM fatura_receber fr WHERE fr.numero='R-1001';

INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='1.1.2'), 1000.00, 0
FROM lancamento l WHERE l.documento_ref='REC-R1001-1';
INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='1.1.3'), 0, 1000.00
FROM lancamento l WHERE l.documento_ref='REC-R1001-1';

-- Baixa + atualizar parcela
INSERT INTO baixa_receber (parcela_id, conta_bancaria_id, data, valor, forma_pagamento, lancamento_id)
SELECT rp.id, (SELECT id FROM conta_bancaria ORDER BY id LIMIT 1), CURDATE(), 1000.00, 'PIX', l.id
FROM receber_parcela rp
JOIN fatura_receber fr ON fr.id = rp.fatura_id
JOIN lancamento l ON l.documento_ref='REC-R1001-1'
WHERE fr.numero='R-1001' AND rp.num_parcela=1;

UPDATE receber_parcela rp
JOIN fatura_receber fr ON fr.id = rp.fatura_id
SET rp.valor_pago = rp.valor_pago + 1000.00,
    rp.status = CASE WHEN rp.valor_pago + 1000.00 >= rp.valor - 0.01 THEN 'PAGA' ELSE 'ABERTA' END,
    rp.data_pagamento = CASE WHEN rp.valor_pago + 1000.00 >= rp.valor - 0.01 THEN CURDATE() ELSE rp.data_pagamento END
WHERE fr.numero='R-1001' AND rp.num_parcela=1;

-- Recebimento integral R-1002 parcela 1: 800 hoje
INSERT INTO lancamento (data, historico, origem, documento_ref, fatura_receber_id, status)
SELECT CURDATE(), 'Recebimento R-1002/1', 'BANCO', 'REC-R1002-1', fr.id, 'FECHADO'
FROM fatura_receber fr WHERE fr.numero='R-1002';

INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='1.1.2'), 800.00, 0
FROM lancamento l WHERE l.documento_ref='REC-R1002-1';
INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='1.1.3'), 0, 800.00
FROM lancamento l WHERE l.documento_ref='REC-R1002-1';

INSERT INTO baixa_receber (parcela_id, conta_bancaria_id, data, valor, forma_pagamento, lancamento_id)
SELECT rp.id, (SELECT id FROM conta_bancaria ORDER BY id LIMIT 1), CURDATE(), 800.00, 'PIX', l.id
FROM receber_parcela rp
JOIN fatura_receber fr ON fr.id = rp.fatura_id
JOIN lancamento l ON l.documento_ref='REC-R1002-1'
WHERE fr.numero='R-1002' AND rp.num_parcela=1;

UPDATE receber_parcela rp
JOIN fatura_receber fr ON fr.id = rp.fatura_id
SET rp.valor_pago = rp.valor,
    rp.status = 'PAGA',
    rp.data_pagamento = CURDATE()
WHERE fr.numero='R-1002' AND rp.num_parcela=1;

-- Pagamento integral P-2002 parcela 1: 650 hoje
INSERT INTO lancamento (data, historico, origem, documento_ref, fatura_pagar_id, status)
SELECT CURDATE(), 'Pagamento P-2002', 'BANCO', 'PAG-P2002', fp.id, 'FECHADO'
FROM fatura_pagar fp WHERE fp.numero='P-2002';

INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='2.1.1'), 650.00, 0
FROM lancamento l WHERE l.documento_ref='PAG-P2002';
INSERT INTO lancamento_item (lancamento_id, conta_id, debito, credito)
SELECT l.id, (SELECT id FROM plano_contas WHERE codigo='1.1.2'), 0, 650.00
FROM lancamento l WHERE l.documento_ref='PAG-P2002';

INSERT INTO baixa_pagar (parcela_id, conta_bancaria_id, data, valor, forma_pagamento, lancamento_id)
SELECT pp.id, (SELECT id FROM conta_bancaria ORDER BY id LIMIT 1), CURDATE(), 650.00, 'PIX', l.id
FROM pagar_parcela pp
JOIN fatura_pagar fp ON fp.id = pp.fatura_id
JOIN lancamento l ON l.documento_ref='PAG-P2002'
WHERE fp.numero='P-2002' AND pp.num_parcela=1;

UPDATE pagar_parcela pp
JOIN fatura_pagar fp ON fp.id = pp.fatura_id
SET pp.valor_pago = pp.valor,
    pp.status = 'PAGA',
    pp.data_pagamento = CURDATE()
WHERE fp.numero='P-2002' AND pp.num_parcela=1;

-- ----------------------------
-- Extrato Bancário (créditos/recebimentos positivos, débitos/pagamentos negativos)
-- ----------------------------
-- Extrato dos recebimentos (positivos)
INSERT INTO extrato_bancario (conta_bancaria_id, data, historico, valor, documento_ref, conciliado, baixa_receber_id)
SELECT b.conta_bancaria_id, b.data, CONCAT('Recebimento ', fr.numero, '/', rp.num_parcela),
       b.valor, l.documento_ref, TRUE, b.id
FROM baixa_receber b
JOIN receber_parcela rp ON rp.id = b.parcela_id
JOIN fatura_receber fr ON fr.id = rp.fatura_id
JOIN lancamento l ON l.id = b.lancamento_id
WHERE b.data = CURDATE();

-- Extrato dos pagamentos (negativos)
INSERT INTO extrato_bancario (conta_bancaria_id, data, historico, valor, documento_ref, conciliado, baixa_pagar_id)
SELECT b.conta_bancaria_id, b.data, CONCAT('Pagamento ', fp.numero, '/', pp.num_parcela),
       -b.valor, l.documento_ref, TRUE, b.id
FROM baixa_pagar b
JOIN pagar_parcela pp ON pp.id = b.parcela_id
JOIN fatura_pagar fp ON fp.id = pp.fatura_id
JOIN lancamento l ON l.id = b.lancamento_id
WHERE b.data = CURDATE();
-- 1) Balancete: saldos por conta (SELECT, ORDER BY)
SELECT * FROM v_balancete_contas ORDER BY codigo;

-- 2) Aging list AR (expressões derivadas, WHERE, ORDER BY)
SELECT
  c.nome AS cliente,
  fr.numero AS fatura,
  rp.num_parcela,
  rp.vencimento,
  rp.valor,
  COALESCE(rp.valor_pago,0) AS valor_pago,
  (rp.valor - COALESCE(rp.valor_pago,0)) AS em_aberto,
  GREATEST(0, DATEDIFF(CURDATE(), rp.vencimento)) AS dias_atraso,
  CASE
    WHEN CURDATE() <= rp.vencimento THEN 'A VENCER'
    WHEN DATEDIFF(CURDATE(), rp.vencimento) BETWEEN 1 AND 30 THEN '1-30'
    WHEN DATEDIFF(CURDATE(), rp.vencimento) BETWEEN 31 AND 60 THEN '31-60'
    WHEN DATEDIFF(CURDATE(), rp.vencimento) BETWEEN 61 AND 90 THEN '61-90'
    ELSE '90+'
  END AS faixa
FROM receber_parcela rp
JOIN fatura_receber fr ON fr.id = rp.fatura_id
JOIN cliente c ON c.id = fr.cliente_id
WHERE rp.status <> 'CANCELADA'
ORDER BY dias_atraso DESC, c.nome;

-- 3) Fluxo de caixa projetado (GROUP BY, HAVING)
WITH inflows AS (
  SELECT DATE_FORMAT(rp.vencimento,'%Y-%m-01') AS mes,
         SUM(rp.valor - COALESCE(rp.valor_pago,0)) AS valor
  FROM receber_parcela rp
  WHERE rp.status = 'ABERTA'
  GROUP BY 1
),
outflows AS (
  SELECT DATE_FORMAT(pp.vencimento,'%Y-%m-01') AS mes,
         SUM(pp.valor - COALESCE(pp.valor_pago,0)) AS valor
  FROM pagar_parcela pp
  WHERE pp.status = 'ABERTA'
  GROUP BY 1
)
SELECT
  COALESCE(i.mes, o.mes) AS mes,
  COALESCE(i.valor,0) AS entradas_previstas,
  COALESCE(o.valor,0) AS saidas_previstas,
  COALESCE(i.valor,0) - COALESCE(o.valor,0) AS saldo_projetado
FROM inflows i
FULL JOIN outflows o ON o.mes = i.mes
HAVING COALESCE(i.valor,0) <> 0 OR COALESCE(o.valor,0) <> 0
ORDER BY mes;

-- 4) Receita por cliente (JOIN, GROUP BY, HAVING)
SELECT
  c.id AS cliente_id,
  c.nome,
  SUM(li.credito) AS receita_contabilizada
FROM lancamento l
JOIN lancamento_item li ON li.lancamento_id = l.id
JOIN plano_contas pc ON pc.id = li.conta_id AND pc.tipo = 'RECEITA'
JOIN fatura_receber fr ON fr.id = l.fatura_receber_id
JOIN cliente c ON c.id = fr.cliente_id
GROUP BY c.id, c.nome
HAVING SUM(li.credito) > 0
ORDER BY receita_contabilizada DESC;

-- 5) Despesa por centro de custo (GROUP BY + HAVING)
SELECT
  cc.codigo,
  cc.nome,
  SUM(li.debito) AS despesas
FROM lancamento_item li
JOIN plano_contas pc ON pc.id = li.conta_id AND pc.tipo = 'DESPESA'
LEFT JOIN centro_custo cc ON cc.id = li.centro_custo_id
GROUP BY cc.codigo, cc.nome
HAVING SUM(li.debito) >= 500
ORDER BY despesas DESC;

-- 6) Conciliação por dia (JOINs, agregações)
WITH razao AS (
  SELECT l.data AS data, SUM(li.debito - li.credito) AS mov
  FROM lancamento l
  JOIN lancamento_item li ON li.lancamento_id = l.id
  WHERE li.conta_id = (SELECT id FROM plano_contas WHERE codigo='1.1.2')
  GROUP BY 1
),
extrato AS (
  SELECT data, SUM(valor) AS mov
  FROM extrato_bancario
  WHERE conta_bancaria_id = (SELECT id FROM conta_bancaria ORDER BY id LIMIT 1)
  GROUP BY data
)
SELECT
  COALESCE(r.data, e.data) AS data,
  COALESCE(r.mov, 0) AS mov_razao,
  COALESCE(e.mov, 0) AS mov_extrato,
  (COALESCE(r.mov,0) - COALESCE(e.mov,0)) AS diferenca
FROM razao r
FULL JOIN extrato e ON e.data = r.data
WHERE ABS(COALESCE(r.mov,0) - COALESCE(e.mov,0)) > 0.01
ORDER BY data;

-- 7) A pagar nos próximos 15 dias (WHERE, ORDER BY)
SELECT
  f.razao_nome,
  pp.vencimento,
  pp.valor,
  GREATEST(0, DATEDIFF(pp.vencimento, CURDATE())) AS dias_para_vencer
FROM pagar_parcela pp
JOIN fatura_pagar fp ON fp.id = pp.fatura_id
JOIN fornecedor f ON f.id = fp.fornecedor_id
WHERE pp.status = 'ABERTA'
  AND pp.vencimento BETWEEN CURDATE() AND CURDATE() + INTERVAL 15 DAY
ORDER BY pp.vencimento;
