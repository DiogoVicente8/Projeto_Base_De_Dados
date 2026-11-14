-- Cria a base de dados do zero, pela ordem certa.
-- Uso: psql -U postgres -d hotel -f sql/run_all.sql
-- ON_ERROR_STOP faz parar no primeiro erro, para não ficar a BD meio criada.

\set ON_ERROR_STOP on

\echo '== 1. Apagar tabelas existentes'
\ir drop.sql

\echo '== 2. Tabelas do núcleo (Diogo)'
\ir Table.sql

\echo '== 3. Tabelas de serviços e pagamentos (João)'
\ir servicos_pagamentos.sql

\echo '== 4. Vistas'
\ir vistas.sql

\echo '== 5. Dados de povoamento'
\ir ../dados/povoamento_nucleo.sql
\ir ../dados/povoamento_servicos.sql

\echo '== Base de dados criada.'